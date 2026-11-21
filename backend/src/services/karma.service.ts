/**
 * RF-07 Karma Técnico. Valores alineados con el front (api_service.dart):
 *   +50 resolver un reto (sólo la primera vez)
 *   +10 publicar en el foro
 *   +15 responder a un compañero
 *   +5  al autor cuando recibe un voto positivo
 */
import { getDb } from '../db/database.js';
import type { User } from '../types/models.js';

export const KARMA = {
  SOLVE_CHALLENGE: 50,
  CREATE_POST: 10,
  REPLY: 15,
  RECEIVE_UPVOTE: 5,
} as const;

interface UserRow {
  id: string;
  name: string;
  university: string;
  karma_points: number;
}

export function getUser(id: string): User | null {
  const db = getDb();
  const row = db.prepare('SELECT * FROM users WHERE id = ?').get(id) as UserRow | undefined;
  if (!row) return null;
  const solved = db
    .prepare('SELECT challenge_id FROM solved_challenges WHERE user_id = ? ORDER BY solved_at')
    .all(id) as { challenge_id: string }[];
  return {
    id: row.id,
    name: row.name,
    university: row.university,
    karmaPoints: row.karma_points,
    solvedChallenges: solved.map((s) => s.challenge_id),
  };
}

/** Crea el usuario si no existe (modo invitado / demo). */
export function ensureUser(id: string, name = 'Estudiante Dev', university = ''): User {
  getDb()
    .prepare('INSERT OR IGNORE INTO users (id, name, university, karma_points) VALUES (?, ?, ?, 0)')
    .run(id, name, university);
  return getUser(id)!;
}

export function addKarma(userId: string, amount: number): void {
  getDb().prepare('UPDATE users SET karma_points = karma_points + ? WHERE id = ?').run(amount, userId);
}

/** Marca el reto como resuelto. Devuelve true si es la primera vez (y suma karma). */
export function markChallengeSolved(userId: string, challengeId: string): boolean {
  const result = getDb()
    .prepare('INSERT OR IGNORE INTO solved_challenges (user_id, challenge_id) VALUES (?, ?)')
    .run(userId, challengeId);
  const firstTime = Number(result.changes) > 0;
  if (firstTime) addKarma(userId, KARMA.SOLVE_CHALLENGE);
  return firstTime;
}

export function leaderboard(limit = 10): Pick<User, 'id' | 'name' | 'university' | 'karmaPoints'>[] {
  const rows = getDb()
    .prepare('SELECT id, name, university, karma_points FROM users ORDER BY karma_points DESC LIMIT ?')
    .all(limit) as unknown as UserRow[];
  return rows.map((r) => ({ id: r.id, name: r.name, university: r.university, karmaPoints: r.karma_points }));
}
