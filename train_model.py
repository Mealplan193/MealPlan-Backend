"""Train and evaluate the Meal Plan food-group classifier (TF-IDF + Logistic Regression).

Usage (from the project root):
    python -m ml.train_model                 # uses data/raw/nutrition.csv if present, else the built-in 30 foods
    python -m ml.train_model --data path.csv # explicit dataset CSV
    python -m ml.train_model --builtin       # force the built-in 30-food fallback

Pipeline (proposal Sections V-C / V-D):
    clean -> stratified 80/20 split -> TF-IDF (1-2 grams) + LogisticRegression
    -> hyper-parameter tuning with cross-validation on the TRAINING split only
    -> evaluation on the untouched test split -> refit on all data -> save with joblib.

If the dataset is too small for a valid stratified split (e.g. the 30-food fallback, where
groups have only 2-5 foods) the script says so and reports training-fit + leave-one-out
accuracy instead. It never silently pretends that is held-out performance.
"""
import argparse
import json
import platform
import sys
from datetime import datetime, timezone
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
import sklearn
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix, precision_recall_fscore_support
from sklearn.model_selection import GridSearchCV, LeaveOneOut, StratifiedKFold, cross_val_predict, train_test_split
from sklearn.pipeline import Pipeline

from preprocess import GROUPS, load_builtin, load_dataset, normalize_name

ROOT = Path(__file__).resolve().parent.parent
RAW_CSV = ROOT / "data" / "raw" / "nutrition.csv"
BUILTIN_CSV = ROOT / "data" / "builtin_foods.csv"
PROCESSED_DIR = ROOT / "data" / "processed"
MODEL_PATH = ROOT / "models" / "food_classifier.joblib"
META_PATH = ROOT / "models" / "model_metadata.json"
REPORT_DIR = ROOT / "reports"
RANDOM_STATE = 42


def build_pipeline(C=10.0, ngram_range=(1, 2)) -> Pipeline:
    return Pipeline([
        ("tfidf", TfidfVectorizer(preprocessor=normalize_name, ngram_range=ngram_range,
                                  token_pattern=r"[a-z0-9][a-z0-9\-]*", sublinear_tf=False)),
        ("clf", LogisticRegression(C=C, max_iter=2000, random_state=RANDOM_STATE)),
    ])


def _metrics(y_true, y_pred, labels) -> dict:
    p, r, f, s = precision_recall_fscore_support(y_true, y_pred, labels=labels, zero_division=0)
    wp, wr, wf, _ = precision_recall_fscore_support(y_true, y_pred, labels=labels, average="weighted", zero_division=0)
    mp, mr, mf, _ = precision_recall_fscore_support(y_true, y_pred, labels=labels, average="macro", zero_division=0)
    return {
        "accuracy": round(float(accuracy_score(y_true, y_pred)), 4),
        "macro": {"precision": round(float(mp), 4), "recall": round(float(mr), 4), "f1": round(float(mf), 4)},
        "weighted": {"precision": round(float(wp), 4), "recall": round(float(wr), 4), "f1": round(float(wf), 4)},
        "per_class": {l: {"precision": round(float(p[i]), 4), "recall": round(float(r[i]), 4),
                          "f1": round(float(f[i]), 4), "support": int(s[i])} for i, l in enumerate(labels)},
        "confusion_matrix": confusion_matrix(y_true, y_pred, labels=labels).tolist(),
        "labels": labels,
    }


def _plot_confusion(cm, labels, title, path):
    try:
        import matplotlib
        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except Exception:
        return False
    fig, ax = plt.subplots(figsize=(7, 6))
    ax.imshow(cm, cmap="Greens")
    ax.set_xticks(range(len(labels)), labels, rotation=45, ha="right", fontsize=8)
    ax.set_yticks(range(len(labels)), labels, fontsize=8)
    ax.set_xlabel("Predicted"); ax.set_ylabel("Actual"); ax.set_title(title, fontsize=10)
    for i in range(len(labels)):
        for j in range(len(labels)):
            if cm[i][j]:
                ax.text(j, i, cm[i][j], ha="center", va="center", fontsize=8)
    fig.tight_layout(); fig.savefig(path, dpi=150); plt.close(fig)
    return True


