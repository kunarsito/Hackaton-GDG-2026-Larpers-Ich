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
  return db;
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
