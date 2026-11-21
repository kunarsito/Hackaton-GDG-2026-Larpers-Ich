import { DatabaseSync } from 'node:sqlite';
import { readFileSync, mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));

let db: DatabaseSync | null = null;

/** Conexión única (SQLite nativo de Node >= 22.13, sin dependencias compiladas). */
export function getDb(): DatabaseSync {
  if (db) return db;

  const dbPath = process.env.DB_PATH ?? './data/faro.db';
  if (dbPath !== ':memory:') {
    mkdirSync(dirname(resolve(dbPath)), { recursive: true });
  }

  db = new DatabaseSync(dbPath);
  db.exec(readFileSync(resolve(here, 'schema.sql'), 'utf8'));
  migrate(db);
  return db;
}

/**
 * Columnas nuevas de la red social (SRS v2) sobre tablas existentes.
 * SQLite no permite defaults no constantes en ALTER TABLE, por eso created_at
 * se agrega vacío y luego se rellena.
 */
const NEW_COLUMNS: Record<string, [string, string][]> = {
  users: [
    ['bio', "TEXT NOT NULL DEFAULT ''"],
    ['avatar_url', 'TEXT'],
    ['links', "TEXT NOT NULL DEFAULT '{}'"],
    ['skills', "TEXT NOT NULL DEFAULT '[]'"],
    ['open_to_work', 'INTEGER NOT NULL DEFAULT 0'],
    ['cv_url', 'TEXT'],
    ['roles', 'TEXT NOT NULL DEFAULT \'["student"]\''],
  ],
  articles: [
    ['source', "TEXT NOT NULL DEFAULT 'official'"],
    ['author_id', 'TEXT'],
    ['upvotes', 'INTEGER NOT NULL DEFAULT 0'],
    ['downvotes', 'INTEGER NOT NULL DEFAULT 0'],
    ['created_at', "TEXT NOT NULL DEFAULT ''"],
  ],
  challenges: [
    ['source', "TEXT NOT NULL DEFAULT 'official'"],
    ['author_id', 'TEXT'],
    ['upvotes', 'INTEGER NOT NULL DEFAULT 0'],
    ['downvotes', 'INTEGER NOT NULL DEFAULT 0'],
    ['forked_from_id', 'TEXT'],
    ['created_at', "TEXT NOT NULL DEFAULT ''"],
  ],
  forum_posts: [
    ['type', "TEXT NOT NULL DEFAULT 'post'"],
    ['downvotes', 'INTEGER NOT NULL DEFAULT 0'],
    ['attachments', "TEXT NOT NULL DEFAULT '[]'"],
    ['forked_from_id', 'TEXT'],
    ['accepted_reply_id', 'TEXT'],
    ['ref_id', 'TEXT'],
  ],
  jobs: [['poster_id', 'TEXT']],
};

function migrate(conn: DatabaseSync): void {
  for (const [table, columns] of Object.entries(NEW_COLUMNS)) {
    const existing = new Set(
      (conn.prepare(`PRAGMA table_info(${table})`).all() as { name: string }[]).map((c) => c.name),
    );
    for (const [name, def] of columns) {
      if (!existing.has(name)) conn.exec(`ALTER TABLE ${table} ADD COLUMN ${name} ${def}`);
    }
  }
  const now = new Date().toISOString();
  conn.prepare("UPDATE articles SET created_at = ? WHERE created_at = ''").run(now);
  conn.prepare("UPDATE challenges SET created_at = ? WHERE created_at = ''").run(now);
}

/** Ejecuta `fn` dentro de una transacción. */
export function transaction<T>(fn: () => T): T {
  const conn = getDb();
  conn.exec('BEGIN');
  try {
    const result = fn();
    conn.exec('COMMIT');
    return result;
  } catch (err) {
    conn.exec('ROLLBACK');
    throw err;
  }
}

export function newId(prefix: string): string {
  return `${prefix}-${Date.now().toString(36)}${Math.random().toString(36).slice(2, 6)}`;
}