def load_training_frame(data_path=None, force_builtin=False):
    """Return (df, source_description, cleaning_report)."""
    if not force_builtin:
        p = Path(data_path) if data_path else RAW_CSV
        if p.exists():
            df, rep = load_dataset(p)
            # The app has 10 food groups but the Kaggle table has no snack category. Groups the dataset
            # lacks are filled from the app's own built-in foods so the model can still predict them.
            bi = load_builtin(BUILTIN_CSV)
            missing = [g for g in GROUPS if g not in set(df["group"])]
            extra = bi[bi["group"].isin(missing)]
            if len(extra):
                df = pd.concat([df, extra[df.columns.intersection(extra.columns)]], ignore_index=True)
                rep["supplemented_from_builtin"] = {g: int((extra["group"] == g).sum()) for g in missing if (extra["group"] == g).any()}
                rep["rows_kept"] = int(len(df))
                rep["class_counts"] = {k: int(v) for k, v in df["group"].value_counts().items()}
            return df, f"Dataset CSV: {p.name}", rep
        if data_path:
            raise FileNotFoundError(f"Dataset not found: {p}")
    df = load_builtin(BUILTIN_CSV)
    return df, "Built-in 30-food table (fallback; Kaggle CSV not found at data/raw/nutrition.csv)", {
        "rows_read": len(df), "rows_kept": len(df),
        "class_counts": {k: int(v) for k, v in df["group"].value_counts().items()}}


