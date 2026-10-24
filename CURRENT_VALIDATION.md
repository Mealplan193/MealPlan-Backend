# Current validation notes

This note distinguishes previously recorded project results from checks that could be repeated in the current editing environment.

## Paper-reported results (from the included project reports)

- Dataset: 316 foods across 10 food groups.
- Model: TF-IDF word unigrams/bigrams + Logistic Regression.
- Held-out evaluation: 64 foods; accuracy 57.8%; macro F1 0.546. The Snacks class has no held-out examples.
- The included historical test report records 35 tests passing in its original environment.

## Checks repeated while preparing this revision

- JavaScript syntax check (`node --check static/js/app.js`): passed.
- SQLite database inspection: 332 food records, 10 food groups, 10 demo diary entries, 1 goals row; `PRAGMA foreign_key_check` reported no violations.
- Full Python test suite: **not fully runnable in the current environment** because Flask/Werkzeug are not installed and network access prevented installing the declared dependencies. The ML-focused tests that could import successfully passed, but the API/UI test modules failed at import time. Do not present this current run as 35 passing tests.

## Changes in this revision

- Added a Dashboard date selector and wired it to the Flask `/api/state?date=YYYY-MM-DD` response so the totals, group breakdown, recent entries, and food ideas reflect the selected date.
- Updated README deployment guidance to distinguish the static GitHub Pages prototype from the full Flask/SQLite/scikit-learn implementation.

## Re-run validation locally

```bash
python -m pip install -r requirements.txt
python run_tests.py
```

The browser test additionally requires Playwright and its Chromium browser (`playwright install chromium`).
