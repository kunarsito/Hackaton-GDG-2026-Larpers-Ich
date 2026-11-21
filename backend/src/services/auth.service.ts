/**
 * Login con correo + contraseña.
 *   - Contraseñas con scrypt + sal aleatoria (node:crypto, sin dependencias).
 *   - Sesiones con token aleatorio; en la BD sólo se guarda su SHA-256.
 */
import { createHash, randomBytes, scryptSync, timingSafeEqual } from 'node:crypto';
import { getDb, newId, transaction } from '../db/database.js';
import { ensureUser, getUser } from './karma.service.js';
import { HttpError } from '../utils/http.js';
import type { User } from '../types/models.js';

const SESSION_DAYS = 30;
const KEY_LEN = 64;
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/** Cuentas de prueba para los usuarios semilla (contraseña: DEMO_PASSWORD o "faro1234"). */
export const demoAccounts: { userId: string; email: string }[] = [
  { userId: 'usr-001', email: 'ada@faro.dev' },
  { userId: 'usr-002', email: 'carlos@faro.dev' },
  { userId: 'usr-003', email: 'valeria@faro.dev' },
  { userId: 'usr-004', email: 'mateo@faro.dev' },
  { userId: 'usr-005', email: 'grace@faro.dev' },
  { userId: 'usr-006', email: 'linus@faro.dev' },
];

export function hashPassword(password: string): string {
  const salt = randomBytes(16);
  const hash = scryptSync(password, salt, KEY_LEN);
  return `scrypt$${salt.toString('hex')}$${hash.toString('hex')}`;
}

export function verifyPassword(password: string, stored: string): boolean {
  const [algo, saltHex, hashHex] = stored.split('$');
  if (algo !== 'scrypt' || !saltHex || !hashHex) return false;
  const expected = Buffer.from(hashHex, 'hex');
  const actual = scryptSync(password, Buffer.from(saltHex, 'hex'), expected.length);
  return timingSafeEqual(actual, expected);
}

const sha256 = (s: string) => createHash('sha256').update(s).digest('hex');

export function createSession(userId: string): string {
  const token = randomBytes(32).toString('hex');
  const expires = new Date(Date.now() + SESSION_DAYS * 24 * 3_600_000).toISOString();
  getDb()
    .prepare('INSERT INTO sessions (token_hash, user_id, expires_at) VALUES (?, ?, ?)')
    .run(sha256(token), userId, expires);
  return token;
}

/** Devuelve el id del usuario del token, o null si no existe o expiró. */
export function userIdFromToken(token: string): string | null {
  const row = getDb()
    .prepare('SELECT user_id, expires_at FROM sessions WHERE token_hash = ?')
    .get(sha256(token)) as { user_id: string; expires_at: string } | undefined;
  if (!row) return null;
  if (row.expires_at < new Date().toISOString()) {
    deleteSession(token);
    return null;
  }
  return row.user_id;
}

export function deleteSession(token: string): void {
  getDb().prepare('DELETE FROM sessions WHERE token_hash = ?').run(sha256(token));
}

function validateCredentials(email: string, password: string): string {
  const normalized = email.trim().toLowerCase();
  if (!EMAIL_RE.test(normalized) || normalized.length > 160) throw new HttpError(400, 'Correo electrónico inválido.');
  if (password.length < 8) throw new HttpError(400, 'La contraseña debe tener al menos 8 caracteres.');
  if (password.length > 200) throw new HttpError(400, 'La contraseña es demasiado larga.');
  return normalized;
}

export function register(input: { name: string; email: string; password: string; university?: string }): {
  token: string;
  user: User;
} {
  const email = validateCredentials(input.email, input.password);
  const db = getDb();
  const taken = db.prepare('SELECT 1 FROM auth_credentials WHERE email = ?').get(email);
  if (taken) throw new HttpError(409, 'Ya existe una cuenta con ese correo.');

  const userId = newId('usr');
  return transaction(() => {
    ensureUser(userId, input.name, input.university ?? '');
    db.prepare('INSERT INTO auth_credentials (user_id, email, password_hash) VALUES (?, ?, ?)').run(
      userId,
      email,
      hashPassword(input.password),
    );
    return { token: createSession(userId), user: getUser(userId)! };
  });
}

export function login(emailInput: string, password: string): { token: string; user: User } {
  const email = emailInput.trim().toLowerCase();
  const row = getDb()
    .prepare('SELECT user_id, password_hash FROM auth_credentials WHERE email = ?')
    .get(email) as { user_id: string; password_hash: string } | undefined;
  // Mismo mensaje si el correo no existe o la contraseña falla (no revela cuentas).
  if (!row || !verifyPassword(password, row.password_hash)) {
    throw new HttpError(401, 'Correo o contraseña incorrectos.');
  }
  const user = getUser(row.user_id);
  if (!user) throw new HttpError(401, 'Correo o contraseña incorrectos.');
  return { token: createSession(row.user_id), user };
}

/** Da de alta las credenciales de prueba de los usuarios semilla que aún no tengan. */
export function ensureDemoCredentials(): void {
  const db = getDb();
  const password = process.env.DEMO_PASSWORD || 'faro1234';
  const userExists = db.prepare('SELECT 1 FROM users WHERE id = ?');
  const hasCreds = db.prepare('SELECT 1 FROM auth_credentials WHERE user_id = ? OR email = ?');
  const insert = db.prepare('INSERT INTO auth_credentials (user_id, email, password_hash) VALUES (?, ?, ?)');
  for (const acc of demoAccounts) {
    if (userExists.get(acc.userId) && !hasCreds.get(acc.userId, acc.email)) {
      insert.run(acc.userId, acc.email, hashPassword(password));
    }
  }
}