def train(data_path=None, force_builtin=False, model_path=MODEL_PATH, meta_path=META_PATH,
          report_dir=REPORT_DIR, processed_dir=PROCESSED_DIR, verbose=True) -> dict:
    log = print if verbose else (lambda *a, **k: None)
    df, source, cleaning = load_training_frame(data_path, force_builtin)
    X, y = df["name"].astype(str), df["group"].astype(str)
    counts = y.value_counts()
    labels = sorted(counts.index.tolist(), key=lambda g: GROUPS.index(g) if g in GROUPS else 99)
    log(f"Source : {source}\nFoods  : {len(df)}   Classes: {len(labels)}   Smallest class: {counts.min()}")

    # A stratified 80/20 split needs >=2 members per class and a test set at least as big as the class count.
    n_test = int(np.ceil(0.2 * len(df)))
    holdout_ok = counts.min() >= 2 and n_test >= len(labels)
    result = {"source": source, "cleaning": cleaning, "n_foods": int(len(df)), "classes": labels}

    if holdout_ok:
        Xtr, Xte, ytr, yte = train_test_split(X, y, test_size=0.2, stratify=y, random_state=RANDOM_STATE)
        k = int(max(2, min(5, ytr.value_counts().min())))
        grid = GridSearchCV(build_pipeline(), {"clf__C": [1, 10, 100], "tfidf__ngram_range": [(1, 1), (1, 2)]},
                            cv=StratifiedKFold(n_splits=k, shuffle=True, random_state=RANDOM_STATE),
                            scoring="f1_macro", n_jobs=1)
        grid.fit(Xtr, ytr)                       # tuning sees the training split only
        ypred = grid.predict(Xte)                # test split used once, after tuning
        present = [l for l in labels if l in set(yte) | set(ypred)]   # classes with no test example cannot be scored
        m = _metrics(yte, ypred, present)
        result.update(evaluation_mode="stratified_80_20_holdout",
                      evaluation_note=f"Stratified 80/20 split ({len(Xtr)} train / {len(Xte)} test); "
                                      f"{k}-fold CV tuning on the training split only."
                                      + ("" if len(present) == len(labels) else f" Not scored (no test example): {sorted(set(labels) - set(present))}."),
                      best_params={"C": grid.best_params_["clf__C"],
                                   "ngram_range": list(grid.best_params_["tfidf__ngram_range"])},
                      cv_macro_f1=round(float(grid.best_score_), 4), test_metrics=m,
                      n_train=int(len(Xtr)), n_test=int(len(Xte)))
        best = build_pipeline(C=grid.best_params_["clf__C"], ngram_range=grid.best_params_["tfidf__ngram_range"])
        headline = m
        cm_title = "Confusion matrix - held-out test split"
    else:
        best = build_pipeline()
        best.fit(X, y)
        m_train = _metrics(y, best.predict(X), labels)
        loo_pred = cross_val_predict(build_pipeline(), X, y, cv=LeaveOneOut())
        m_loo = _metrics(y, loo_pred, labels)
        result.update(evaluation_mode="training_fit_plus_leave_one_out",
                      evaluation_note="Dataset too small for a valid stratified 80/20 split "
                                      f"(smallest class = {counts.min()}, test set would be {n_test} for {len(labels)} classes). "
                                      "Training-fit metrics are NOT predictive performance; "
                                      "leave-one-out accuracy is the honest generalisation estimate.",
                      best_params={"C": 10.0, "ngram_range": [1, 2]},
                      training_metrics=m_train, test_metrics=m_loo, leave_one_out_accuracy=m_loo["accuracy"])
        headline = m_loo
        cm_title = "Confusion matrix - leave-one-out"
        log(f"WARNING: {result['evaluation_note']}")
        log(f"  training accuracy = {m_train['accuracy']}   leave-one-out accuracy = {m_loo['accuracy']}")

    best.fit(X, y)                               # deployment model: refit on ALL cleaned data
    model_path, meta_path = Path(model_path), Path(meta_path)
    model_path.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(best, model_path)

    # Corpus that the runtime classifier retrains on when the user edits custom foods
    processed_dir = Path(processed_dir); processed_dir.mkdir(parents=True, exist_ok=True)
    df[["name", "group"]].to_csv(processed_dir / "training_foods.csv", index=False)
    if "Dataset CSV" in source:                  # foods that can be imported into the app's food table
        df[["name", "group", "measure", "calories", "protein", "carbs", "fat"]].to_csv(
            processed_dir / "dataset_foods.csv", index=False)

    report_dir = Path(report_dir); report_dir.mkdir(parents=True, exist_ok=True)
    png = _plot_confusion(np.array(headline["confusion_matrix"]), headline["labels"], cm_title, report_dir / "confusion_matrix.png")
    with open(report_dir / "evaluation_report.json", "w", encoding="utf-8") as f:
        json.dump(result, f, indent=2)
    lines = [f"Meal Plan classifier evaluation  ({datetime.now(timezone.utc):%Y-%m-%d %H:%M} UTC)",
             f"Source: {source}", f"Mode  : {result['evaluation_mode']}", result["evaluation_note"], ""]
    if "training_metrics" in result:
        lines += ["TRAINING-FIT accuracy (not predictive): %.3f" % result["training_metrics"]["accuracy"], ""]
    lines += ["Headline metrics (%s):" % ("held-out test" if holdout_ok else "leave-one-out"),
              f"  accuracy        {headline['accuracy']}",
              f"  macro  P/R/F1   {headline['macro']['precision']} / {headline['macro']['recall']} / {headline['macro']['f1']}",
              f"  weighted P/R/F1 {headline['weighted']['precision']} / {headline['weighted']['recall']} / {headline['weighted']['f1']}", "",
              "Per-class precision / recall / F1 / support:"]
    for l, d in headline["per_class"].items():
        lines.append(f"  {l:<18} {d['precision']:.3f}  {d['recall']:.3f}  {d['f1']:.3f}  {d['support']}")
    (report_dir / "evaluation_report.txt").write_text("\n".join(lines), encoding="utf-8")

    meta = {
        "model_file": model_path.name, "trained_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "algorithm": "TfidfVectorizer(1-2 grams) + LogisticRegression (multinomial)",
        "source": source, "n_foods": result["n_foods"], "classes": labels,
        "evaluation_mode": result["evaluation_mode"], "evaluation_note": result["evaluation_note"],
        "best_params": result["best_params"],
        "headline_accuracy": headline["accuracy"], "headline_macro_f1": headline["macro"]["f1"],
        "headline_label": "held-out test split" if holdout_ok else "leave-one-out",
        "training_accuracy": result.get("training_metrics", {}).get("accuracy"),
        "versions": {"python": platform.python_version(), "scikit-learn": sklearn.__version__,
                     "pandas": pd.__version__, "numpy": np.__version__, "joblib": joblib.__version__},
    }
    meta_path.write_text(json.dumps(meta, indent=2), encoding="utf-8")
    log(f"\nHeadline ({meta['headline_label']}): accuracy={meta['headline_accuracy']}  macro-F1={meta['headline_macro_f1']}")
    log(f"Saved: {model_path.relative_to(ROOT) if model_path.is_relative_to(ROOT) else model_path}, {meta_path.name}, reports/ (confusion matrix: {png})")
    return meta


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--data", help="path to the dataset CSV (default data/raw/nutrition.csv)")
    ap.add_argument("--builtin", action="store_true", help="force the built-in 30-food fallback")
    a = ap.parse_args()
    try:
        train(a.data, a.builtin)
    except Exception as e:
        print("Training failed:", e, file=sys.stderr); sys.exit(1)
