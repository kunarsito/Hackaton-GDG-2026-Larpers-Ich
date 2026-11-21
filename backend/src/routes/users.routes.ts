/**
 * Perfiles estilo Instagram (RF-15), seguidores, ranking de usuarios/creadores
 * (RF-13) y búsqueda de talento para reclutadores (RF-17).
 */
import { Router } from 'express';
import { getDb } from '../db/database.js';
import { ensureUser, getUser } from '../services/karma.service.js';
import {
  currentUserId,
  HttpError,
  optionalStringArray,
  requireSessionUserId,
} from '../utils/http.js';
import { ownUploadUrl } from './uploads.routes.js';
import type { UserLinks } from '../types/models.js';

const BIO_MAX = 300;

export const usersRouter = Router();

/**
 * GET /api/users?sort=karma|new&role=creator|recruiter&q=&skill=&university=&openToWork=true&limit=20
 * Sirve para "Top Usuarios", "Top Creadores" y "Buscar talento".
 */
usersRouter.get('/', (req, res) => {
  const viewerId = currentUserId(req);
  const where: string[] = [];
  const params: string[] = [];
  const q = (name: string) => (typeof req.query[name] === 'string' ? (req.query[name] as string).trim() : '');

  if (q('role')) {
    where.push('roles LIKE ?');
    params.push(`%"${q('role')}"%`);
  }
  if (q('q')) {
    where.push('(name LIKE ? OR bio LIKE ?)');
    params.push(`%${q('q')}%`, `%${q('q')}%`);
  }
  if (q('skill')) {
    where.push('LOWER(skills) LIKE ?');
    params.push(`%"${q('skill').toLowerCase()}%`);
  }
  if (q('university')) {
    where.push('university LIKE ?');
    params.push(`%${q('university')}%`);
  }
  if (req.query.openToWork === 'true') where.push('open_to_work = 1');

  const limit = Math.min(50, Math.max(1, Number(req.query.limit) || 20));
  const order = req.query.sort === 'new' ? 'rowid DESC' : 'karma_points DESC, name';
  const rows = getDb()
    .prepare(`SELECT id FROM users ${where.length ? 'WHERE ' + where.join(' AND ') : ''} ORDER BY ${order} LIMIT ?`)
    .all(...params, limit) as { id: string }[];
  res.json(rows.map((r) => getUser(r.id, viewerId)));
});

/** GET /api/users/me — perfil completo de la sesión (o invitado). */
usersRouter.get('/me', (req, res) => {
  const id = currentUserId(req);
  res.json(getUser(id) ?? ensureUser(id));
});

/**
 * PATCH /api/users/me { name?, university?, bio?, links?, skills?, openToWork?, cvUrl?, avatarUrl? }
 * cvUrl/avatarUrl deben ser archivos subidos por el propio usuario (o "" para quitarlos).
 */
usersRouter.patch('/me', (req, res) => {
  const userId = requireSessionUserId(req);
  const body = (req.body ?? {}) as Record<string, unknown>;
  const sets: string[] = [];
  const params: (string | number | null)[] = [];
  const set = (col: string, value: string | number | null) => {
    sets.push(`${col} = ?`);
    params.push(value);
  };

  if (body.name !== undefined) {
    const name = typeof body.name === 'string' ? body.name.trim() : '';
    if (!name || name.length > 80) throw new HttpError(400, 'El nombre es obligatorio (máx. 80 caracteres).');
    set('name', name);
  }
  if (body.university !== undefined) {
    if (typeof body.university !== 'string' || body.university.length > 120) throw new HttpError(400, 'Universidad inválida.');
    set('university', body.university.trim());
  }
  if (body.bio !== undefined) {
    if (typeof body.bio !== 'string') throw new HttpError(400, '"bio" debe ser texto.');
    if (body.bio.trim().length > BIO_MAX) throw new HttpError(400, `La biografía admite ${BIO_MAX} caracteres.`);
    set('bio', body.bio.trim());
  }
  if (body.links !== undefined) {
    const raw = (body.links ?? {}) as Record<string, unknown>;
    const links: UserLinks = {};
    for (const key of ['github', 'linkedin', 'website'] as const) {
      const v = typeof raw[key] === 'string' ? (raw[key] as string).trim() : '';
      if (!v) continue;
      if (v.length > 200 || !/^https?:\/\//i.test(v)) throw new HttpError(400, `El enlace de ${key} debe empezar con http(s)://`);
      links[key] = v;
    }
    set('links', JSON.stringify(links));
  }
  if (body.skills !== undefined) set('skills', JSON.stringify(optionalStringArray(body, 'skills', 15, 30)));
  if (body.openToWork !== undefined) set('open_to_work', body.openToWork === true ? 1 : 0);
  if (body.cvUrl !== undefined) {
    const v = typeof body.cvUrl === 'string' ? body.cvUrl.trim() : '';
    set('cv_url', v ? ownUploadUrl(v, userId, 'pdf') : null);
  }
  if (body.avatarUrl !== undefined) {
    const v = typeof body.avatarUrl === 'string' ? body.avatarUrl.trim() : '';
    set('avatar_url', v ? ownUploadUrl(v, userId, 'image') : null);
  }

  if (sets.length) {
    getDb().prepare(`UPDATE users SET ${sets.join(', ')} WHERE id = ?`).run(...params, userId);
    // Mantiene el nombre visible en sus publicaciones
    if (body.name !== undefined) {
      getDb().prepare('UPDATE forum_posts SET author_name = (SELECT name FROM users WHERE id = ?) WHERE author_id = ?').run(userId, userId);
      getDb().prepare('UPDATE forum_replies SET author_name = (SELECT name FROM users WHERE id = ?) WHERE author_id = ?').run(userId, userId);
    }
  }
  res.json(getUser(userId));
});

usersRouter.get('/:id', (req, res) => {
  const user = getUser(req.params.id, currentUserId(req));
  if (!user) throw new HttpError(404, 'Usuario no encontrado.');
  res.json(user);
});

/** POST /api/users/:id/follow · DELETE /api/users/:id/follow */
usersRouter.post('/:id/follow', (req, res) => {
  const userId = currentUserId(req);
  ensureUser(userId);
  if (userId === req.params.id) throw new HttpError(400, 'No puedes seguirte a ti mismo.');
  if (!getUser(req.params.id)) throw new HttpError(404, 'Usuario no encontrado.');
  getDb().prepare('INSERT OR IGNORE INTO follows (follower_id, followee_id) VALUES (?, ?)').run(userId, req.params.id);
  res.json(getUser(req.params.id, userId));
});

usersRouter.delete('/:id/follow', (req, res) => {
  const userId = currentUserId(req);
  getDb().prepare('DELETE FROM follows WHERE follower_id = ? AND followee_id = ?').run(userId, req.params.id);
  const user = getUser(req.params.id, userId);
  if (!user) throw new HttpError(404, 'Usuario no encontrado.');
  res.json(user);
});

/** GET /api/users/:id/followers · /following -> UserSummary[] (para listas del perfil) */
for (const kind of ['followers', 'following'] as const) {
  usersRouter.get(`/:id/${kind}`, (req, res) => {
    const sql =
      kind === 'followers'
        ? 'SELECT follower_id AS id FROM follows WHERE followee_id = ? ORDER BY created_at DESC'
        : 'SELECT followee_id AS id FROM follows WHERE follower_id = ? ORDER BY created_at DESC';
    const rows = getDb().prepare(sql).all(req.params.id) as { id: string }[];
    const viewerId = currentUserId(req);
    res.json(rows.map((r) => getUser(r.id, viewerId)).filter(Boolean));
  });
}
