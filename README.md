# Meal Plan - Web-Based Nutrition Tracking with Text-Based Food Classification

Flask web app + SQLite database + scikit-learn model (TF-IDF + Logistic Regression), working together.

```
Browser UI  --fetch-->  Flask REST API  --SQL-->  SQLite (schema.sql)
                              |
                              +--> trained model (models/food_classifier.joblib)
```

Logging a food: the API asks the **model** for the food group -> looks up nutrients in the **database** and scales
them by quantity (`N_logged = N_table x Q`) -> stores the entry -> the dashboard is recomputed from the database.
Adding / editing / deleting a custom food retrains the classifier in memory.

## Important: GitHub Pages vs. the full paper implementation

The live GitHub Pages site (`https://mealplan193.github.io/MealPlan/`) is a separate static/browser prototype. GitHub Pages cannot execute this Flask backend, the SQLite database, or the scikit-learn model. This repository package is the full Python implementation described in the paper. Run it locally with the setup below or deploy it to a Python-capable host. If keeping GitHub Pages for the interface, a separately hosted API and frontend API-base configuration are required; uploading Python files to Pages is not enough.

## 1. Setup (about 2 minutes)

Requires Python 3.10+.

```bash
python -m venv venv
venv\Scripts\activate            # Windows        (macOS/Linux: source venv/bin/activate)
pip install -r requirements.txt
python app.py                    # open http://127.0.0.1:5000
```

On first run the app creates `data/mealplan.db` and, if no saved model exists, trains one automatically.
This package already includes a ready database (332 foods plus demo diary entries) and a model trained on the Kaggle dataset, so it runs immediately.

Optional commands:

| Command | What it does |
|---|---|
| `python init_db.py` | Recreate a minimal database (schema + 30 built-in foods + default goals) |
| `python init_db.py --with-dataset --demo` | Same, plus the cleaned Kaggle foods and demonstration diary entries for today and yesterday (this is how the shipped database was built) |
| `sqlite3 restored.db < data/mealplan_export.sql` | Restore the demo database from the SQL export into a new file |
| `python -m ml.train_model` | Retrain + evaluate the classifier, write `models/` and `reports/` |
| `python run_tests.py` | Run all tests, save `reports/test_results.txt` |

## 2. Dataset access (IMPORTANT - read before the final run)

The approved proposal specifies the Kaggle dataset **"Nutritional Facts for Most Common Foods"** (niharika41298):
https://www.kaggle.com/datasets/niharika41298/nutrition-details-for-most-common-foods

The Kaggle CSV is **included** as `data/raw/nutrition.csv`, and the shipped model was trained on it. If you ever need to
download it again, it requires a free Kaggle login (use "Download dataset as zip" and save the CSV under that name).
To retrain and rebuild:

```bash
python -m ml.train_model          # cleans -> stratified 80/20 split -> CV tuning -> test evaluation -> saves model
python init_db.py --with-dataset --demo   # rebuild the database with the cleaned dataset foods + demo entries
python app.py
```

`ml.train_model` auto-detects `data/raw/nutrition.csv`. It maps the dataset's categories onto the app's 10 food groups
(e.g. "Vegetables A-E/F-P/R-Z" -> Vegetables; see `ml/preprocess.py::map_category`), drops categories with no equivalent
(Soups), and follows proposal Section V-C (dedupe, "t" trace -> 0 in nutrient columns only, normalize names).
The dataset has no snack category, so the two built-in Snacks foods are added to the training data.

Current result (held-out 20% test split, 64 foods): accuracy 0.578, macro F1 0.546 (see `reports/evaluation_report.txt`).

**Without the CSV** the project falls back to the built-in 30-food table. That set is too small for a valid held-out
split, so the script reports training-fit and leave-one-out accuracy and says plainly that training accuracy is not
predictive performance.

## 3. Project structure

```
app.py               Flask app: REST API, validation, rule-based suggestions, model integration
database.py          SQLite layer (parameterised SQL), seeding, reset
init_db.py           Database setup script (+ --demo, --with-dataset)
schema.sql           Tables and relationships
ml/preprocess.py     Dataset loading/cleaning, category mapping, name normalisation (also used at inference)
ml/train_model.py    Training, tuning, evaluation, model + report export
ml/classifier.py     Runtime wrapper: predict, retrain with custom foods
models/              food_classifier.joblib (trained pipeline incl. TF-IDF vectoriser), model_metadata.json
data/                builtin_foods.csv, mealplan.db (demo), mealplan_export.sql, processed/, raw/ (Kaggle CSV)
templates/, static/  Interface (your original design) + JavaScript that calls the API
tests/               test_api.py (functional + DB), test_ml.py (ML), test_ui.py (real browser, Playwright)
reports/             evaluation_report.*, confusion_matrix.png, test_results.txt, screenshots/
```

## 4. Database

| Table | Purpose | Relationships |
|---|---|---|
| `food_groups` | the 10 food groups | - |
| `foods` | reference foods + nutrients per measure | `group_id` -> food_groups |
| `entries` | diary entries (nutrients stored at logging time) | `food_id` -> foods (SET NULL on delete); `predicted_group_id`, `final_group_id` -> food_groups |
| `goals` | current daily targets (single row) | - |
| `goal_history` | saved targets / profile estimates with date and time | - |

Operations implemented: create/read/update/delete for foods and entries; save/read goals; goal history add/apply/delete;
daily aggregates (`SUM ... GROUP BY`); reset. CHECK constraints and foreign keys are enforced by SQLite itself.

## 5. API summary

`GET /api/state` | `GET/POST /api/foods` | `PUT/DELETE /api/foods/<id>` | `GET/POST /api/entries` |
`PATCH/DELETE /api/entries/<id>` | `GET/PUT /api/goals` | `POST /api/goals/estimate` |
`POST /api/goals/history/<id>/apply` | `DELETE /api/goals/history/<id>` | `GET /api/summary?date=` |
`POST /api/predict` | `GET /api/model` | `POST /api/reset`

Errors return `{"error": "..."}` with 400 (invalid input), 403 (built-in food), 404, or 409 (duplicate name).

## 6. Testing

`python run_tests.py` runs 35 tests: 26 API/database tests (test IDs FL, EM, FB, GS, DB, FS, PS from the paper's
Table V, plus DI integrity tests), 8 ML tests, and 1 real-browser end-to-end test that drives the UI.
The browser test needs `pip install playwright && playwright install chromium`; it is skipped if unavailable.

## 7. Known limitations

- Single user, no login (as in the approved scope). No CSRF protection - intended for local/classroom use.
- Held-out accuracy is 57.8%: food names alone are short and ambiguous, so users can correct any predicted group.
- `joblib` model files are tied to the scikit-learn version that created them. If you see a version warning or
  load error, run `python -m ml.train_model` to rebuild the model.
- Nutrient values are approximate estimates, not medical advice.
- The Dashboard includes a date selector for reviewing past-day totals; the Food diary also has its own date filter.
