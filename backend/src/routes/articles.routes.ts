/** Módulo A — Biblioteca Digital (RF-01, RF-02) + artículos de la comunidad (RF-10, RF-13). */
import { Router } from 'express';
import { getDb, newId, transaction } from '../db/database.js';
import { addRole, applyVote, ensureUser, myVotes, userName } from '../services/karma.service.js';
import { currentUserId, HttpError, optionalString, requireString, sortParam } from '../utils/http.js';
import { createFeedPost } from './community.routes.js';
import { findChallenge } from './challenges.routes.js';
import type { Article, ContentSource } from '../types/models.js';

interface ArticleRow {
  id: string;
  title: string;
  pioneer_name: string;
  era: string;
  summary: string;
  content: string;
  related_challenge_id: string | null;
  source: ContentSource;
  author_id: string | null;
  upvotes: number;
  downvotes: number;
  created_at: string;
}

const toArticle = (r: ArticleRow, myVote = 0): Article => ({
  id: r.id,
  title: r.title,
  pioneerName: r.pioneer_name,
  era: r.era,
  summary: r.summary,
  content: r.content,
  relatedChallengeId: r.related_challenge_id ?? '',
  source: r.source,
  authorId: r.author_id ?? undefined,
  authorName: userName(r.author_id),
  upvotes: r.upvotes,
  downvotes: r.downvotes,
  createdAt: r.created_at,
  myVote,
});

const getRow = (id: string) => getDb().prepare('SELECT * FROM articles WHERE id = ?').get(id) as ArticleRow | undefined;

export function findArticle(id: string): Article | null {
  const row = getRow(id);
  return row ? toArticle(row) : null;
}

export const articlesRouter = Router();

/** GET /api/articles?source=official|community&sort=top|new&authorId= */
articlesRouter.get('/', (req, res) => {
  const where: string[] = [];
  const params: string[] = [];
  if (req.query.source === 'official' || req.query.source === 'community') {
    where.push('source = ?');
    params.push(req.query.source);
  }
  if (typeof req.query.authorId === 'string') {
    where.push('author_id = ?');
    params.push(req.query.authorId);
  }
  // Oficial: orden editorial. Comunidad: lo mejor votado arriba (o lo más reciente).
  const order =
    sortParam(req) === 'new'
      ? 'created_at DESC'
      : "CASE source WHEN 'official' THEN 0 ELSE 1 END, CASE source WHEN 'official' THEN sort_order ELSE -(upvotes - downvotes) END, created_at DESC";
  const rows = getDb()
    .prepare(`SELECT * FROM articles ${where.length ? 'WHERE ' + where.join(' AND ') : ''} ORDER BY ${order}`)
    .all(...params) as unknown as ArticleRow[];
  const votes = myVotes(currentUserId(req), 'article', rows.map((r) => r.id));
  res.json(rows.map((r) => toArticle(r, votes.get(r.id) ?? 0)));
});

/** POST /api/articles { title, summary, content, pioneerName?, era?, relatedChallengeId? } — RF-10 */
articlesRouter.post('/', (req, res) => {
  const body = (req.body ?? {}) as Record<string, unknown>;
  const user = ensureUser(currentUserId(req));
  const title = requireString(body, 'title', 200);
  const summary = requireString(body, 'summary', 500);
  const content = requireString(body, 'content', 30_000);
  const pioneerName = optionalString(body, 'pioneerName', 120);
  const era = optionalString(body, 'era', 60);
  const relatedChallengeId = optionalString(body, 'relatedChallengeId', 100) || null;
  if (relatedChallengeId && !findChallenge(relatedChallengeId)) {
    throw new HttpError(400, `Reto "${relatedChallengeId}" no existe.`);
  }

  const id = newId('art');
  transaction(() => {
    getDb()
      .prepare(
        `INSERT INTO articles (id, title, pioneer_name, era, summary, content, related_challenge_id, sort_order,
                               source, author_id, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, 1000, 'community', ?, ?)`,
      )
      .run(id, title, pioneerName, era, summary, content, relatedChallengeId, user.id, new Date().toISOString());
    addRole(user.id, 'creator');
    createFeedPost({
      authorId: user.id,
      type: 'article',
      title: `Nuevo artículo: ${title}`,
      body: summary,
      refId: id,
    });
  });
  res.status(201).json(findArticle(id));
});

articlesRouter.get('/:id', (req, res) => {
  const row = getRow(req.params.id);
  if (!row) throw new HttpError(404, 'Artículo no encontrado.');
  const vote = myVotes(currentUserId(req), 'article', [row.id]).get(row.id) ?? 0;
  res.json(toArticle(row, vote));
});

/** POST /api/articles/:id/vote { value: 1 | -1 | 0 } — el contenido oficial no admite votos negativos. */
articlesRouter.post('/:id/vote', (req, res) => {
  const row = getRow(req.params.id);
  if (!row) throw new HttpError(404, 'Artículo no encontrado.');
  const requested = Number((req.body as Record<string, unknown>)?.value) || 0;
  if (row.source === 'official' && requested < 0) {
    throw new HttpError(400, 'El contenido oficial no admite votos negativos.');
  }
  const userId = currentUserId(req);
  ensureUser(userId);
  const value = transaction(() =>
    applyVote({
      userId,
      targetType: 'article',
      targetId: row.id,
      table: 'articles',
      authorId: row.author_id,
      value: requested,
    }),
  );
  res.json(toArticle(getRow(row.id)!, value));
});

/** RF-02 "Pon en práctica su legado": devuelve el reto vinculado al artículo. */
articlesRouter.get('/:id/challenge', (req, res) => {
  const row = getRow(req.params.id);
  if (!row) throw new HttpError(404, 'Artículo no encontrado.');
  const challenge = row.related_challenge_id ? findChallenge(row.related_challenge_id) : null;
  if (!challenge) throw new HttpError(404, 'Este artículo no tiene un reto vinculado.');
  res.json(challenge);
});
