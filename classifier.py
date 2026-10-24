"""Runtime wrapper around the trained scikit-learn pipeline used by the Flask app."""
import json
import threading
from pathlib import Path

import joblib
import pandas as pd
from sklearn.base import clone

from preprocess import normalize_name


class FoodClassifier:
    """Loads the saved pipeline, predicts a food group + confidence, and can retrain in memory
    when the user adds/edits/deletes custom foods (base training corpus + custom foods)."""

    def __init__(self, model_path, training_csv, meta_path=None):
        self.model_path, self.training_csv = Path(model_path), Path(training_csv)
        self.meta = json.loads(Path(meta_path).read_text(encoding="utf-8")) if meta_path and Path(meta_path).exists() else {}
        self._base = joblib.load(self.model_path)
        self._pipe = self._base
        self._lock = threading.Lock()
        self.retrain_count = 0

    @property
    def classes(self):
        return list(self._pipe.classes_)

    def predict(self, name: str):
        """Return (group, confidence 0-1) for a food name."""
        if not normalize_name(name):
            raise ValueError("Food name is empty after normalisation.")
        with self._lock:
            pipe = self._pipe
        proba = pipe.predict_proba([str(name)])[0]
        i = int(proba.argmax())
        return str(pipe.classes_[i]), float(proba[i])

    def retrain(self, custom_foods):
        """Retrain on the saved training corpus plus (name, group) pairs from the DB's custom foods."""
        base = pd.read_csv(self.training_csv)
        extra = pd.DataFrame(list(custom_foods), columns=["name", "group"])
        df = pd.concat([base, extra], ignore_index=True)
        df["k"] = df["name"].map(normalize_name)
        df = df.drop_duplicates("k", keep="last")          # custom/edited foods override
        pipe = clone(self._base).fit(df["name"].astype(str), df["group"].astype(str))
        with self._lock:
            self._pipe = pipe
            self.retrain_count += 1
        return {"n_training": int(len(df)), "vocabulary": int(len(pipe.named_steps["tfidf"].vocabulary_))}

    def info(self):
        v = len(self._pipe.named_steps["tfidf"].vocabulary_)
        return {**self.meta, "vocabulary": int(v), "retrain_count": self.retrain_count}
