PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS users (
  id            TEXT PRIMARY KEY,
  name          TEXT NOT NULL,
  university    TEXT NOT NULL DEFAULT '',
  karma_points  INTEGER NOT NULL DEFAULT 0
);

-- Login: credenciales (contraseña con scrypt) separadas del perfil público
CREATE TABLE IF NOT EXISTS auth_credentials (
  user_id        TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  email          TEXT NOT NULL UNIQUE COLLATE NOCASE,
  password_hash  TEXT NOT NULL, -- scrypt$<salt hex>$<hash hex>
  created_at     TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

-- Sesiones: se guarda sólo el SHA-256 del token, nunca el token en claro
CREATE TABLE IF NOT EXISTS sessions (
  token_hash  TEXT PRIMARY KEY,
  user_id     TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at  TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  expires_at  TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_sessions_user ON sessions(user_id);

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

-- =====================================================================
-- Red social (SRS v2, RF-09 a RF-18). Las columnas nuevas de las tablas
-- anteriores (bio, source, votos, adjuntos...) se agregan en
-- database.ts -> migrate(), para que también lleguen a bases existentes.
-- =====================================================================

CREATE TABLE IF NOT EXISTS follows (
  follower_id  TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  followee_id  TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at   TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  PRIMARY KEY (follower_id, followee_id)
);

-- Un voto por usuario y objetivo (post, respuesta, artículo o reto)
CREATE TABLE IF NOT EXISTS votes (
  user_id      TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  target_type  TEXT NOT NULL CHECK (target_type IN ('post', 'reply', 'article', 'challenge')),
  target_id    TEXT NOT NULL,
  value        INTEGER NOT NULL CHECK (value IN (-1, 1)),
  PRIMARY KEY (user_id, target_type, target_id)
);

CREATE TABLE IF NOT EXISTS saved_posts (
  user_id     TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  post_id     TEXT NOT NULL REFERENCES forum_posts(id) ON DELETE CASCADE,
  created_at  TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  PRIMARY KEY (user_id, post_id)
);

CREATE TABLE IF NOT EXISTS courses (
  id           TEXT PRIMARY KEY,
  source       TEXT NOT NULL CHECK (source IN ('official', 'community')),
  author_id    TEXT REFERENCES users(id) ON DELETE SET NULL,
  title        TEXT NOT NULL,
  description  TEXT NOT NULL,
  cover_url    TEXT,
  level        TEXT NOT NULL CHECK (level IN ('Básico', 'Intermedio', 'Avanzado')),
  tags         TEXT NOT NULL DEFAULT '[]', -- JSON string[]
  lessons      TEXT NOT NULL DEFAULT '[]', -- JSON CourseLesson[]
  created_at   TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE TABLE IF NOT EXISTS course_enrollments (
  course_id     TEXT NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  completed_at  TEXT,
  created_at    TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  PRIMARY KEY (course_id, user_id)
);

CREATE TABLE IF NOT EXISTS course_ratings (
  course_id  TEXT NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  user_id    TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  rating     INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  PRIMARY KEY (course_id, user_id)
);

-- Archivos subidos (se guardan en disco: UPLOADS_DIR)
CREATE TABLE IF NOT EXISTS attachments (
  id           TEXT PRIMARY KEY,
  owner_id     TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  file_name    TEXT NOT NULL,
  mime_type    TEXT NOT NULL,
  size_bytes   INTEGER NOT NULL,
  stored_name  TEXT NOT NULL UNIQUE,
  created_at   TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

-- Mensajes privados 1 a 1 (user_a < user_b para que la pareja sea única)
CREATE TABLE IF NOT EXISTS conversations (
  id               TEXT PRIMARY KEY,
  user_a           TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  user_b           TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  last_message_at  TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  UNIQUE (user_a, user_b)
);

CREATE TABLE IF NOT EXISTS messages (
  id               TEXT PRIMARY KEY,
  conversation_id  TEXT NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id        TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  body             TEXT NOT NULL DEFAULT '',
  attachments      TEXT NOT NULL DEFAULT '[]', -- JSON Attachment[]
  created_at       TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  read_at          TEXT
);

CREATE INDEX IF NOT EXISTS idx_messages_conv ON messages(conversation_id, created_at);

CREATE TABLE IF NOT EXISTS job_applications (
  id            TEXT PRIMARY KEY,
  job_id        TEXT NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  applicant_id  TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  cv_url        TEXT NOT NULL,
  message       TEXT NOT NULL DEFAULT '',
  status        TEXT NOT NULL DEFAULT 'enviada' CHECK (status IN ('enviada', 'vista', 'contactado')),
  created_at    TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
  UNIQUE (job_id, applicant_id)
);

-- Auditoría de Karma (también limita los regalos diarios)
CREATE TABLE IF NOT EXISTS karma_events (
  id            TEXT PRIMARY KEY,
  user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount        INTEGER NOT NULL,
  reason        TEXT NOT NULL,
  from_user_id  TEXT,
  ref_id        TEXT,
  created_at    TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

CREATE INDEX IF NOT EXISTS idx_karma_user ON karma_events(user_id, created_at);
