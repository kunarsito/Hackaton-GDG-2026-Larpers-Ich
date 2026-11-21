/** Módulo B — Zona de Práctica (RF-03, RF-04) + retos de la comunidad (RF-10, RF-11, RF-13). */
import { Router } from 'express';
import { getDb, newId, transaction } from '../db/database.js';
import { validateSolution } from '../services/code_validator.service.js';
import {
  addRole,
  applyVote,
  ensureUser,
  getUser,
  markChallengeSolved,
  myVotes,
  userName,
} from '../services/karma.service.js';
import { asyncHandler, currentUserId, HttpError, optionalString, requireString, sortParam } from '../utils/http.js';
import { createFeedPost } from './community.routes.js';
import type { Challenge, ContentSource, Difficulty, TestCase, ValidationResult } from '../types/models.js';

const DIFFICULTIES: Difficulty[] = ['Básico', 'Intermedio', 'Avanzado'];

interface ChallengeRow {
  id: string;
  title: string;
  difficulty: Difficulty;
  category: string;
  description: string;
  starter_code: string;
  function_name: string;
  test_cases: string;
  source: ContentSource;
  author_id: string | null;
  upvotes: number;
  downvotes: number;
  forked_from_id: string | null;
  created_at: string;
}

const toChallenge = (r: ChallengeRow, myVote = 0): Challenge => ({
  id: r.id,
  title: r.title,
  difficulty: r.difficulty,
  category: r.category,
  description: r.description,
  starterCode: r.starter_code,
  functionName: r.function_name,
  testCases: JSON.parse(r.test_cases),
  source: r.source,
  authorId: r.author_id ?? undefined,
  authorName: userName(r.author_id),
  upvotes: r.upvotes,
  downvotes: r.downvotes,
  forkedFromId: r.forked_from_id ?? undefined,
  createdAt: r.created_at,
  myVote,
});

const getRow = (id: string) =>
  getDb().prepare('SELECT * FROM challenges WHERE id = ?').get(id) as ChallengeRow | undefined;

export function findChallenge(id: string): Challenge | null {
  const row = getRow(id);
  return row ? toChallenge(row) : null;
}

/** Nombre de la primera función declarada en el código base: `int sumar(List<int> x) {` -> "sumar". */
export function inferFunctionName(code: string): string | null {
  const match = /^\s*(?:[\w<>?,\s\[\]]+?)\s+([a-zA-Z_]\w*)\s*\([^)]*\)\s*(?:async\s*)?\{/m.exec(code);
  return match ? match[1] : null;
}

export const challengesRouter = Router();

/** GET /api/challenges?source=official|community&sort=top|new&difficulty=&category=&authorId= */
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
  if (req.query.source === 'official' || req.query.source === 'community') {
    where.push('source = ?');
    params.push(req.query.source);
  }
  if (typeof req.query.authorId === 'string') {
    where.push('author_id = ?');
    params.push(req.query.authorId);
  }
  const order =
    sortParam(req) === 'new'
      ? 'created_at DESC'
      : "CASE source WHEN 'official' THEN 0 ELSE 1 END, CASE source WHEN 'official' THEN sort_order ELSE -(upvotes - downvotes) END, created_at DESC";
  const sql = `SELECT * FROM challenges ${where.length ? 'WHERE ' + where.join(' AND ') : ''} ORDER BY ${order}`;
  const rows = getDb().prepare(sql).all(...params) as unknown as ChallengeRow[];
  const votes = myVotes(currentUserId(req), 'challenge', rows.map((r) => r.id));
  res.json(rows.map((r) => toChallenge(r, votes.get(r.id) ?? 0)));
});

/**
 * POST /api/challenges — RF-10: reto creado por un usuario (espacio Comunidad).
 * { title, difficulty, category, description, starterCode, testCases: [{input, expectedOutput, description?}], forkedFromId? }
 * El validador llama a la primera función del código base con cada `input`.
 */
