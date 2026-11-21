/** Perfiles (modo invitado): historial de retos y Karma Técnico. */
import { Router } from 'express';
import { newId } from '../db/database.js';
import { ensureUser, getUser, leaderboard } from '../services/karma.service.js';
import { currentUserId, HttpError, optionalString, requireString } from '../utils/http.js';

export const userRouter = Router();

/** GET /api/user — usuario actual (x-user-id o usuario demo). */
userRouter.get('/', (req, res) => {
  const id = currentUserId(req);
  res.json(getUser(id) ?? ensureUser(id));
});

/** GET /api/user/leaderboard?limit=10 */
userRouter.get('/leaderboard', (req, res) => {
  const limit = Math.min(50, Math.max(1, Number(req.query.limit) || 10));
  res.json(leaderboard(limit));
});

userRouter.get('/:id', (req, res) => {
  const user = getUser(req.params.id);
  if (!user) throw new HttpError(404, 'Usuario no encontrado.');
  res.json(user);
});

/** POST /api/user { name, university? } — crea un perfil invitado y devuelve su id. */
userRouter.post('/', (req, res) => {
  const body = (req.body ?? {}) as Record<string, unknown>;
  const name = requireString(body, 'name', 80);
  const university = optionalString(body, 'university', 120);
  res.status(201).json(ensureUser(newId('usr'), name, university));
});
