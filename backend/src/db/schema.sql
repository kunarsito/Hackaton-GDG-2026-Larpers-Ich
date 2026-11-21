PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS users (
  id            TEXT PRIMARY KEY,
  name          TEXT NOT NULL,
  university    TEXT NOT NULL DEFAULT '',
  karma_points  INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS challenges (
  id             TEXT PRIMARY KEY,
  title          TEXT NOT NULL,
  difficulty     TEXT NOT NULL CHECK (difficulty IN ('Básico', 'Intermedio', 'Avanzado')),
  category       TEXT NOT NULL,
  description    TEXT NOT NULL,
  starter_code   TEXT NOT NULL,
  function_name  TEXT NOT NULL,
  test_cases     TEXT NOT NULL DEFAULT '[]', -- JSON TestCase[]
  sort_order     INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS solved_challenges (
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  challenge_id  TEXT NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
  solved_at     TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  PRIMARY KEY (user_id, challenge_id)
);

CREATE TABLE IF NOT EXISTS articles (
  id                    TEXT PRIMARY KEY,
  title                 TEXT NOT NULL,
  pioneer_name          TEXT NOT NULL,
  era                   TEXT NOT NULL,
  summary               TEXT NOT NULL,
  content               TEXT NOT NULL,
  related_challenge_id  TEXT REFERENCES challenges(id),
  sort_order            INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS forum_posts (
  id            TEXT PRIMARY KEY,
  author_id     TEXT NOT NULL,
  author_name   TEXT NOT NULL,
  title         TEXT NOT NULL,
  body          TEXT NOT NULL,
  code_snippet  TEXT NOT NULL DEFAULT '',
  challenge_id  TEXT,
  upvotes       INTEGER NOT NULL DEFAULT 0,
  created_at    TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE TABLE IF NOT EXISTS forum_replies (
  id           TEXT PRIMARY KEY,
  post_id      TEXT NOT NULL REFERENCES forum_posts(id) ON DELETE CASCADE,
  author_id    TEXT,
  author_name  TEXT NOT NULL,
  body         TEXT NOT NULL,
  upvotes      INTEGER NOT NULL DEFAULT 0,
  created_at   TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_replies_post ON forum_replies(post_id);

CREATE TABLE IF NOT EXISTS jobs (
  id                 TEXT PRIMARY KEY,
  title              TEXT NOT NULL,
  company_or_poster  TEXT NOT NULL,
  type               TEXT NOT NULL CHECK (type IN ('Pasantía', 'Junior', 'Freelance')),
  modality           TEXT NOT NULL,
  description        TEXT NOT NULL,
  requirements       TEXT NOT NULL DEFAULT '[]', -- JSON string[]
  contact_url        TEXT NOT NULL,
  created_at         TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);