challengesRouter.post('/', (req, res) => {
  const body = (req.body ?? {}) as Record<string, unknown>;
  const user = ensureUser(currentUserId(req));
  const title = requireString(body, 'title', 150);
  const difficulty = requireString(body, 'difficulty', 20) as Difficulty;
  if (!DIFFICULTIES.includes(difficulty)) throw new HttpError(400, `"difficulty" debe ser: ${DIFFICULTIES.join(', ')}.`);
  const category = optionalString(body, 'category', 80) || 'General';
  const description = requireString(body, 'description', 10_000);
  const starterCode = requireString(body, 'starterCode', 10_000);
  const functionName = inferFunctionName(starterCode);
  if (!functionName) {
    throw new HttpError(400, 'El código base debe declarar una función, p. ej. "int sumar(List<int> numeros) { ... }".');
  }

  if (!Array.isArray(body.testCases) || body.testCases.length === 0) {
    throw new HttpError(400, 'Agrega al menos un caso de prueba.');
  }
  if (body.testCases.length > 10) throw new HttpError(400, 'Máximo 10 casos de prueba.');
  const testCases: TestCase[] = body.testCases.map((raw, i) => {
    const tc = (raw ?? {}) as Record<string, unknown>;
    const input = typeof tc.input === 'string' ? tc.input.trim() : '';
    const expectedOutput = typeof tc.expectedOutput === 'string' ? tc.expectedOutput.trim() : '';
    if (!input || !expectedOutput) throw new HttpError(400, `El caso ${i + 1} necesita entrada y salida esperada.`);
    if (input.length > 500 || expectedOutput.length > 500) throw new HttpError(400, `El caso ${i + 1} es demasiado largo.`);
    const description = typeof tc.description === 'string' && tc.description.trim() ? tc.description.trim().slice(0, 200) : `Caso ${i + 1}`;
    return { input, expectedOutput, description };
  });

  const forkedFromId = optionalString(body, 'forkedFromId', 100) || null;
  if (forkedFromId && !getRow(forkedFromId)) throw new HttpError(400, 'El reto original no existe.');

  const id = newId('ch');
  transaction(() => {
    getDb()
      .prepare(
        `INSERT INTO challenges (id, title, difficulty, category, description, starter_code, function_name, test_cases,
                                 sort_order, source, author_id, forked_from_id, created_at)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1000, 'community', ?, ?, ?)`,
      )
      .run(
        id,
        title,
        difficulty,
        category,
        description,
        starterCode,
        functionName,
        JSON.stringify(testCases),
        user.id,
        forkedFromId,
        new Date().toISOString(),
      );
    addRole(user.id, 'creator');
    createFeedPost({
      authorId: user.id,
      type: 'challenge',
      title: `${forkedFromId ? 'Fork de reto' : 'Nuevo reto'}: ${title}`,
      body: description.slice(0, 400),
      challengeId: id,
      refId: id,
    });
  });
  res.status(201).json(findChallenge(id));
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
    const karmaAwarded = verdict.passed ? markChallengeSolved(userId, challenge.id, challenge.source) : 0;

    const result: ValidationResult = { ...verdict, karmaAwarded, user: getUser(userId)! };
    res.json(result);
  }),
);

challengesRouter.get('/:id', (req, res) => {
  const row = getRow(req.params.id);
  if (!row) throw new HttpError(404, 'Reto no encontrado.');
  const vote = myVotes(currentUserId(req), 'challenge', [row.id]).get(row.id) ?? 0;
  res.json(toChallenge(row, vote));
});

/** POST /api/challenges/:id/vote { value: 1 | -1 | 0 } — el contenido oficial no admite votos negativos. */
challengesRouter.post('/:id/vote', (req, res) => {
  const row = getRow(req.params.id);
  if (!row) throw new HttpError(404, 'Reto no encontrado.');
  const requested = Number((req.body as Record<string, unknown>)?.value) || 0;
  if (row.source === 'official' && requested < 0) {
    throw new HttpError(400, 'El contenido oficial no admite votos negativos.');
  }
  const userId = currentUserId(req);
  ensureUser(userId);
  const value = transaction(() =>
    applyVote({
      userId,
      targetType: 'challenge',
      targetId: row.id,
      table: 'challenges',
      authorId: row.author_id,
      value: requested,
    }),
  );
  res.json(toChallenge(getRow(row.id)!, value));
});
