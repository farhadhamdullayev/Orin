import os
import sqlite3
from contextlib import contextmanager

DB_PATH = os.environ.get("ORIN_DB_PATH", os.path.join(os.path.dirname(os.path.abspath(__file__)), "orin.db"))

SCHEMA = """
CREATE TABLE IF NOT EXISTS users (
  device_id   TEXT PRIMARY KEY,
  display_name TEXT NOT NULL,
  created_at  TEXT NOT NULL,
  points      INTEGER NOT NULL DEFAULT 0,
  wins        INTEGER NOT NULL DEFAULT 0,
  losses      INTEGER NOT NULL DEFAULT 0,
  draws       INTEGER NOT NULL DEFAULT 0,
  current_band TEXT NOT NULL DEFAULT 'A1',
  month_points INTEGER NOT NULL DEFAULT 0,
  month_key   TEXT NOT NULL DEFAULT ''
);

CREATE TABLE IF NOT EXISTS friends (
  device_id   TEXT NOT NULL,
  friend_id   TEXT NOT NULL,
  created_at  TEXT NOT NULL,
  PRIMARY KEY (device_id, friend_id)
);

CREATE TABLE IF NOT EXISTS push_subscriptions (
  device_id   TEXT PRIMARY KEY,
  endpoint    TEXT NOT NULL,
  p256dh      TEXT NOT NULL,
  auth        TEXT NOT NULL,
  created_at  TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS catalog_items (
  item_id     TEXT PRIMARY KEY,
  type        TEXT NOT NULL,      -- 'word' | 'grammar'
  band        TEXT NOT NULL,      -- CEFR band this item belongs to
  rank        INTEGER,            -- word frequency rank (word items only)
  question    TEXT,               -- grammar items only: sentence with blank
  options     TEXT,               -- grammar items only: JSON array of option strings
  correct_answer TEXT             -- grammar items only: correct option text
);
CREATE INDEX IF NOT EXISTS idx_catalog_type_band ON catalog_items(type, band);

CREATE TABLE IF NOT EXISTS duels (
  duel_id       TEXT PRIMARY KEY,
  mode          TEXT NOT NULL,    -- 'word' | 'grammar'
  band          TEXT NOT NULL,
  questions     TEXT NOT NULL,    -- JSON: full internal question spec (includes correct answers)
  player1_id    TEXT NOT NULL,
  player2_id    TEXT,
  status        TEXT NOT NULL DEFAULT 'open',  -- open|active|done
  created_at    TEXT NOT NULL,
  p1_finished_at TEXT,
  p2_finished_at TEXT,
  winner_id     TEXT
);
CREATE INDEX IF NOT EXISTS idx_duels_open ON duels(status, mode, band);

CREATE TABLE IF NOT EXISTS duel_answers (
  duel_id     TEXT NOT NULL,
  device_id   TEXT NOT NULL,
  qid         TEXT NOT NULL,
  chosen      TEXT NOT NULL,
  correct     INTEGER NOT NULL,
  time_ms     INTEGER NOT NULL,
  points      INTEGER NOT NULL,
  answered_at TEXT NOT NULL,
  PRIMARY KEY (duel_id, device_id, qid)
);
"""


# Additive migrations for columns introduced after the initial CREATE TABLE — SQLite
# has no "ADD COLUMN IF NOT EXISTS", so each is guarded against "duplicate column".
MIGRATIONS = [
    "ALTER TABLE users ADD COLUMN month_points INTEGER NOT NULL DEFAULT 0",
    "ALTER TABLE users ADD COLUMN month_key TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE users ADD COLUMN invite_code TEXT",
    "ALTER TABLE duels ADD COLUMN target_friend_id TEXT",
    "ALTER TABLE users ADD COLUMN due_count INTEGER NOT NULL DEFAULT 0",
    "ALTER TABLE users ADD COLUMN today_points INTEGER NOT NULL DEFAULT 0",
    "ALTER TABLE users ADD COLUMN today_mastered INTEGER NOT NULL DEFAULT 0",
    "ALTER TABLE users ADD COLUMN activity_day_key TEXT NOT NULL DEFAULT ''",
    "ALTER TABLE users ADD COLUMN last_activity_at TEXT",
    "ALTER TABLE users ADD COLUMN last_notified_at TEXT",
    "ALTER TABLE users ADD COLUMN lang TEXT NOT NULL DEFAULT 'az'",
]


def init_db():
    conn = sqlite3.connect(DB_PATH)
    conn.executescript(SCHEMA)
    for stmt in MIGRATIONS:
        try:
            conn.execute(stmt)
        except sqlite3.OperationalError as e:
            if "duplicate column" not in str(e):
                raise
    # runs after migrations so the invite_code column is guaranteed to exist,
    # on both a fresh DB and one upgraded from an older schema
    conn.execute("CREATE UNIQUE INDEX IF NOT EXISTS idx_users_invite_code ON users(invite_code)")
    conn.execute("PRAGMA journal_mode=WAL;")
    conn.commit()
    conn.close()


@contextmanager
def get_conn():
    conn = sqlite3.connect(DB_PATH, timeout=10)
    conn.execute("PRAGMA journal_mode=WAL;")
    conn.row_factory = sqlite3.Row
    try:
        yield conn
        conn.commit()
    finally:
        conn.close()
