/** Módulo C — Foro técnico (RF-05, RF-06) y Karma Técnico (RF-07). */
import { Router } from 'express';
import { getDb, newId, transaction } from '../db/database.js';
import { addKarma, ensureUser, getUser, KARMA } from '../services/karma.service.js';
import { currentUserId, HttpError, optionalString, requireString } from '../utils/http.js';
import { relativeTime } from '../utils/time.js';
import { findChallenge } from './challenges.routes.js';
import type { ForumPost, ForumReply } from '../types/models.js';

interface PostRow {
  id: string;
  author_id: string;
  author_name: string;
  title: string;
  body: string;
  code_snippet: string;
  challenge_id: string | null;
  upvotes: number;
  created_at: string;
}

interface ReplyRow {
  id: string;
  post_id: string;
  author_id: string | null;
  author_name: string;
  body: string;
  upvotes: number;
  created_at: string;
}

const toReply = (r: ReplyRow): ForumReply => ({
  id: r.id,
  authorId: r.author_id ?? undefined,
  authorName: r.author_name,
  body: r.body,
  upvotes: r.upvotes,
  createdAt: relativeTime(r.created_at),
});

function loadReplies(postIds: string[]): Map<string, ForumReply[]> {
  const map = new Map<string, ForumReply[]>();
  if (!postIds.length) return map;
  const rows = getDb()
    .prepare(`SELECT * FROM forum_replies WHERE post_id IN (${postIds.map(() => '?').join(',')}) ORDER BY created_at`)
    .all(...postIds) as unknown as ReplyRow[];
  for (const r of rows) {
    if (!map.has(r.post_id)) map.set(r.post_id, []);
    map.get(r.post_id)!.push(toReply(r));
  }
  return map;
}

const toPost = (r: PostRow, replies: ForumReply[]): ForumPost => ({
  id: r.id,
  authorId: r.author_id,
  authorName: r.author_name,
  title: r.title,
  body: r.body,
  codeSnippet: r.code_snippet,
  challengeId: r.challenge_id,
  replies,
  upvotes: r.upvotes,
  createdAt: relativeTime(r.created_at),
});

function getPost(id: string): ForumPost | null {
  const row = getDb().prepare('SELECT * FROM forum_posts WHERE id = ?').get(id) as PostRow | undefined;
  return row ? toPost(row, loadReplies([id]).get(id) ?? []) : null;
}

export const communityRouter = Router();

/** GET /api/community?challengeId=ch-dijkstra-01&q=regex */
communityRouter.get('/', (req, res) => {
  const where: string[] = [];
  const params: string[] = [];
  if (typeof req.query.challengeId === 'string') {
    where.push('challenge_id = ?');
    params.push(req.query.challengeId);
  }
  if (typeof req.query.q === 'string' && req.query.q.trim()) {
    where.push('(title LIKE ? OR body LIKE ? OR code_snippet LIKE ?)');
    const q = `%${req.query.q.trim()}%`;
    params.push(q, q, q);
  }
  const rows = getDb()
    .prepare(`SELECT * FROM forum_posts ${where.length ? 'WHERE ' + where.join(' AND ') : ''} ORDER BY created_at DESC`)
    .all(...params) as unknown as PostRow[];
  const replies = loadReplies(rows.map((r) => r.id));
  res.json(rows.map((r) => toPost(r, replies.get(r.id) ?? [])));
});

communityRouter.get('/:id', (req, res) => {
  const post = getPost(req.params.id);
  if (!post) throw new HttpError(404, 'Publicación no encontrada.');
  res.json(post);
});

/**
 * POST /api/community — acepta el JSON de ForumPostModel.toJson() del front.
 * RF-05: si llega `challengeId` y no hay título/cuerpo, se precargan desde el reto.
 */
