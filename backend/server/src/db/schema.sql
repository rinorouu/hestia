-- Skema database Hestia (SQLite) — sesuai data model di docs/ARCHITECTURE.md.
-- Hanya metadata; file asli foto/video tetap di HDD eksternal.

PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS users (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  email         TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  display_name  TEXT,
  role          TEXT NOT NULL DEFAULT 'user',      -- 'admin' | 'user'
  created_at    DATETIME NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS files (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id     INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  filename    TEXT NOT NULL,
  rel_path    TEXT NOT NULL,                        -- path relatif dari root user di HDD
  mime_type   TEXT,
  size_bytes  INTEGER NOT NULL DEFAULT 0,
  thumb_path  TEXT,                                 -- nullable, path thumbnail
  checksum    TEXT,                                 -- future: duplicate detection
  uploaded_at DATETIME NOT NULL DEFAULT (datetime('now')),
  taken_at    DATETIME                              -- nullable, dari EXIF
);

CREATE INDEX IF NOT EXISTS idx_files_user      ON files(user_id);
CREATE INDEX IF NOT EXISTS idx_files_uploaded  ON files(uploaded_at);

CREATE TABLE IF NOT EXISTS upload_history (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id    INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  file_id    INTEGER REFERENCES files(id) ON DELETE SET NULL,  -- nullable jika gagal
  status     TEXT NOT NULL,                          -- 'success' | 'failed'
  message    TEXT,
  created_at DATETIME NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_history_user ON upload_history(user_id);
