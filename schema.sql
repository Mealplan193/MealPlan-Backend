-- Meal Plan database schema (SQLite)
-- Run automatically by `python init_db.py`; safe to read as documentation of the data model.
PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS goal_history;
DROP TABLE IF EXISTS goals;
DROP TABLE IF EXISTS entries;
DROP TABLE IF EXISTS foods;
DROP TABLE IF EXISTS food_groups;

-- Ten broad food groups (the classifier's target classes)
CREATE TABLE food_groups (
    group_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name     TEXT NOT NULL UNIQUE
);

-- Reference food table: one consistent source for nutrient values (per stated measure)
CREATE TABLE foods (
    food_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    name       TEXT NOT NULL UNIQUE COLLATE NOCASE,
    group_id   INTEGER NOT NULL REFERENCES food_groups(group_id),
    measure    TEXT NOT NULL DEFAULT '1 serving',
    calories   REAL NOT NULL CHECK (calories >= 0),
    protein    REAL NOT NULL CHECK (protein  >= 0),
    carbs      REAL NOT NULL CHECK (carbs    >= 0),
    fat        REAL NOT NULL CHECK (fat      >= 0),
    emoji      TEXT NOT NULL DEFAULT '🍽️',
    is_builtin INTEGER NOT NULL DEFAULT 0 CHECK (is_builtin IN (0, 1))
);

-- Diary entries. Nutrient values are copied at logging time (quantity-scaled), so later
-- edits to the food table do not change past entries. food_id becomes NULL if the food is deleted.
CREATE TABLE entries (
    entry_id            INTEGER PRIMARY KEY AUTOINCREMENT,
    food_id             INTEGER REFERENCES foods(food_id) ON DELETE SET NULL,
    food_name           TEXT NOT NULL,
    measure             TEXT NOT NULL,
    emoji               TEXT NOT NULL DEFAULT '🍽️',
    quantity            REAL NOT NULL CHECK (quantity >= 0.25),
    calories            REAL NOT NULL,
    protein             REAL NOT NULL,
    carbs               REAL NOT NULL,
    fat                 REAL NOT NULL,
    predicted_group_id  INTEGER NOT NULL REFERENCES food_groups(group_id),
    final_group_id      INTEGER NOT NULL REFERENCES food_groups(group_id),
    prediction_confidence REAL,
    entry_date          TEXT NOT NULL,          -- YYYY-MM-DD
    entry_time          TEXT NOT NULL,          -- HH:MM
    created_at          TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_entries_date ON entries(entry_date);

-- Current daily targets (single user => exactly one row)
CREATE TABLE goals (
    goal_id  INTEGER PRIMARY KEY CHECK (goal_id = 1),
    calories REAL NOT NULL CHECK (calories > 0),
    protein  REAL NOT NULL CHECK (protein  > 0),
    carbs    REAL NOT NULL CHECK (carbs    > 0),
    fat      REAL NOT NULL CHECK (fat      > 0)
);

-- Every saved target set or profile-based estimate, with the date/time the user recorded
CREATE TABLE goal_history (
    history_id  INTEGER PRIMARY KEY AUTOINCREMENT,
    record_type TEXT NOT NULL CHECK (record_type IN ('manual', 'estimate')),
    record_date TEXT NOT NULL,
    record_time TEXT NOT NULL,
    calories    REAL NOT NULL,
    protein     REAL NOT NULL,
    carbs       REAL NOT NULL,
    fat         REAL NOT NULL,
    applied     INTEGER NOT NULL DEFAULT 0 CHECK (applied IN (0, 1)),
    profile_text TEXT,
    saved_at    TEXT NOT NULL
);
