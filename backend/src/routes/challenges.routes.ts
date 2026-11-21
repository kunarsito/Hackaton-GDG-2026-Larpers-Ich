/** Módulo B — Zona de Práctica (RF-03, RF-04). */
import { Router } from 'express';
import { getDb } from '../db/database.js';
import { validateSolution } from '../services/code_validator.service.js';
import { ensureUser, getUser, markChallengeSolved, KARMA } from '../services/karma.service.js';
import { asyncHandler, currentUserId, HttpError, requireString } from '../utils/http.js';
import type { Challenge, ValidationResult } from '../types/models.js';

interface ChallengeRow {
  id: string;
  title: string;
  difficulty: Challenge['difficulty'];
  category: string;
  description: string;
  starter_code: string;
  function_name: string;
  test_cases: string;
}

const toChallenge = (r: ChallengeRow): Challenge => ({
  id: r.id,
  title: r.title,
  difficulty: r.difficulty,
  category: r.category,
  description: r.description,
  starterCode: r.starter_code,
  functionName: r.function_name,
  testCases: JSON.parse(r.test_cases),
});

export function findChallenge(id: string): Challenge | null {
  const row = getDb().prepare('SELECT * FROM challenges WHERE id = ?').get(id) as ChallengeRow | undefined;
  return row ? toChallenge(row) : null;
}

export const challengesRouter = Router();

/** GET /api/challenges?difficulty=Básico&category=Grafos */
challengesRouter.get('/', (req, res) => {
  const where: string[] = [];
  const params: string[] = [];
  if (typeof req.query.difficulty === 'string' && req.query.difficulty !== 'Todos') {
    where.push('difficulty = ?');
    params.push(req.query.difficulty);
  }
  if (typeof req.query.category === 'string') {
    where.push('category LIKE ?');
    params.push(`%${req.query.category}%`);
  }
  const sql = `SELECT * FROM challenges ${where.length ? 'WHERE ' + where.join(' AND ') : ''} ORDER BY sort_order`;
  const rows = getDb().prepare(sql).all(...params) as unknown as ChallengeRow[];
  res.json(rows.map(toChallenge));
});

/**
 * POST /api/challenges/validate  { challengeId, code, userId? }
 * Respuesta: { passed, message, executionTimeMs, testsPassed, totalTests, results[], engine, karmaAwarded, user }
 */
challengesRouter.post(
  '/validate',
  asyncHandler(async (req, res) => {
    const body = (req.body ?? {}) as Record<string, unknown>;
    const challengeId = requireString(body, 'challengeId', 100);
    const code = typeof body.code === 'string' ? body.code : '';

    const challenge = findChallenge(challengeId);
    if (!challenge) throw new HttpError(404, `Reto "${challengeId}" no encontrado.`);

    const verdict = await validateSolution(code, challenge);

    const userId = currentUserId(req);
    ensureUser(userId);
    let karmaAwarded = 0;
    if (verdict.passed && markChallengeSolved(userId, challenge.id)) karmaAwarded = KARMA.SOLVE_CHALLENGE;

    const result: ValidationResult = { ...verdict, karmaAwarded, user: getUser(userId)! };
    res.json(result);
  }),
);

challengesRouter.get('/:id', (req, res) => {
  const challenge = findChallenge(req.params.id);
  if (!challenge) throw new HttpError(404, 'Reto no encontrado.');
  res.json(challenge);
});
