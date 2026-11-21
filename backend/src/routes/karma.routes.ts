/** RF-14 Otorgar Karma: hasta 5 puntos al día, tomados del saldo propio. */
import { Router } from 'express';
import { getDb, transaction } from '../db/database.js';
import { addKarma, getUser, KARMA } from '../services/karma.service.js';
import { HttpError, optionalString, requireSessionUserId } from '../utils/http.js';
import type { KarmaEvent } from '../types/models.js';

export const karmaRouter = Router();

/** Puntos que el usuario ya regaló desde las 00:00 UTC de hoy. */
function giftedToday(userId: string): number {
  const since = new Date();
  since.setUTCHours(0, 0, 0, 0);
  const row = getDb()
    .prepare(
      "SELECT COALESCE(SUM(-amount), 0) AS n FROM karma_events WHERE user_id = ? AND reason = 'gift' AND amount < 0 AND created_at >= ?",
    )
    .get(userId, since.toISOString()) as { n: number };
  return row.n;
}

/** GET /api/karma/gift -> { giftedToday, remainingToday } */
karmaRouter.get('/gift', (req, res) => {
  const userId = requireSessionUserId(req);
  const gifted = giftedToday(userId);
  res.json({ giftedToday: gifted, remainingToday: Math.max(0, KARMA.GIFT_DAILY_MAX - gifted) });
});

/** POST /api/karma/gift { toUserId, amount } -> { user, recipient, remainingToday } */
karmaRouter.post('/gift', (req, res) => {
  const userId = requireSessionUserId(req);
  const body = (req.body ?? {}) as Record<string, unknown>;
  const toUserId = optionalString(body, 'toUserId', 100);
  const amount = Math.round(Number(body.amount));
  if (!toUserId) throw new HttpError(400, 'Falta "toUserId".');
  if (toUserId === userId) throw new HttpError(400, 'No puedes regalarte Karma a ti mismo.');
  if (!(amount >= 1 && amount <= KARMA.GIFT_DAILY_MAX)) {
    throw new HttpError(400, `Puedes regalar entre 1 y ${KARMA.GIFT_DAILY_MAX} puntos.`);
  }
  const giver = getUser(userId)!;
  if (!getUser(toUserId)) throw new HttpError(404, 'Usuario no encontrado.');
  const remaining = KARMA.GIFT_DAILY_MAX - giftedToday(userId);
  if (amount > remaining) throw new HttpError(400, `Hoy sólo puedes regalar ${Math.max(0, remaining)} punto(s) más.`);
  if (giver.karmaPoints < amount) throw new HttpError(400, 'No tienes suficiente Karma para regalar esa cantidad.');

  transaction(() => {
    addKarma(userId, -amount, 'gift', { fromUserId: toUserId });
    addKarma(toUserId, amount, 'gift', { fromUserId: userId });
  });
  res.json({ user: getUser(userId), recipient: getUser(toUserId, userId), remainingToday: remaining - amount });
});

/** GET /api/karma/events — historial de Karma del usuario de la sesión. */
karmaRouter.get('/events', (req, res) => {
  const userId = requireSessionUserId(req);
  const rows = getDb()
    .prepare('SELECT * FROM karma_events WHERE user_id = ? ORDER BY created_at DESC LIMIT 50')
    .all(userId) as {
    id: string;
    user_id: string;
    amount: number;
    reason: KarmaEvent['reason'];
    from_user_id: string | null;
    created_at: string;
  }[];
  const events: KarmaEvent[] = rows.map((r) => ({
    id: r.id,
    userId: r.user_id,
    amount: r.amount,
    reason: r.reason,
    fromUserId: r.from_user_id ?? undefined,
    createdAt: r.created_at,
  }));
  res.json(events);
});
