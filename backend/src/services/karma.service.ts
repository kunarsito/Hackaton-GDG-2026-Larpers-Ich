/**
 * Usuarios y Karma Técnico (RF-14 del SRS):
 *   +10 resolver un reto oficial · +5 un reto de comunidad (sólo la 1.ª vez)
 *   +10 publicar en el foro (Happy Path §6)
 *   +2 por upvote recibido · −1 por downvote (el Karma nunca baja de 0)
 *   +15 cuando tu respuesta se marca como solución
 *   +20 al creador cuando alguien completa su curso
 *   Regalos: hasta 5 puntos al día, tomados del saldo de quien regala
 */
import { getDb, newId } from '../db/database.js';
import type { KarmaReason, Role, User, UserLinks, UserSummary } from '../types/models.js';

export const KARMA = {
  SOLVE_OFFICIAL: 10,
  SOLVE_COMMUNITY: 5,
  CREATE_POST: 10,
  UPVOTE_RECEIVED: 2,
  DOWNVOTE_RECEIVED: -1,
  ACCEPTED_ANSWER: 15,
  COURSE_COMPLETED: 20,
  GIFT_DAILY_MAX: 5,
} as const;

export interface UserRow {
  id: string;
  name: string;
  university: string;
  karma_points: number;
  bio: string;
  avatar_url: string | null;
  links: string;
  skills: string;
  open_to_work: number;
  cv_url: string | null;
  roles: string;
}

export function parseJson<T>(raw: string | null | undefined, fallback: T): T {
  if (!raw) return fallback;
  try {
    return JSON.parse(raw) as T;
  } catch {
    return fallback;
  }
}

/** Usuario completo. `viewerId` calcula isFollowing (quién está mirando el perfil). */
export function getUser(id: string, viewerId?: string): User | null {
  const db = getDb();
  const row = db.prepare('SELECT * FROM users WHERE id = ?').get(id) as UserRow | undefined;
  if (!row) return null;
  const solved = db
    .prepare('SELECT challenge_id FROM solved_challenges WHERE user_id = ? ORDER BY solved_at')
    .all(id) as { challenge_id: string }[];
  const count = (sql: string, ...params: string[]) => (db.prepare(sql).get(...params) as { n: number }).n;

  const user: User = {
    id: row.id,
    name: row.name,
    university: row.university,
    karmaPoints: row.karma_points,
    solvedChallenges: solved.map((s) => s.challenge_id),
    roles: parseJson<Role[]>(row.roles, ['student']),
    avatarUrl: row.avatar_url ?? undefined,
    bio: row.bio ?? '',
    links: parseJson<UserLinks>(row.links, {}),
    skills: parseJson<string[]>(row.skills, []),
    followers: count('SELECT COUNT(*) AS n FROM follows WHERE followee_id = ?', id),
    following: count('SELECT COUNT(*) AS n FROM follows WHERE follower_id = ?', id),
    openToWork: row.open_to_work === 1,
    cvUrl: row.cv_url ?? undefined,
  };
  if (viewerId && viewerId !== id) {
    user.isFollowing = Boolean(
      db.prepare('SELECT 1 FROM follows WHERE follower_id = ? AND followee_id = ?').get(viewerId, id),
    );
  }
  return user;
}

export function userSummary(id: string): UserSummary | null {
  const row = getDb()
    .prepare('SELECT id, name, university, avatar_url, karma_points FROM users WHERE id = ?')
    .get(id) as Pick<UserRow, 'id' | 'name' | 'university' | 'avatar_url' | 'karma_points'> | undefined;
  return row
    ? {
        id: row.id,
        name: row.name,
        university: row.university,
        avatarUrl: row.avatar_url ?? undefined,
        karmaPoints: row.karma_points,
      }
    : null;
}

export function userName(id: string | null | undefined): string | undefined {
  if (!id) return undefined;
  const row = getDb().prepare('SELECT name FROM users WHERE id = ?').get(id) as { name: string } | undefined;
  return row?.name;
}

/** Crea el usuario si no existe (modo invitado / demo). */
export function ensureUser(id: string, name = 'Estudiante Dev', university = ''): User {
  getDb()
    .prepare('INSERT OR IGNORE INTO users (id, name, university, karma_points) VALUES (?, ?, ?, 0)')
    .run(id, name, university);
  return getUser(id)!;
}

/** Suma (o resta) Karma sin bajar de 0 y deja el movimiento en karma_events. */
export function addKarma(
  userId: string,
  amount: number,
  reason: KarmaReason,
  opts: { fromUserId?: string; refId?: string } = {},
): void {
  if (!amount) return;
  const db = getDb();
  db.prepare('UPDATE users SET karma_points = MAX(0, karma_points + ?) WHERE id = ?').run(amount, userId);
  db.prepare(
    'INSERT INTO karma_events (id, user_id, amount, reason, from_user_id, ref_id) VALUES (?, ?, ?, ?, ?, ?)',
  ).run(newId('kev'), userId, amount, reason, opts.fromUserId ?? null, opts.refId ?? null);
}