communityRouter.post('/', (req, res) => {
  const body = (req.body ?? {}) as Record<string, unknown>;
  const userId = currentUserId(req);
  const user = ensureUser(userId, optionalString(body, 'authorName', 80) || undefined);

  const challengeId = optionalString(body, 'challengeId', 100) || null;
  const challenge = challengeId ? findChallenge(challengeId) : null;
  if (challengeId && !challenge) throw new HttpError(400, `Reto "${challengeId}" no existe.`);

  const title = optionalString(body, 'title', 200) || (challenge ? `Ayuda con el reto: ${challenge.title}` : '');
  if (!title) throw new HttpError(400, 'El campo "title" es obligatorio.');
  const postBody =
    optionalString(body, 'body', 10_000) || (challenge ? `Enunciado:\n${challenge.description}` : '');
  const codeSnippet = optionalString(body, 'codeSnippet', 20_000);

  // Respeta el id generado por el cliente (post-<timestamp>) para que coincida con su caché local.
  const clientId = optionalString(body, 'id', 100);
  const exists = clientId && getDb().prepare('SELECT 1 FROM forum_posts WHERE id = ?').get(clientId);
  const id = clientId && !exists ? clientId : newId('post');
  const upvotes = Math.min(1, Math.max(0, Number(body.upvotes) || 0));

  transaction(() => {
    getDb()
      .prepare(
        `INSERT INTO forum_posts (id, author_id, author_name, title, body, code_snippet, challenge_id, upvotes)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      )
      .run(id, user.id, user.name, title, postBody, codeSnippet, challengeId, upvotes);
    addKarma(user.id, KARMA.CREATE_POST);
  });

  res.status(201).json({ post: getPost(id), karmaAwarded: KARMA.CREATE_POST, user: getUser(user.id) });
});

/** POST /api/community/:id/replies — acepta ForumReply.toJson() (+ authorId opcional). */
communityRouter.post('/:id/replies', (req, res) => {
  const body = (req.body ?? {}) as Record<string, unknown>;
  const post = getPost(req.params.id);
  if (!post) throw new HttpError(404, 'Publicación no encontrada.');

  const text = requireString(body, 'body', 10_000);
  const user = ensureUser(currentUserId(req), optionalString(body, 'authorName', 80) || undefined);

  const clientId = optionalString(body, 'id', 100);
  const exists = clientId && getDb().prepare('SELECT 1 FROM forum_replies WHERE id = ?').get(clientId);
  const id = clientId && !exists ? clientId : newId('rep');

  transaction(() => {
    getDb()
      .prepare('INSERT INTO forum_replies (id, post_id, author_id, author_name, body) VALUES (?, ?, ?, ?, ?)')
      .run(id, post.id, user.id, user.name, text);
    addKarma(user.id, KARMA.REPLY);
  });

  res.status(201).json({ post: getPost(post.id), karmaAwarded: KARMA.REPLY, user: getUser(user.id) });
});

/** POST /api/community/:id/upvote — +1 al post y +5 de karma a su autor (si no es auto-voto). */
communityRouter.post('/:id/upvote', (req, res) => {
  const post = getPost(req.params.id);
  if (!post) throw new HttpError(404, 'Publicación no encontrada.');
  const voterId = currentUserId(req);

  transaction(() => {
    getDb().prepare('UPDATE forum_posts SET upvotes = upvotes + 1 WHERE id = ?').run(post.id);
    if (voterId !== post.authorId) addKarma(post.authorId, KARMA.RECEIVE_UPVOTE);
  });

  res.json(getPost(post.id));
});

/** POST /api/community/:id/replies/:replyId/upvote — RF-07: votos a respuestas de ayuda. */
communityRouter.post('/:id/replies/:replyId/upvote', (req, res) => {
  const reply = getDb()
    .prepare('SELECT * FROM forum_replies WHERE id = ? AND post_id = ?')
    .get(req.params.replyId, req.params.id) as ReplyRow | undefined;
  if (!reply) throw new HttpError(404, 'Respuesta no encontrada.');
  const voterId = currentUserId(req);

  transaction(() => {
    getDb().prepare('UPDATE forum_replies SET upvotes = upvotes + 1 WHERE id = ?').run(reply.id);
    if (reply.author_id && voterId !== reply.author_id) addKarma(reply.author_id, KARMA.RECEIVE_UPVOTE);
  });

  res.json(getPost(req.params.id));
});
