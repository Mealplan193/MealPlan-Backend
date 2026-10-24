"""Meal Plan - Flask application (REST API + single-page interface).

Run:  python app.py        -> http://127.0.0.1:5000
The app, the SQLite database (schema.sql) and the trained scikit-learn model all work together:
logging a food -> model predicts its food group -> nutrients are looked up in the DB and scaled
by quantity -> the entry is stored -> the dashboard is recomputed from the DB.
"""
import math
import sqlite3
from datetime import datetime
from pathlib import Path

from flask import Flask, g, jsonify, render_template, request

import database
from classifier import FoodClassifier
from preprocess import GROUPS, normalize_name

ROOT = Path(__file__).resolve().parent
ACTIVITY_FACTORS = {1.2, 1.375, 1.55, 1.725}
LIMITS = {"calories": 10000, "protein": 1000, "carbs": 1000, "fat": 1000}


def js_round(x):
    """Round half up, like JavaScript's Math.round (Python's round() rounds half to even)."""
    return int(math.floor(x + 0.5))


class ApiError(Exception):
    def __init__(self, message, status=400):
        super().__init__(message)
        self.message, self.status = message, status


# ---------------------------------------------------------------- validation helpers
def num(value, label, lo=0.0, hi=1e6, strict_low=False):
    if isinstance(value, bool) or value is None or (isinstance(value, str) and not value.strip()):
        raise ApiError(f"{label} must be a valid number.")
    try:
        v = float(value)
    except (TypeError, ValueError):
        raise ApiError(f"{label} must be a valid number.")
    if not math.isfinite(v):
        raise ApiError(f"{label} must be a valid number.")
    if v < lo or (strict_low and v <= lo):
        raise ApiError(f"{label} must be {'greater than' if strict_low else 'at least'} {lo:g}.")
    if v > hi:
        raise ApiError(f"{label} must be at most {hi:g}.")
    return v


def parse_date(value, label="Date"):
    try:
        return datetime.strptime(str(value), "%Y-%m-%d").strftime("%Y-%m-%d")
    except ValueError:
        raise ApiError(f"{label} must be in YYYY-MM-DD format.")


def parse_time(value, label="Time"):
    try:
        return datetime.strptime(str(value), "%H:%M").strftime("%H:%M")
    except ValueError:
        raise ApiError(f"{label} must be in HH:MM format.")


def body():
    data = request.get_json(silent=True)
    if not isinstance(data, dict):
        raise ApiError("Request body must be a JSON object.")
    return data


def food_fields(data):
    name = str(data.get("name", "")).strip()
    if not name:
        raise ApiError("Food name cannot be empty.")
    if len(name) > 80:
        raise ApiError("Food name must be 80 characters or fewer.")
    if not normalize_name(name):
        raise ApiError("Food name must contain letters or numbers.")
    group = str(data.get("group", "")).strip()
    if group not in GROUPS:
        raise ApiError("Please choose one of the listed food groups.")
    measure = str(data.get("measure") or "1 serving").strip()[:40] or "1 serving"
    vals = {k: num(data.get(k), lbl, 0, LIMITS[k]) for k, lbl in
            (("calories", "Calories"), ("protein", "Protein"), ("carbs", "Carbohydrates"), ("fat", "Fat"))}
    return name, group, measure, vals


# ---------------------------------------------------------------- serializers
def food_json(r):
    return {"id": r["food_id"], "name": r["name"], "group": r["group"], "measure": r["measure"],
            "cal": r["calories"], "protein": r["protein"], "carbs": r["carbs"], "fat": r["fat"],
            "emoji": r["emoji"], "builtin": bool(r["is_builtin"])}


def entry_json(r):
    return {"id": r["entry_id"], "foodId": r["food_id"], "name": r["food_name"], "measure": r["measure"],
            "emoji": r["emoji"], "qty": r["quantity"], "cal": r["calories"], "protein": r["protein"],
            "carbs": r["carbs"], "fat": r["fat"], "group": r["final_group"], "predictedGroup": r["predicted_group"],
            "confidence": r["prediction_confidence"], "date": r["entry_date"], "time": r["entry_time"]}


