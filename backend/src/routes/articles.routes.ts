/** Módulo A — Biblioteca Digital (RF-01, RF-02). */
import { Router } from 'express';
import { getDb } from '../db/database.js';
import { HttpError } from '../utils/http.js';
import { findChallenge } from './challenges.routes.js';
import type { Article } from '../types/models.js';

interface ArticleRow {
  id: string;
  title: string;
  pioneer_name: string;
  era: string;
  summary: string;
  content: string;
  related_challenge_id: string | null;
}

const toArticle = (r: ArticleRow): Article => ({
  id: r.id,
  title: r.title,
  pioneerName: r.pioneer_name,
  era: r.era,
  summary: r.summary,
  content: r.content,
  relatedChallengeId: r.related_challenge_id ?? '',
});

export const articlesRouter = Router();

articlesRouter.get('/', (_req, res) => {
  const rows = getDb().prepare('SELECT * FROM articles ORDER BY sort_order').all() as unknown as ArticleRow[];
  res.json(rows.map(toArticle));
});

articlesRouter.get('/:id', (req, res) => {
  const row = getDb().prepare('SELECT * FROM articles WHERE id = ?').get(req.params.id) as ArticleRow | undefined;
  if (!row) throw new HttpError(404, 'Artículo no encontrado.');
  res.json(toArticle(row));
});

/** RF-02 "Pon en práctica su legado": devuelve el reto vinculado al artículo. */
articlesRouter.get('/:id/challenge', (req, res) => {
  const row = getDb().prepare('SELECT * FROM articles WHERE id = ?').get(req.params.id) as ArticleRow | undefined;
  if (!row) throw new HttpError(404, 'Artículo no encontrado.');
  const challenge = row.related_challenge_id ? findChallenge(row.related_challenge_id) : null;
  if (!challenge) throw new HttpError(404, 'Este artículo no tiene un reto vinculado.');
  res.json(challenge);
});
