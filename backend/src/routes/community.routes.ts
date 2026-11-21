/**
 * Módulo C — Comunidad (Facebook + GitHub): foro/feed (RF-05, RF-06, RF-11),
 * adjuntos (RF-12), ranking Top/Recientes (RF-13) y Karma (RF-14).
 * Se monta en /api/community (compatibilidad), /api/posts y /api/feed.
 */
import { Router, type Request, type Response } from 'express';
import { getDb, newId, transaction } from '../db/database.js';
import { addKarma, applyVote, ensureUser, getUser, KARMA, myVotes, parseJson } from '../services/karma.service.js';
import { currentUserId, HttpError, optionalString, requireString, sortParam } from '../utils/http.js';
import { relativeTime } from '../utils/time.js';
import { findChallenge } from './challenges.routes.js';
import { resolveAttachments } from './uploads.routes.js';
import type { Attachment, ForumPost, ForumReply, PostType } from '../types/models.js';

const POST_TYPES: PostType[] = ['post', 'question', 'challenge', 'course', 'snippet', 'article'];

interface PostRow {
  id: string;
  author_id: string;
  author_name: string;
  title: string;
  body: string;
  code_snippet: string;
  challenge_id: string | null;
  upvotes: number;
  downvotes: number;
  created_at: string;
  type: PostType;
  attachments: string;
  forked_from_id: string | null;
  accepted_reply_id: string | null;
  ref_id: string | null;
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

function savedInfo(postIds: string[], viewerId: string): { counts: Map<string, number>; mine: Set<string> } {
  const counts = new Map<string, number>();
  const mine = new Set<string>();
  if (!postIds.length) return { counts, mine };
  const marks = postIds.map(() => '?').join(',');
  const db = getDb();
  for (const r of db
    .prepare(`SELECT post_id, COUNT(*) AS n FROM saved_posts WHERE post_id IN (${marks}) GROUP BY post_id`)
    .all(...postIds) as { post_id: string; n: number }[]) {
    counts.set(r.post_id, r.n);
  }
  for (const r of db
    .prepare(`SELECT post_id FROM saved_posts WHERE user_id = ? AND post_id IN (${marks})`)
    .all(viewerId, ...postIds) as { post_id: string }[]) {
    mine.add(r.post_id);
  }
  return { counts, mine };
}

/** Filas -> ForumPost con respuestas, guardados y voto del usuario que mira. */
function hydrate(rows: PostRow[], viewerId: string): ForumPost[] {
  const ids = rows.map((r) => r.id);
  const replies = loadReplies(ids);
  const votes = myVotes(viewerId, 'post', ids);
  const saved = savedInfo(ids, viewerId);
  return rows.map((r) => ({
    id: r.id,
    authorId: r.author_id,
    authorName: r.author_name,
    title: r.title,
    body: r.body,
    codeSnippet: r.code_snippet,
    challengeId: r.challenge_id,
    replies: replies.get(r.id) ?? [],
    upvotes: r.upvotes,
    createdAt: relativeTime(r.created_at),
    type: r.type,
    downvotes: r.downvotes,
    attachments: parseJson<Attachment[]>(r.attachments, []),
    savedCount: saved.counts.get(r.id) ?? 0,
    forkedFromId: r.forked_from_id ?? undefined,
    acceptedReplyId: r.accepted_reply_id ?? undefined,
    refId: r.ref_id ?? undefined,
    myVote: votes.get(r.id) ?? 0,
    isSaved: saved.mine.has(r.id),
  }));
}

const getRow = (id: string) => getDb().prepare('SELECT * FROM forum_posts WHERE id = ?').get(id) as PostRow | undefined;

function getPost(id: string, viewerId: string): ForumPost | null {
  const row = getRow(id);
  return row ? hydrate([row], viewerId)[0] : null;
}

/**
 * Publica en el feed el anuncio de un reto/curso/artículo nuevo (RF-10, RF-11).
 * Debe llamarse dentro de una transacción.
 */
export function createFeedPost(opts: {
  authorId: string;
  type: PostType;
  title: string;
  body: string;
  refId: string;
  challengeId?: string;
}): string {
  const author = getUser(opts.authorId);
  const id = newId('post');
  getDb()
    .prepare(
      `INSERT INTO forum_posts (id, author_id, author_name, title, body, code_snippet, challenge_id, upvotes, type, ref_id)
       VALUES (?, ?, ?, ?, ?, '', ?, 0, ?, ?)`,
    )
    .run(id, opts.authorId, author?.name ?? 'Estudiante Dev', opts.title.slice(0, 200), opts.body, opts.challengeId ?? null, opts.type, opts.refId);
  return id;
}

/** GET /api/community (= /api/feed) ?sort=top|new&challengeId=&q=&authorId=&type=&saved=me */
function listPosts(req: Request, res: Response): void {
  const viewerId = currentUserId(req);
  const where: string[] = [];
  const params: string[] = [];
  if (typeof req.query.challengeId === 'string') {
    where.push('p.challenge_id = ?');
    params.push(req.query.challengeId);
  }
  if (typeof req.query.authorId === 'string') {
    where.push('p.author_id = ?');
    params.push(req.query.authorId);
  }
  if (typeof req.query.type === 'string' && POST_TYPES.includes(req.query.type as PostType)) {
    where.push('p.type = ?');
    params.push(req.query.type);
  }
  if (req.query.saved === 'me') {
    where.push('p.id IN (SELECT post_id FROM saved_posts WHERE user_id = ?)');
    params.push(viewerId);
  }
  if (typeof req.query.q === 'string' && req.query.q.trim()) {
    where.push('(p.title LIKE ? OR p.body LIKE ? OR p.code_snippet LIKE ?)');
    const q = `%${req.query.q.trim()}%`;
    params.push(q, q, q);
  }
  const order = sortParam(req) === 'new' ? 'p.created_at DESC' : '(p.upvotes - p.downvotes) DESC, p.created_at DESC';
  const rows = getDb()
    .prepare(`SELECT p.* FROM forum_posts p ${where.length ? 'WHERE ' + where.join(' AND ') : ''} ORDER BY ${order}`)
    .all(...params) as unknown as PostRow[];
  res.json(hydrate(rows, viewerId));
}

export const communityRouter = Router();

communityRouter.get('/', listPosts);

/** GET /api/feed — feed de Comunidad (mismo contrato que /api/community). */
export const feedRouter = Router();
feedRouter.get('/', listPosts);

communityRouter.get('/:id', (req, res) => {
  const post = getPost(req.params.id, currentUserId(req));
  if (!post) throw new HttpError(404, 'Publicación no encontrada.');
  res.json(post);
});

/**
 * POST /api/community — acepta el JSON de ForumPostModel.toJson() del front.
 * RF-05: si llega `challengeId` y no hay título/cuerpo, se precargan desde el reto.
 * RF-12: `attachments` = adjuntos subidos antes con /api/uploads (máx. 4).
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
  const requestedType = optionalString(body, 'type', 20) as PostType;
  // Los tipos challenge/course/article los crea el servidor al publicar ese contenido.
  const type: PostType = requestedType === 'question' || requestedType === 'snippet' ? requestedType : challengeId ? 'question' : 'post';
  const attachments = resolveAttachments(body.attachments, user.id);

  // Respeta el id generado por el cliente (post-<timestamp>) para que coincida con su caché local.
  const clientId = optionalString(body, 'id', 100);
  const exists = clientId && getRow(clientId);
  const id = clientId && !exists ? clientId : newId('post');

  transaction(() => {
    getDb()
      .prepare(
        `INSERT INTO forum_posts (id, author_id, author_name, title, body, code_snippet, challenge_id, upvotes, type, attachments)
         VALUES (?, ?, ?, ?, ?, ?, ?, 0, ?, ?)`,
      )
      .run(id, user.id, user.name, title, postBody, codeSnippet, challengeId, type, JSON.stringify(attachments));
    addKarma(user.id, KARMA.CREATE_POST, 'post_created', { refId: id });
  });

  res.status(201).json({ post: getPost(id, user.id), karmaAwarded: KARMA.CREATE_POST, user: getUser(user.id) });
});

/** POST /api/posts/:id/fork { title?, body?, codeSnippet? } — copia un snippet para mejorarlo (estilo GitHub). */
communityRouter.post('/:id/fork', (req, res) => {
  const original = getRow(req.params.id);
  if (!original) throw new HttpError(404, 'Publicación no encontrada.');
  const body = (req.body ?? {}) as Record<string, unknown>;
  const user = ensureUser(currentUserId(req));
  const code = optionalString(body, 'codeSnippet', 20_000) || original.code_snippet;
  if (!code) throw new HttpError(400, 'Sólo se pueden hacer fork de publicaciones con código.');
  const title = optionalString(body, 'title', 200) || `Fork de: ${original.title}`.slice(0, 200);
  const text = optionalString(body, 'body', 10_000) || `Mejora del código de @${original.author_name}.`;

  const id = newId('post');
  transaction(() => {
    getDb()
      .prepare(
        `INSERT INTO forum_posts (id, author_id, author_name, title, body, code_snippet, challenge_id, upvotes, type, forked_from_id)
         VALUES (?, ?, ?, ?, ?, ?, ?, 0, 'snippet', ?)`,
      )
      .run(id, user.id, user.name, title, text, code, original.challenge_id, original.id);
    addKarma(user.id, KARMA.CREATE_POST, 'post_created', { refId: id });
  });
  res.status(201).json({ post: getPost(id, user.id), user: getUser(user.id) });
});

/** POST /api/posts/:id/vote { value: 1 | -1 | 0 } — RF-11/RF-13; +2/−1 Karma al autor. */
communityRouter.post('/:id/vote', (req, res) => {
  const row = getRow(req.params.id);
  if (!row) throw new HttpError(404, 'Publicación no encontrada.');
  const userId = currentUserId(req);
  ensureUser(userId);
  transaction(() =>
    applyVote({
      userId,
      targetType: 'post',
      targetId: row.id,
      table: 'forum_posts',
      authorId: row.author_id,
      value: Number((req.body as Record<string, unknown>)?.value) || 0,
    }),
  );
  res.json(getPost(row.id, userId));
});

/** POST /api/community/:id/upvote — compatibilidad con el front anterior (= voto +1). */
communityRouter.post('/:id/upvote', (req, res) => {
  const row = getRow(req.params.id);
  if (!row) throw new HttpError(404, 'Publicación no encontrada.');
  const userId = currentUserId(req);
  ensureUser(userId);
  transaction(() =>
    applyVote({ userId, targetType: 'post', targetId: row.id, table: 'forum_posts', authorId: row.author_id, value: 1 }),
  );
  res.json(getPost(row.id, userId));
});

/** POST /api/posts/:id/save — guardar / quitar de guardados (estrella). */
communityRouter.post('/:id/save', (req, res) => {
  const row = getRow(req.params.id);
  if (!row) throw new HttpError(404, 'Publicación no encontrada.');
  const userId = currentUserId(req);
  ensureUser(userId);
  const db = getDb();
  const already = db.prepare('SELECT 1 FROM saved_posts WHERE user_id = ? AND post_id = ?').get(userId, row.id);
  if (already) db.prepare('DELETE FROM saved_posts WHERE user_id = ? AND post_id = ?').run(userId, row.id);
  else db.prepare('INSERT INTO saved_posts (user_id, post_id) VALUES (?, ?)').run(userId, row.id);
  res.json(getPost(row.id, userId));
});

/** POST /api/community/:id/replies — acepta ForumReply.toJson() (+ authorId opcional). */
communityRouter.post('/:id/replies', (req, res) => {
  const body = (req.body ?? {}) as Record<string, unknown>;
  const post = getRow(req.params.id);
  if (!post) throw new HttpError(404, 'Publicación no encontrada.');

  const text = requireString(body, 'body', 10_000);
  const user = ensureUser(currentUserId(req), optionalString(body, 'authorName', 80) || undefined);

  const clientId = optionalString(body, 'id', 100);
  const exists = clientId && getDb().prepare('SELECT 1 FROM forum_replies WHERE id = ?').get(clientId);
  const id = clientId && !exists ? clientId : newId('rep');

  getDb()
    .prepare('INSERT INTO forum_replies (id, post_id, author_id, author_name, body) VALUES (?, ?, ?, ?, ?)')
    .run(id, post.id, user.id, user.name, text);

  // RF-14: responder no da Karma por sí solo; da +15 si el autor la marca como solución.
  res.status(201).json({ post: getPost(post.id, user.id), karmaAwarded: 0, user: getUser(user.id) });
});

/** POST /api/posts/:id/replies/:replyId/accept — sólo el autor del hilo; +15 Karma a quien respondió. */
communityRouter.post('/:id/replies/:replyId/accept', (req, res) => {
  const post = getRow(req.params.id);
  if (!post) throw new HttpError(404, 'Publicación no encontrada.');
  const userId = currentUserId(req);
  if (post.author_id !== userId) throw new HttpError(403, 'Sólo el autor del hilo puede marcar la solución.');
  if (post.accepted_reply_id) throw new HttpError(409, 'Este hilo ya tiene una respuesta marcada como solución.');
  const reply = getDb()
    .prepare('SELECT * FROM forum_replies WHERE id = ? AND post_id = ?')
    .get(req.params.replyId, post.id) as ReplyRow | undefined;
  if (!reply) throw new HttpError(404, 'Respuesta no encontrada.');

  transaction(() => {
    getDb().prepare('UPDATE forum_posts SET accepted_reply_id = ? WHERE id = ?').run(reply.id, post.id);
    if (reply.author_id && reply.author_id !== userId) {
      addKarma(reply.author_id, KARMA.ACCEPTED_ANSWER, 'accepted_answer', { fromUserId: userId, refId: reply.id });
    }
  });
  res.json(getPost(post.id, userId));
});

/** POST /api/community/:id/replies/:replyId/upvote — votos a respuestas de ayuda (+2 al autor). */
communityRouter.post('/:id/replies/:replyId/upvote', (req, res) => {
  const reply = getDb()
    .prepare('SELECT * FROM forum_replies WHERE id = ? AND post_id = ?')
    .get(req.params.replyId, req.params.id) as ReplyRow | undefined;
  if (!reply) throw new HttpError(404, 'Respuesta no encontrada.');
  const voterId = currentUserId(req);
  ensureUser(voterId);
  transaction(() =>
    applyVote({
      userId: voterId,
      targetType: 'reply',
      targetId: reply.id,
      table: 'forum_replies',
      authorId: reply.author_id,
      value: 1,
    }),
  );
  res.json(getPost(req.params.id, voterId));
});
