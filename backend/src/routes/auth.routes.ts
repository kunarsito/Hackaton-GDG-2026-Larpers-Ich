/** Login: registro, inicio/cierre de sesión y usuario actual. */
import { Router } from 'express';
import { deleteSession, login, register } from '../services/auth.service.js';
import { getUser } from '../services/karma.service.js';
import { bearerToken, HttpError, optionalString, requireString, sessionUserId } from '../utils/http.js';

export const authRouter = Router();

/** POST /api/auth/register { name, email, password, university? } -> { token, user } */
authRouter.post('/register', (req, res) => {
  const body = (req.body ?? {}) as Record<string, unknown>;
  const result = register({
    name: requireString(body, 'name', 80),
    email: requireString(body, 'email', 160),
    password: requireString(body, 'password', 200),
    university: optionalString(body, 'university', 120),
  });
  res.status(201).json(result);
});

/** POST /api/auth/login { email, password } -> { token, user } */
authRouter.post('/login', (req, res) => {
  const body = (req.body ?? {}) as Record<string, unknown>;
  res.json(login(requireString(body, 'email', 160), requireString(body, 'password', 200)));
});

/** POST /api/auth/logout (Authorization: Bearer <token>) */
authRouter.post('/logout', (req, res) => {
  const token = bearerToken(req);
  if (token) deleteSession(token);
  res.status(204).end();
});

/** GET /api/auth/me (Authorization: Bearer <token>) -> User */
authRouter.get('/me', (req, res) => {
  const userId = sessionUserId(req);
  if (!userId) throw new HttpError(401, 'Inicia sesión para continuar.');
  const user = getUser(userId);
  if (!user) throw new HttpError(401, 'Inicia sesión para continuar.');
  res.json(user);
});
