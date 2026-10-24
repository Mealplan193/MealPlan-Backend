"""SQLite access layer for Meal Plan. All SQL uses bound parameters (never string formatting)."""
import csv
import sqlite3
from pathlib import Path

from preprocess import GROUPS

ROOT = Path(__file__).resolve().parent
SCHEMA = ROOT / "schema.sql"
BUILTIN_CSV = ROOT / "data" / "builtin_foods.csv"
DATASET_FOODS_CSV = ROOT / "data" / "processed" / "dataset_foods.csv"
DEFAULT_GOALS = {"calories": 2000, "protein": 100, "carbs": 250, "fat": 65}


def connect(db_path) -> sqlite3.Connection:
    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    return conn


def init_db(db_path, with_dataset=False) -> None:
    """Create all tables from schema.sql and load the built-in foods (+ optional dataset foods)."""
    Path(db_path).parent.mkdir(parents=True, exist_ok=True)
    conn = connect(db_path)
    try:
        conn.executescript(SCHEMA.read_text(encoding="utf-8"))
        conn.executemany("INSERT INTO food_groups(name) VALUES (?)", [(g,) for g in GROUPS])
        seed_foods(conn)
        if with_dataset:
            import_dataset_foods(conn)
        conn.execute("INSERT INTO goals(goal_id, calories, protein, carbs, fat) VALUES (1, ?, ?, ?, ?)",
                     tuple(DEFAULT_GOALS[k] for k in ("calories", "protein", "carbs", "fat")))
        conn.commit()
    finally:
        conn.close()


def _group_ids(conn):
    return {r["name"]: r["group_id"] for r in conn.execute("SELECT group_id, name FROM food_groups")}


def seed_foods(conn) -> int:
    gid = _group_ids(conn)
    with open(BUILTIN_CSV, newline="", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))
    conn.executemany(
        "INSERT OR IGNORE INTO foods(name, group_id, measure, calories, protein, carbs, fat, emoji, is_builtin) "
        "VALUES (?,?,?,?,?,?,?,?,1)",
        [(r["name"], gid[r["group"]], r["measure"], float(r["calories"]), float(r["protein"]),
          float(r["carbs"]), float(r["fat"]), r["emoji"]) for r in rows])
    return len(rows)


def import_dataset_foods(conn) -> int:
    """Load the cleaned Kaggle foods (written by ml.train_model) as built-in reference foods."""
    if not DATASET_FOODS_CSV.exists():
        raise FileNotFoundError("data/processed/dataset_foods.csv not found. Run `python -m ml.train_model` "
                                "with data/raw/nutrition.csv first.")
    import pandas as pd
    df = pd.read_csv(DATASET_FOODS_CSV)
    gid = _group_ids(conn)
    before = conn.execute("SELECT COUNT(*) FROM foods").fetchone()[0]
    conn.executemany(
        "INSERT OR IGNORE INTO foods(name, group_id, measure, calories, protein, carbs, fat, is_builtin) "
        "VALUES (?,?,?,?,?,?,?,1)",
        [(str(r.name).strip().title(), gid[r.group], str(r.measure), float(r.calories), float(r.protein),
          float(r.carbs), float(r.fat)) for r in df.itertuples() if r.group in gid])
    return conn.execute("SELECT COUNT(*) FROM foods").fetchone()[0] - before


def reset_demo_data(conn) -> None:
    """Clear diary, goal history and custom foods; restore default goals."""
    conn.execute("DELETE FROM entries")
    conn.execute("DELETE FROM goal_history")
    conn.execute("DELETE FROM foods WHERE is_builtin = 0")
    conn.execute("DELETE FROM sqlite_sequence WHERE name IN ('entries','goal_history')")
    conn.execute("UPDATE goals SET calories=?, protein=?, carbs=?, fat=? WHERE goal_id=1",
                 tuple(DEFAULT_GOALS[k] for k in ("calories", "protein", "carbs", "fat")))
    conn.commit()