/** RF-18: agrega un rol (creator al publicar contenido, recruiter al publicar vacantes). */
export function addRole(userId: string, role: Role): void {
  const db = getDb();
  const row = db.prepare('SELECT roles FROM users WHERE id = ?').get(userId) as { roles: string } | undefined;
  if (!row) return;
  const roles = parseJson<Role[]>(row.roles, ['student']);
  if (roles.includes(role)) return;
  roles.push(role);
  db.prepare('UPDATE users SET roles = ? WHERE id = ?').run(JSON.stringify(roles), userId);
}

/**
 * Marca el reto como resuelto. La 1.ª vez suma +10 (oficial) o +5 (comunidad).
 * Devuelve los puntos otorgados (0 si ya estaba resuelto).
 */
export function markChallengeSolved(userId: string, challengeId: string, source: 'official' | 'community'): number {
  const result = getDb()
    .prepare('INSERT OR IGNORE INTO solved_challenges (user_id, challenge_id) VALUES (?, ?)')
    .run(userId, challengeId);
  if (Number(result.changes) === 0) return 0;
  const amount = source === 'official' ? KARMA.SOLVE_OFFICIAL : KARMA.SOLVE_COMMUNITY;
  addKarma(userId, amount, source === 'official' ? 'challenge_official' : 'challenge_community', {
    refId: challengeId,
  });
  return amount;
}

export function leaderboard(limit = 10): UserSummary[] {
  const rows = getDb()
    .prepare('SELECT id FROM users ORDER BY karma_points DESC LIMIT ?')
    .all(limit) as { id: string }[];
  return rows.map((r) => userSummary(r.id)!);
}

/**
 * Votos (RF-11, RF-13): un voto por usuario y objetivo. value 1, -1 o 0 (quitar).
 * Ajusta los contadores de la tabla y el Karma del autor (+2 / −1).
 * Devuelve el voto final del usuario.
 */
export function applyVote(opts: {
  userId: string;
  targetType: 'post' | 'reply' | 'article' | 'challenge';
  targetId: string;
  table: 'forum_posts' | 'forum_replies' | 'articles' | 'challenges';
  authorId: string | null | undefined;
  value: number;
}): number {
  const db = getDb();
  const { userId, targetType, targetId, table, authorId } = opts;
  const value = opts.value > 0 ? 1 : opts.value < 0 ? -1 : 0;
  const prev =
    (db
      .prepare('SELECT value FROM votes WHERE user_id = ? AND target_type = ? AND target_id = ?')
      .get(userId, targetType, targetId) as { value: number } | undefined)?.value ?? 0;
  if (prev === value) return value;

  const hasDownvotes = table !== 'forum_replies';
  const counter = (v: number, delta: number) => {
    if (v === 1) db.prepare(`UPDATE ${table} SET upvotes = MAX(0, upvotes + ?) WHERE id = ?`).run(delta, targetId);
    if (v === -1 && hasDownvotes) {
      db.prepare(`UPDATE ${table} SET downvotes = MAX(0, downvotes + ?) WHERE id = ?`).run(delta, targetId);
    }
  };
  const karmaFor = (v: number) => (v === 1 ? KARMA.UPVOTE_RECEIVED : v === -1 ? KARMA.DOWNVOTE_RECEIVED : 0);

  counter(prev, -1);
  counter(value, +1);
  if (value === 0) {
    db.prepare('DELETE FROM votes WHERE user_id = ? AND target_type = ? AND target_id = ?').run(
      userId,
      targetType,
      targetId,
    );
  } else {
    db.prepare(
      `INSERT INTO votes (user_id, target_type, target_id, value) VALUES (?, ?, ?, ?)
       ON CONFLICT (user_id, target_type, target_id) DO UPDATE SET value = excluded.value`,
    ).run(userId, targetType, targetId, value);
  }

  if (authorId && authorId !== userId) {
    const delta = karmaFor(value) - karmaFor(prev);
    if (delta) addKarma(authorId, delta, delta > 0 ? 'upvote' : 'downvote', { fromUserId: userId, refId: targetId });
  }
  return value;
}

/** Voto actual de un usuario sobre varios objetivos del mismo tipo. */
export function myVotes(userId: string, targetType: string, ids: string[]): Map<string, number> {
  const map = new Map<string, number>();
  if (!ids.length) return map;
  const rows = getDb()
    .prepare(
      `SELECT target_id, value FROM votes WHERE user_id = ? AND target_type = ? AND target_id IN (${ids
        .map(() => '?')
        .join(',')})`,
    )
    .all(userId, targetType, ...ids) as { target_id: string; value: number }[];
  for (const r of rows) map.set(r.target_id, r.value);
  return map;
}
