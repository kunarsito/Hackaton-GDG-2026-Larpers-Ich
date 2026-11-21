/**
 * RF-16 Mensajes privados 1 a 1 (contratación o contacto personal).
 * Sin WebSockets: el cliente consulta cada 5 s (polling). Requiere sesión.
 */
import { Router } from 'express';
import { getDb, newId, transaction } from '../db/database.js';
import { getUser, parseJson, userSummary } from '../services/karma.service.js';
import { HttpError, optionalString, requireSessionUserId } from '../utils/http.js';
import { resolveAttachments } from './uploads.routes.js';
import type { Attachment, Conversation, Message } from '../types/models.js';

interface ConversationRow {
  id: string;
  user_a: string;
  user_b: string;
  last_message_at: string;
}

interface MessageRow {
  id: string;
  conversation_id: string;
  sender_id: string;
  body: string;
  attachments: string;
  created_at: string;
  read_at: string | null;
}

const toMessage = (r: MessageRow): Message => ({
  id: r.id,
  conversationId: r.conversation_id,
  senderId: r.sender_id,
  body: r.body,
  attachments: parseJson<Attachment[]>(r.attachments, []),
  createdAt: r.created_at,
  readAt: r.read_at ?? undefined,
});

function toConversation(r: ConversationRow, viewerId: string): Conversation {
  const db = getDb();
  const otherId = r.user_a === viewerId ? r.user_b : r.user_a;
  const last = db
    .prepare('SELECT body, attachments FROM messages WHERE conversation_id = ? ORDER BY created_at DESC LIMIT 1')
    .get(r.id) as { body: string; attachments: string } | undefined;
  const unread = db
    .prepare('SELECT COUNT(*) AS n FROM messages WHERE conversation_id = ? AND sender_id != ? AND read_at IS NULL')
    .get(r.id, viewerId) as { n: number };
  const attachmentsCount = parseJson<Attachment[]>(last?.attachments, []).length;
  return {
    id: r.id,
    participantIds: [r.user_a, r.user_b],
    lastMessageAt: r.last_message_at,
    unreadCount: unread.n,
    otherUser: userSummary(otherId) ?? { id: otherId, name: 'Usuario', university: '', karmaPoints: 0 },
    lastMessage: last ? last.body || (attachmentsCount ? `📎 ${attachmentsCount} archivo(s)` : '') : undefined,
  };
}

function requireParticipant(conversationId: string, userId: string): ConversationRow {
  const row = getDb().prepare('SELECT * FROM conversations WHERE id = ?').get(conversationId) as
    | ConversationRow
    | undefined;
  if (!row || (row.user_a !== userId && row.user_b !== userId)) throw new HttpError(404, 'Conversación no encontrada.');
  return row;
}

/** Busca o crea la conversación entre dos usuarios. */
export function getOrCreateConversation(userId: string, otherId: string): ConversationRow {
  const [a, b] = userId < otherId ? [userId, otherId] : [otherId, userId];
  const db = getDb();
  db.prepare('INSERT OR IGNORE INTO conversations (id, user_a, user_b) VALUES (?, ?, ?)').run(newId('conv'), a, b);
  return db.prepare('SELECT * FROM conversations WHERE user_a = ? AND user_b = ?').get(a, b) as unknown as ConversationRow;
}

/** Envía un mensaje (también lo usa la postulación a vacantes). */
export function sendMessage(conversationId: string, senderId: string, body: string, attachments: Attachment[]): Message {
  const id = newId('msg');
  const now = new Date().toISOString();
  transaction(() => {
    getDb()
      .prepare('INSERT INTO messages (id, conversation_id, sender_id, body, attachments, created_at) VALUES (?, ?, ?, ?, ?, ?)')
      .run(id, conversationId, senderId, body, JSON.stringify(attachments), now);
    getDb().prepare('UPDATE conversations SET last_message_at = ? WHERE id = ?').run(now, conversationId);
  });
  return toMessage(getDb().prepare('SELECT * FROM messages WHERE id = ?').get(id) as unknown as MessageRow);
}

export const messagesRouter = Router();

/** GET /api/conversations — bandeja, la más reciente arriba. */
messagesRouter.get('/', (req, res) => {
  const userId = requireSessionUserId(req);
  const rows = getDb()
    .prepare('SELECT * FROM conversations WHERE user_a = ? OR user_b = ? ORDER BY last_message_at DESC')
    .all(userId, userId) as unknown as ConversationRow[];
  res.json(rows.map((r) => toConversation(r, userId)));
});

/** GET /api/conversations/unread -> { count } (insignia de no leídos) */
messagesRouter.get('/unread', (req, res) => {
  const userId = requireSessionUserId(req);
  const row = getDb()
    .prepare(
      `SELECT COUNT(*) AS n FROM messages m JOIN conversations c ON c.id = m.conversation_id
       WHERE (c.user_a = ? OR c.user_b = ?) AND m.sender_id != ? AND m.read_at IS NULL`,
    )
    .get(userId, userId, userId) as { n: number };
  res.json({ count: row.n });
});

/** POST /api/conversations { userId } -> Conversation (la crea si no existe). */
messagesRouter.post('/', (req, res) => {
  const userId = requireSessionUserId(req);
  const otherId = optionalString((req.body ?? {}) as Record<string, unknown>, 'userId', 100);
  if (!otherId) throw new HttpError(400, 'Falta "userId".');
  if (otherId === userId) throw new HttpError(400, 'No puedes escribirte a ti mismo.');
  if (!getUser(otherId)) throw new HttpError(404, 'Usuario no encontrado.');
  res.json(toConversation(getOrCreateConversation(userId, otherId), userId));
});

/** GET /api/conversations/:id/messages?after=<ISO> — marca como leídos los recibidos. */
messagesRouter.get('/:id/messages', (req, res) => {
  const userId = requireSessionUserId(req);
  const conv = requireParticipant(req.params.id, userId);
  const after = typeof req.query.after === 'string' ? req.query.after : '';
  const db = getDb();
  db.prepare('UPDATE messages SET read_at = ? WHERE conversation_id = ? AND sender_id != ? AND read_at IS NULL').run(
    new Date().toISOString(),
    conv.id,
    userId,
  );
  const rows = (
    after
      ? db.prepare('SELECT * FROM messages WHERE conversation_id = ? AND created_at > ? ORDER BY created_at').all(conv.id, after)
      : db
          .prepare('SELECT * FROM (SELECT * FROM messages WHERE conversation_id = ? ORDER BY created_at DESC LIMIT 200) ORDER BY created_at')
          .all(conv.id)
  ) as unknown as MessageRow[];
  res.json(rows.map(toMessage));
});

/** POST /api/conversations/:id/messages { body, attachments? } */
messagesRouter.post('/:id/messages', (req, res) => {
  const userId = requireSessionUserId(req);
  const conv = requireParticipant(req.params.id, userId);
  const body = (req.body ?? {}) as Record<string, unknown>;
  const text = optionalString(body, 'body', 5_000);
  const attachments = resolveAttachments(body.attachments, userId);
  if (!text && !attachments.length) throw new HttpError(400, 'El mensaje está vacío.');
  res.status(201).json(sendMessage(conv.id, userId, text, attachments));
});
