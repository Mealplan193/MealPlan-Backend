"""Dataset loading and cleaning for the Meal Plan food-group classifier.

Follows Section V-C of the approved proposal:
  1. remove duplicate and incomplete records
  2. convert nutrient columns to numeric, treating "t" (trace) as 0 in nutrient columns only
  3. normalize food names (lowercase, trim whitespace)
  4. keep: food name, category, measure, grams, calories, protein, carbohydrates, fat
The split into train/test happens in train_model.py.
"""
import re
import unicodedata
from pathlib import Path

import numpy as np
import pandas as pd

GROUPS = [
    "Fruits", "Vegetables", "Desserts", "Protein", "Grains and carbs",
    "Dairy", "Nuts and seeds", "Fats and oils", "Beverages", "Snacks",
]

NUTRIENT_COLS = ["grams", "calories", "protein", "carbs", "fat"]

# Column-name aliases so the loader accepts the Kaggle file ("Nutritional Facts for Most
# Common Foods") as well as the cleaned built-in table.
COLUMN_ALIASES = {
    "name": ["name", "food", "food_name", "item"],
    "category": ["category", "group", "food_group"],
    "measure": ["measure", "serving"],
    "grams": ["grams", "gram", "weight"],
    "calories": ["calories", "kcal", "energy"],
    "protein": ["protein", "proteins"],
    "carbs": ["carbs", "carbohydrates", "carbohydrate", "carbohydrt"],
    "fat": ["fat", "fats", "total_fat"],
}


def normalize_name(text) -> str:
    """Lowercase, strip accents/punctuation (keeping letters, digits, spaces, hyphens)."""
    text = unicodedata.normalize("NFKD", str(text)).encode("ascii", "ignore").decode()
    text = re.sub(r"[^a-z0-9\s-]", " ", text.lower())
    return re.sub(r"\s+", " ", text).strip()


def map_category(raw) -> str | None:
    """Map a source-dataset category onto one of the app's 10 broad food groups.

    The Kaggle table splits some groups alphabetically (e.g. "Vegetables A-E",
    "Vegetables F-P"); those are merged here. Categories with no sensible equivalent
    (e.g. soups) return None and are dropped.
    """
    r = str(raw).strip().lower()
    if r in {g.lower() for g in GROUPS}:
        return next(g for g in GROUPS if g.lower() == r)
    rules = [
        (("dessert", "jam", "jell"), "Desserts"),
        (("dairy", "milk", "cheese"), "Dairy"),
        (("fats", "oils", "shortening"), "Fats and oils"),
        (("meat", "poultry", "fish", "seafood", "egg"), "Protein"),
        (("vegetable",), "Vegetables"),
        (("fruit",), "Fruits"),
        (("bread", "cereal", "grain", "fastfood", "fast food"), "Grains and carbs"),
        (("seed", "nut"), "Nuts and seeds"),
        (("drink", "beverage", "alcohol"), "Beverages"),
        (("snack",), "Snacks"),
    ]
    for keys, group in rules:
        if any(k in r for k in keys):
            return group
    return None


def _to_number(series: pd.Series) -> pd.Series:
    """Numeric conversion; 't' (trace) -> 0. Used on nutrient columns only."""
    s = series.astype(str).str.strip().str.lower().str.replace(",", "", regex=False)
    s = s.replace({"t": "0", "": np.nan, "nan": np.nan, "-": np.nan, "none": np.nan})
    return pd.to_numeric(s, errors="coerce")


def _standardize_columns(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    df.columns = [str(c).strip().lower().replace(".", "_").replace(" ", "_") for c in df.columns]
    rename = {}
    for target, aliases in COLUMN_ALIASES.items():
        for a in aliases:
            if a in df.columns and target not in rename.values():
                rename[a] = target
                break
    df = df.rename(columns=rename)
    missing = [c for c in ("name", "category", "calories", "protein", "carbs", "fat") if c not in df.columns]
    if missing:
        raise ValueError(f"Dataset is missing required column(s): {missing}. Found: {list(df.columns)}")
    return df


def load_dataset(path) -> tuple[pd.DataFrame, dict]:
    """Load + clean a CSV. Returns (clean_df, report) where report counts every dropped row."""
    raw = pd.read_csv(path, encoding="utf-8-sig")
    report = {"rows_read": int(len(raw))}
    df = _standardize_columns(raw)

    if "measure" not in df.columns:
        df["measure"] = "1 serving"        # measure is text ("t" = teaspoon): never numeric-converted
    if "grams" not in df.columns:
        df["grams"] = np.nan

    for c in NUTRIENT_COLS:
        df[c] = _to_number(df[c])

    df["name"] = df["name"].astype(str).str.strip()
    keep = ["name", "category", "measure", "grams", "calories", "protein", "carbs", "fat"]
    df = df[keep + [c for c in ("emoji",) if c in df.columns]]

    before = len(df)
    df = df.dropna(subset=["name", "category", "calories", "protein", "carbs", "fat"])
    df = df[df["name"].str.len() > 0]
    df = df[(df[["calories", "protein", "carbs", "fat"]] >= 0).all(axis=1)]
    report["dropped_incomplete_or_negative"] = int(before - len(df))

    df["name_norm"] = df["name"].map(normalize_name)
    before = len(df)
    df = df[df["name_norm"].str.len() > 0].drop_duplicates(subset="name_norm", keep="first")
    report["dropped_duplicates"] = int(before - len(df))

    df["group"] = df["category"].map(map_category)
    before = len(df)
    df = df.dropna(subset=["group"])
    report["dropped_unmapped_category"] = int(before - len(df))

    df = df.reset_index(drop=True)
    report["rows_kept"] = int(len(df))
    report["class_counts"] = {k: int(v) for k, v in df["group"].value_counts().items()}
    return df, report


def load_builtin(path) -> pd.DataFrame:
    """The 30-food built-in table (also the fallback training set)."""
    df = pd.read_csv(path, encoding="utf-8")
    df["name_norm"] = df["name"].map(normalize_name)
    df["category"] = df["group"]
    return df
