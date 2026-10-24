"""Create (or recreate) the Meal Plan SQLite database.

    python init_db.py                  # schema + 30 built-in foods + default goals  -> data/mealplan.db
    python init_db.py --with-dataset   # also import the cleaned Kaggle foods (after `python -m ml.train_model`)
    python init_db.py --demo           # also insert a small set of demonstration entries
    python init_db.py --path other.db
"""
import argparse
from datetime import date, timedelta
from pathlib import Path

import database

DEFAULT_DB = Path(__file__).resolve().parent / "data" / "mealplan.db"

if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--path", default=str(DEFAULT_DB))
    ap.add_argument("--with-dataset", action="store_true")
    ap.add_argument("--demo", action="store_true", help="add demonstration diary entries (today and yesterday)")
    a = ap.parse_args()
    database.init_db(a.path, with_dataset=a.with_dataset)
    if a.demo:
        from app import create_app
        app = create_app({"DB_PATH": a.path})
        c = app.test_client()
        foods = {f["name"]: f["id"] for f in c.get("/api/foods").get_json()}
        plan = {0: [("Oatmeal", 1, "07:30"), ("Banana", 2, "07:45"), ("Chicken breast", 1.5, "12:15"),
                    ("Brown rice", 1, "12:15"), ("Almonds", 1, "15:30")],
                1: [("Egg", 2, "08:00"), ("Whole wheat bread", 2, "08:00"), ("Salmon", 1.5, "19:00"),
                    ("Broccoli", 1, "19:00"), ("Vanilla ice cream", 1, "20:30")]}
        for back, items in plan.items():
            d = (date.today() - timedelta(days=back)).isoformat()
            for food, qty, t in items:
                c.post("/api/entries", json={"food_id": foods[food], "quantity": qty, "date": d, "time": t})
    conn = database.connect(a.path)
    n = {t: conn.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0] for t in ("food_groups", "foods", "entries", "goals", "goal_history")}
    print(f"Database ready at {a.path}: {n}")