def history_json(r):
    return {"id": r["history_id"], "type": r["record_type"], "date": r["record_date"], "time": r["record_time"],
            "cal": r["calories"], "protein": r["protein"], "carbs": r["carbs"], "fat": r["fat"],
            "applied": bool(r["applied"]), "profile": r["profile_text"], "savedAt": r["saved_at"]}


FOOD_SQL = ("SELECT f.*, g.name AS \"group\" FROM foods f JOIN food_groups g ON g.group_id = f.group_id")
ENTRY_SQL = ("SELECT e.*, pg.name AS predicted_group, fg.name AS final_group FROM entries e "
             "JOIN food_groups pg ON pg.group_id = e.predicted_group_id "
             "JOIN food_groups fg ON fg.group_id = e.final_group_id")


def create_app(config=None):
    app = Flask(__name__)
    app.config.update(
        DB_PATH=str(ROOT / "data" / "mealplan.db"),
        MODEL_PATH=str(ROOT / "models" / "food_classifier.joblib"),
        META_PATH=str(ROOT / "models" / "model_metadata.json"),
        TRAINING_CSV=str(ROOT / "data" / "processed" / "training_foods.csv"),
    )
    if config:
        app.config.update(config)

    # --- database: create on first run
    if not Path(app.config["DB_PATH"]).exists():
        database.init_db(app.config["DB_PATH"])

    # --- model: train the fallback model on first run if no saved model exists
    if not Path(app.config["MODEL_PATH"]).exists():
       from train_model import train
        train(model_path=app.config["MODEL_PATH"], meta_path=app.config["META_PATH"],
              processed_dir=Path(app.config["TRAINING_CSV"]).parent, report_dir=ROOT / "reports", verbose=False)
    clf = FoodClassifier(app.config["MODEL_PATH"], app.config["TRAINING_CSV"], app.config["META_PATH"])
    app.extensions["classifier"] = clf

    def db():
        if "db" not in g:
            g.db = database.connect(app.config["DB_PATH"])
        return g.db

    @app.teardown_appcontext
    def close_db(_exc):
        conn = g.pop("db", None)
        if conn is not None:
            conn.close()

    def retrain():
        rows = db().execute(FOOD_SQL + " WHERE f.is_builtin = 0").fetchall()
        return clf.retrain([(r["name"], r["group"]) for r in rows])

    with app.app_context():                      # make the live model aware of existing custom foods
        if db().execute("SELECT 1 FROM foods WHERE is_builtin = 0 LIMIT 1").fetchone():
            retrain()

    def group_id(name):
        r = db().execute("SELECT group_id FROM food_groups WHERE name = ?", (name,)).fetchone()
        if not r:
            raise ApiError("Unknown food group.")
        return r["group_id"]

    # ------------------------------------------------------------ error handling
    @app.errorhandler(ApiError)
    def handle_api_error(e):
        return jsonify({"error": e.message}), e.status

    @app.errorhandler(404)
    def not_found(_e):
        return (jsonify({"error": "Not found."}), 404) if request.path.startswith("/api/") else ("Not found", 404)

    @app.errorhandler(405)
    def bad_method(_e):
        return jsonify({"error": "Method not allowed."}), 405

    @app.errorhandler(Exception)
    def unexpected(e):
        if hasattr(e, "code") and isinstance(e.code, int):      # werkzeug HTTP exceptions
            return jsonify({"error": getattr(e, "description", "Error")}), e.code
        app.logger.exception("Unhandled error")
        return jsonify({"error": "Something went wrong on the server."}), 500

    # ------------------------------------------------------------ pages
    @app.get("/")
    def index():
        return render_template("index.html")

    # ------------------------------------------------------------ foods
    @app.get("/api/foods")
    def list_foods():
        rows = db().execute(FOOD_SQL + " ORDER BY f.name COLLATE NOCASE").fetchall()
        return jsonify([food_json(r) for r in rows])

    @app.post("/api/foods")
    def add_food():
        name, group, measure, v = food_fields(body())
        try:
            cur = db().execute(
                "INSERT INTO foods(name, group_id, measure, calories, protein, carbs, fat, is_builtin) VALUES (?,?,?,?,?,?,?,0)",
                (name, group_id(group), measure, v["calories"], v["protein"], v["carbs"], v["fat"]))
            db().commit()
        except sqlite3.IntegrityError:
            raise ApiError("That food name already exists.", 409)
        info = retrain()
        row = db().execute(FOOD_SQL + " WHERE f.food_id = ?", (cur.lastrowid,)).fetchone()
        return jsonify({"food": food_json(row), "retrained": info}), 201

    @app.put("/api/foods/<int:food_id>")
    def edit_food(food_id):
        row = db().execute("SELECT is_builtin FROM foods WHERE food_id = ?", (food_id,)).fetchone()
        if not row:
            raise ApiError("Food not found.", 404)
        if row["is_builtin"]:
            raise ApiError("Built-in foods cannot be edited.", 403)
        name, group, measure, v = food_fields(body())
        try:
            db().execute("UPDATE foods SET name=?, group_id=?, measure=?, calories=?, protein=?, carbs=?, fat=? WHERE food_id=?",
                         (name, group_id(group), measure, v["calories"], v["protein"], v["carbs"], v["fat"], food_id))
            db().commit()
        except sqlite3.IntegrityError:
            raise ApiError("That food name already exists.", 409)
        info = retrain()
        return jsonify({"food": food_json(db().execute(FOOD_SQL + " WHERE f.food_id = ?", (food_id,)).fetchone()), "retrained": info})

    @app.delete("/api/foods/<int:food_id>")
    def delete_food(food_id):
        row = db().execute("SELECT is_builtin FROM foods WHERE food_id = ?", (food_id,)).fetchone()
        if not row:
            raise ApiError("Food not found.", 404)
        if row["is_builtin"]:
            raise ApiError("Built-in foods cannot be deleted.", 403)
        db().execute("DELETE FROM foods WHERE food_id = ?", (food_id,))   # entries keep their copy (food_id -> NULL)
        db().commit()
        return jsonify({"deleted": food_id, "retrained": retrain()})

    # ------------------------------------------------------------ model
    @app.post("/api/predict")
    def predict():
        name = str(body().get("name", "")).strip()
        if not name:
            raise ApiError("Food name cannot be empty.")
        try:
            group, conf = clf.predict(name)
        except ValueError as e:
            raise ApiError(str(e))
        return jsonify({"name": name, "group": group, "confidence": round(conf, 4)})

    @app.get("/api/model")
    def model_info():
        return jsonify(clf.info())

    # ------------------------------------------------------------ entries
    @app.get("/api/entries")
    def list_entries():
        d = request.args.get("date")
        if d:
            rows = db().execute(ENTRY_SQL + " WHERE e.entry_date = ? ORDER BY e.entry_time, e.entry_id", (parse_date(d),)).fetchall()
        else:
            rows = db().execute(ENTRY_SQL + " ORDER BY e.entry_date, e.entry_time, e.entry_id").fetchall()
        return jsonify([entry_json(r) for r in rows])

    @app.post("/api/entries")
    def add_entry():
        data = body()
        try:
            fid = int(data.get("food_id"))
        except (TypeError, ValueError):
            raise ApiError("Please choose a food.")
        food = db().execute(FOOD_SQL + " WHERE f.food_id = ?", (fid,)).fetchone()
        if not food:
            raise ApiError("Food not found.", 404)
        qty = num(data.get("quantity"), "Quantity", 0.25, 100)
        entry_date = parse_date(data.get("date") or datetime.now().strftime("%Y-%m-%d"), "Record date")
        entry_time = parse_time(data.get("time") or datetime.now().strftime("%H:%M"), "Record time")
        try:
            group, conf = clf.predict(food["name"])             # <-- model output drives the entry's category
        except ValueError:                                      # name has no usable text: use the food's own group
            group, conf = food["group"], None
        gid = group_id(group)
        cur = db().execute(
            "INSERT INTO entries(food_id, food_name, measure, emoji, quantity, calories, protein, carbs, fat, "
            "predicted_group_id, final_group_id, prediction_confidence, entry_date, entry_time) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
            (fid, food["name"], food["measure"], food["emoji"], qty,
             food["calories"] * qty, food["protein"] * qty, food["carbs"] * qty, food["fat"] * qty,   # N_logged = N_table x Q
             gid, gid, conf, entry_date, entry_time))
        db().commit()
        row = db().execute(ENTRY_SQL + " WHERE e.entry_id = ?", (cur.lastrowid,)).fetchone()
        return jsonify(entry_json(row)), 201

    @app.patch("/api/entries/<int:entry_id>")
    def correct_entry(entry_id):
        grp = str(body().get("group", "")).strip()
        if grp not in GROUPS:
            raise ApiError("Please choose one of the listed food groups.")
        cur = db().execute("UPDATE entries SET final_group_id = ? WHERE entry_id = ?", (group_id(grp), entry_id))
        if cur.rowcount == 0:
            raise ApiError("Entry not found.", 404)
        db().commit()
        return jsonify(entry_json(db().execute(ENTRY_SQL + " WHERE e.entry_id = ?", (entry_id,)).fetchone()))

    @app.delete("/api/entries/<int:entry_id>")
    def delete_entry(entry_id):
        cur = db().execute("DELETE FROM entries WHERE entry_id = ?", (entry_id,))
        if cur.rowcount == 0:
            raise ApiError("Entry not found.", 404)
        db().commit()
        return jsonify({"deleted": entry_id})

    # ------------------------------------------------------------ goals
    def goals_row():
        r = db().execute("SELECT calories, protein, carbs, fat FROM goals WHERE goal_id = 1").fetchone()
        return {"cal": r["calories"], "protein": r["protein"], "carbs": r["carbs"], "fat": r["fat"]}

    @app.get("/api/goals")
    def get_goals():
        return jsonify(goals_row())

    @app.put("/api/goals")
    def save_goals():
        d = body()
        v = {k: num(d.get(k), lbl, 0, LIMITS[k], strict_low=True)
             for k, lbl in (("calories", "Calories"), ("protein", "Protein"), ("carbs", "Carbohydrates"), ("fat", "Fat"))}
        now = datetime.now()
        rdate = parse_date(d.get("date") or now.strftime("%Y-%m-%d"), "Record date")
        rtime = parse_time(d.get("time") or now.strftime("%H:%M"), "Record time")
        db().execute("UPDATE goals SET calories=?, protein=?, carbs=?, fat=? WHERE goal_id=1",
                     (v["calories"], v["protein"], v["carbs"], v["fat"]))
        db().execute("INSERT INTO goal_history(record_type, record_date, record_time, calories, protein, carbs, fat, applied, saved_at) "
                     "VALUES ('manual',?,?,?,?,?,?,1,?)", (rdate, rtime, v["calories"], v["protein"], v["carbs"], v["fat"], now.isoformat()))
        db().commit()
        return jsonify(goals_row())

    @app.post("/api/goals/estimate")
    def estimate_goals():
        """Mifflin-St Jeor BMR x activity factor; split 20% protein / 50% carbs / 30% fat (4/4/9 kcal per g)."""
        d = body()
        sex = str(d.get("sex", "")).lower()
        if sex not in ("male", "female"):
            raise ApiError("Sex must be male or female.")
        age = num(d.get("age"), "Age", 18, 110)
        weight = num(d.get("weight"), "Weight", 0, 500, strict_low=True)
        height = num(d.get("height"), "Height", 0, 272, strict_low=True)
        activity = num(d.get("activity"), "Activity level", 1, 3)
        if activity not in ACTIVITY_FACTORS:
            raise ApiError("Please choose one of the listed activity levels.")
        bmr = js_round(10 * weight + 6.25 * height - 5 * age + (5 if sex == "male" else -161))
        cal = js_round(bmr * activity)
        if cal <= 0:
            raise ApiError("These values give an unrealistic estimate. Please check your profile.")
        protein, carbs, fat = js_round(cal * .20 / 4), js_round(cal * .50 / 4), js_round(cal * .30 / 9)
        now = datetime.now()
        label = str(d.get("activity_label") or "").strip()[:60]
        profile = f"{sex.capitalize()}, {age:g} y, {weight:g} kg, {height:g} cm" + (f", {label}" if label else "")
        cur = db().execute(
            "INSERT INTO goal_history(record_type, record_date, record_time, calories, protein, carbs, fat, applied, profile_text, saved_at) "
            "VALUES ('estimate',?,?,?,?,?,?,0,?,?)",
            (now.strftime("%Y-%m-%d"), now.strftime("%H:%M"), cal, protein, carbs, fat, profile, now.isoformat()))
        db().commit()
        row = db().execute("SELECT * FROM goal_history WHERE history_id = ?", (cur.lastrowid,)).fetchone()
        return jsonify(dict(history_json(row), bmr=bmr)), 201

    @app.post("/api/goals/history/<int:hid>/apply")
    def apply_estimate(hid):
        r = db().execute("SELECT * FROM goal_history WHERE history_id = ?", (hid,)).fetchone()
        if not r:
            raise ApiError("Goal record not found.", 404)
        db().execute("UPDATE goals SET calories=?, protein=?, carbs=?, fat=? WHERE goal_id=1",
                     (r["calories"], r["protein"], r["carbs"], r["fat"]))
        db().execute("UPDATE goal_history SET applied = 1 WHERE history_id = ?", (hid,))
        db().commit()
        return jsonify(goals_row())

    @app.delete("/api/goals/history/<int:hid>")
    def delete_history(hid):
        cur = db().execute("DELETE FROM goal_history WHERE history_id = ?", (hid,))
        if cur.rowcount == 0:
            raise ApiError("Goal record not found.", 404)
        db().commit()
        return jsonify({"deleted": hid})

    # ------------------------------------------------------------ dashboard + suggestions
    def summary_for(day):
        t = db().execute("SELECT COALESCE(SUM(calories),0) c, COALESCE(SUM(protein),0) p, COALESCE(SUM(carbs),0) b, "
                         "COALESCE(SUM(fat),0) f FROM entries WHERE entry_date = ?", (day,)).fetchone()
        totals = {"cal": t["c"], "protein": t["p"], "carbs": t["b"], "fat": t["f"]}
        groups = {r["name"]: r["n"] for r in db().execute(
            "SELECT g.name, COUNT(*) n FROM entries e JOIN food_groups g ON g.group_id = e.final_group_id "
            "WHERE e.entry_date = ? GROUP BY g.name", (day,))}
        return {"date": day, "totals": totals, "groups": groups, "ideas": suggestions(totals)}

    def suggestions(totals):
        """Rule-based ideas (team's own design): foods whose calories fit the remaining calories (+80 kcal
        tolerance), ranked by smallest protein+carb+fat shortfall; top 5. None when every target is met."""
        goals = goals_row()
        rem = {k: goals[k] - totals[k] for k in ("cal", "protein", "carbs", "fat")}
        if all(v <= 0 for v in rem.values()):
            return []
        rows = db().execute(FOOD_SQL).fetchall()
        cand = []
        for r in rows:
            if r["calories"] <= max(0, rem["cal"]) + 80:
                score = (max(rem["protein"] - r["protein"], 0) + max(rem["carbs"] - r["carbs"], 0)
                         + max(rem["fat"] - r["fat"], 0))
                cand.append((score, r["name"].lower(), r))
        cand.sort(key=lambda x: (x[0], x[1]))
        return [dict(food_json(r), score=round(s, 2)) for s, _n, r in cand[:5]]

    @app.get("/api/summary")
    def summary():
        return jsonify(summary_for(parse_date(request.args.get("date") or datetime.now().strftime("%Y-%m-%d"))))

    @app.get("/api/state")
    def state():
        day = parse_date(request.args.get("date") or datetime.now().strftime("%Y-%m-%d"))
        return jsonify({
            "groups": GROUPS,
            "foods": [food_json(r) for r in db().execute(FOOD_SQL + " ORDER BY f.name COLLATE NOCASE")],
            "entries": [entry_json(r) for r in db().execute(ENTRY_SQL + " ORDER BY e.entry_date, e.entry_time, e.entry_id")],
            "goals": goals_row(),
            "goalHistory": [history_json(r) for r in db().execute("SELECT * FROM goal_history ORDER BY history_id")],
            "summary": summary_for(day),
            "model": clf.info(),
        })

    @app.post("/api/reset")
    def reset():
        database.reset_demo_data(db())
        return jsonify({"reset": True, "retrained": retrain()})

    return app


if __name__ == "__main__":
    create_app().run(host="127.0.0.1", port=5000, debug=False)
