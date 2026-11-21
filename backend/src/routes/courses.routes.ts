/** RF-09 Cursos (oficiales y de creadores): inscripción, avance, calificación y ranking por rating. */
import { Router } from 'express';
import { getDb, newId, transaction } from '../db/database.js';
import { addKarma, addRole, ensureUser, getUser, KARMA, parseJson, userName } from '../services/karma.service.js';
import {
  currentUserId,
  HttpError,
  optionalString,
  optionalStringArray,
  requireSessionUserId,
  requireString,
  sortParam,
} from '../utils/http.js';
import { findArticle } from './articles.routes.js';
import { findChallenge } from './challenges.routes.js';
import { createFeedPost } from './community.routes.js';
import { ownUploadUrl } from './uploads.routes.js';
import type { ContentSource, Course, CourseLesson, Difficulty } from '../types/models.js';

const LEVELS: Difficulty[] = ['Básico', 'Intermedio', 'Avanzado'];

interface CourseRow {
  id: string;
  source: ContentSource;
  author_id: string | null;
  title: string;
  description: string;
  cover_url: string | null;
  level: Difficulty;
  tags: string;
  lessons: string;
  created_at: string;
  rating_avg: number | null;
  rating_count: number;
  enrolled_count: number;
}

const SELECT = `
  SELECT c.*,
         (SELECT AVG(rating) FROM course_ratings r WHERE r.course_id = c.id) AS rating_avg,
         (SELECT COUNT(*) FROM course_ratings r WHERE r.course_id = c.id) AS rating_count,
         (SELECT COUNT(*) FROM course_enrollments e WHERE e.course_id = c.id) AS enrolled_count
  FROM courses c`;

function toCourse(r: CourseRow, viewerId: string): Course {
  const db = getDb();
  const enrollment = db
    .prepare('SELECT completed_at FROM course_enrollments WHERE course_id = ? AND user_id = ?')
    .get(r.id, viewerId) as { completed_at: string | null } | undefined;
  const rating = db
    .prepare('SELECT rating FROM course_ratings WHERE course_id = ? AND user_id = ?')
    .get(r.id, viewerId) as { rating: number } | undefined;
  return {
    id: r.id,
    source: r.source,
    authorId: r.author_id ?? undefined,
    authorName: userName(r.author_id),
    title: r.title,
    description: r.description,
    coverUrl: r.cover_url ?? undefined,
    level: r.level,
    tags: parseJson<string[]>(r.tags, []),
    lessons: parseJson<CourseLesson[]>(r.lessons, []),
    ratingAvg: Math.round((r.rating_avg ?? 0) * 10) / 10,
    ratingCount: r.rating_count,
    enrolledCount: r.enrolled_count,
    createdAt: r.created_at,
    isEnrolled: Boolean(enrollment),
    isCompleted: Boolean(enrollment?.completed_at),
    myRating: rating?.rating ?? 0,
  };
}

function getCourse(id: string, viewerId: string): Course | null {
  const row = getDb().prepare(`${SELECT} WHERE c.id = ?`).get(id) as CourseRow | undefined;
  return row ? toCourse(row, viewerId) : null;
}

function requireCourse(id: string, viewerId: string): Course {
  const course = getCourse(id, viewerId);
  if (!course) throw new HttpError(404, 'Curso no encontrado.');
  return course;
}

/** Valida y normaliza los datos editables de un curso (crear y editar comparten reglas). */
function parseCourseInput(body: Record<string, unknown>, userId: string) {
  const title = requireString(body, 'title', 150);
  const description = requireString(body, 'description', 3_000);
  const level = requireString(body, 'level', 20) as Difficulty;
  if (!LEVELS.includes(level)) throw new HttpError(400, `"level" debe ser: ${LEVELS.join(', ')}.`);
  const tags = optionalStringArray(body, 'tags', 8, 30);
  const coverRaw = optionalString(body, 'coverUrl', 300);
  const coverUrl = coverRaw ? ownUploadUrl(coverRaw, userId, 'image') : null;

  if (!Array.isArray(body.lessons) || body.lessons.length === 0) throw new HttpError(400, 'Agrega al menos una lección.');
  if (body.lessons.length > 30) throw new HttpError(400, 'Máximo 30 lecciones.');
  const lessons: CourseLesson[] = body.lessons.map((raw, i) => {
    const l = (raw ?? {}) as Record<string, unknown>;
    const articleId = typeof l.articleId === 'string' && l.articleId ? l.articleId : undefined;
    const challengeId = typeof l.challengeId === 'string' && l.challengeId ? l.challengeId : undefined;
    if (!articleId && !challengeId) throw new HttpError(400, `La lección ${i + 1} debe enlazar un artículo o un reto.`);
    const article = articleId ? findArticle(articleId) : null;
    const challenge = challengeId ? findChallenge(challengeId) : null;
    if (articleId && !article) throw new HttpError(400, `Artículo "${articleId}" no existe.`);
    if (challengeId && !challenge) throw new HttpError(400, `Reto "${challengeId}" no existe.`);
    const lessonTitle =
      (typeof l.title === 'string' && l.title.trim().slice(0, 150)) || article?.title || challenge?.title || `Lección ${i + 1}`;
    return { order: i + 1, title: lessonTitle, articleId, challengeId };
  });
  return { title, description, level, tags, coverUrl, lessons };
}

/** Sólo el autor (o un admin) puede editar o borrar un curso; los oficiales no se tocan desde aquí. */
function requireCourseOwner(id: string, userId: string): Course {
  const course = requireCourse(id, userId);
  const isAdmin = getUser(userId)?.roles.includes('admin') ?? false;
  if (course.source === 'official' && !isAdmin) throw new HttpError(403, 'Los cursos oficiales no se pueden modificar.');
  if (course.authorId !== userId && !isAdmin) throw new HttpError(403, 'Sólo el creador puede modificar este curso.');
  return course;
}

/** Lecciones-reto del curso que el usuario aún no ha resuelto. */
function pendingChallengeLessons(course: Course, userId: string): CourseLesson[] {
  const solved = new Set(
    (
      getDb().prepare('SELECT challenge_id FROM solved_challenges WHERE user_id = ?').all(userId) as {
        challenge_id: string;
      }[]
    ).map((r) => r.challenge_id),
  );
  return course.lessons.filter((l) => l.challengeId && !solved.has(l.challengeId));
}

export const coursesRouter = Router();

/** GET /api/courses?source=official|community&sort=top|new&authorId=&enrolled=me */
coursesRouter.get('/', (req, res) => {
  const viewerId = currentUserId(req);
  const where: string[] = [];
  const params: string[] = [];
  if (req.query.source === 'official' || req.query.source === 'community') {
    where.push('c.source = ?');
    params.push(req.query.source);
  }
  if (typeof req.query.authorId === 'string') {
    where.push('c.author_id = ?');
    params.push(req.query.authorId);
  }
  if (req.query.enrolled === 'me') {
    where.push('c.id IN (SELECT course_id FROM course_enrollments WHERE user_id = ?)');
    params.push(viewerId);
  }
  // RF-13: "Top" = mejor rating promedio (y más votos) arriba.
  const order =
    sortParam(req) === 'new'
      ? 'c.created_at DESC'
      : 'COALESCE(rating_avg, 0) DESC, rating_count DESC, enrolled_count DESC, c.created_at DESC';
  const rows = getDb()
    .prepare(`${SELECT} ${where.length ? 'WHERE ' + where.join(' AND ') : ''} ORDER BY ${order}`)
    .all(...params) as unknown as CourseRow[];
  res.json(rows.map((r) => toCourse(r, viewerId)));
});

coursesRouter.get('/:id', (req, res) => {
  res.json(requireCourse(req.params.id, currentUserId(req)));
});

/**
 * POST /api/courses { title, description, level, tags?, coverUrl?, lessons: [{ title, articleId?, challengeId? }] }
 * Cada lección enlaza un artículo o un reto existente (propio u oficial).
 */
coursesRouter.post('/', (req, res) => {
  const body = (req.body ?? {}) as Record<string, unknown>;
  const user = ensureUser(currentUserId(req));
  const { title, description, level, tags, coverUrl, lessons } = parseCourseInput(body, user.id);

  const id = newId('crs');
  transaction(() => {
    getDb()
      .prepare(
        `INSERT INTO courses (id, source, author_id, title, description, cover_url, level, tags, lessons)
         VALUES (?, 'community', ?, ?, ?, ?, ?, ?, ?)`,
      )
      .run(id, user.id, title, description, coverUrl, level, JSON.stringify(tags), JSON.stringify(lessons));
    addRole(user.id, 'creator');
    createFeedPost({
      authorId: user.id,
      type: 'course',
      title: `Nuevo curso: ${title}`,
      body: description.slice(0, 400),
      refId: id,
    });
  });
  res.status(201).json(getCourse(id, user.id));
});

/**
 * PATCH /api/courses/:id — editar un curso propio (mismos campos que al crearlo).
 * Exige sesión real. Actualiza también el anuncio del curso en el feed.
 */
coursesRouter.patch('/:id', (req, res) => {
  const userId = requireSessionUserId(req);
  const course = requireCourseOwner(req.params.id, userId);
  const body = (req.body ?? {}) as Record<string, unknown>;
  const { title, description, level, tags, coverUrl, lessons } = parseCourseInput(body, userId);
  transaction(() => {
    getDb()
      .prepare(
        `UPDATE courses SET title = ?, description = ?, cover_url = ?, level = ?, tags = ?, lessons = ?
         WHERE id = ?`,
      )
      .run(title, description, coverUrl, level, JSON.stringify(tags), JSON.stringify(lessons), course.id);
    getDb()
      .prepare(`UPDATE forum_posts SET title = ?, body = ? WHERE type = 'course' AND ref_id = ?`)
      .run(`Nuevo curso: ${title}`, description.slice(0, 400), course.id);
  });
  res.json(getCourse(course.id, userId));
});

/**
 * DELETE /api/courses/:id — borrar un curso propio. Las inscripciones y
 * calificaciones se borran en cascada; también se quita su anuncio del feed.
 */
coursesRouter.delete('/:id', (req, res) => {
  const userId = requireSessionUserId(req);
  const course = requireCourseOwner(req.params.id, userId);
  transaction(() => {
    getDb().prepare(`DELETE FROM forum_posts WHERE type = 'course' AND ref_id = ?`).run(course.id);
    getDb().prepare('DELETE FROM courses WHERE id = ?').run(course.id);
  });
  res.status(204).end();
});

/** POST /api/courses/:id/enroll */
coursesRouter.post('/:id/enroll', (req, res) => {
  const userId = currentUserId(req);
  ensureUser(userId);
  const course = requireCourse(req.params.id, userId);
  getDb().prepare('INSERT OR IGNORE INTO course_enrollments (course_id, user_id) VALUES (?, ?)').run(course.id, userId);
  res.json(getCourse(course.id, userId));
});

/** POST /api/courses/:id/complete — RF-14: +20 Karma al creador (una vez por alumno). */
coursesRouter.post('/:id/complete', (req, res) => {
  const userId = currentUserId(req);
  ensureUser(userId);
  const course = requireCourse(req.params.id, userId);
  if (!course.isEnrolled) throw new HttpError(400, 'Inscríbete al curso antes de completarlo.');
  if (course.isCompleted) {
    res.json({ course, karmaAwarded: 0 });
    return;
  }
  // Un curso sólo se completa cuando todas sus prácticas (lecciones-reto) están resueltas.
  const pending = pendingChallengeLessons(course, userId);
  if (pending.length > 0) {
    const list = pending.map((l) => `${l.order}. ${l.title}`).join('; ');
    throw new HttpError(
      400,
      `Te ${pending.length === 1 ? 'falta 1 práctica' : `faltan ${pending.length} prácticas`} por resolver: ${list}.`,
    );
  }
  let karmaAwarded = 0;
  transaction(() => {
    getDb()
      .prepare('UPDATE course_enrollments SET completed_at = ? WHERE course_id = ? AND user_id = ?')
      .run(new Date().toISOString(), course.id, userId);
    if (course.authorId && course.authorId !== userId) {
      addKarma(course.authorId, KARMA.COURSE_COMPLETED, 'course_completed', { fromUserId: userId, refId: course.id });
      karmaAwarded = KARMA.COURSE_COMPLETED;
    }
  });
  res.json({ course: getCourse(course.id, userId), karmaAwarded });
});

/** POST /api/courses/:id/rate { rating: 1..5 } — sólo alumnos inscritos, no el autor. */
coursesRouter.post('/:id/rate', (req, res) => {
  const userId = currentUserId(req);
  ensureUser(userId);
  const course = requireCourse(req.params.id, userId);
  if (course.authorId === userId) throw new HttpError(400, 'No puedes calificar tu propio curso.');
  if (!course.isEnrolled) throw new HttpError(400, 'Inscríbete al curso para calificarlo.');
  const rating = Math.round(Number((req.body as Record<string, unknown>)?.rating));
  if (!(rating >= 1 && rating <= 5)) throw new HttpError(400, '"rating" debe estar entre 1 y 5.');
  getDb()
    .prepare(
      `INSERT INTO course_ratings (course_id, user_id, rating) VALUES (?, ?, ?)
       ON CONFLICT (course_id, user_id) DO UPDATE SET rating = excluded.rating`,
    )
    .run(course.id, userId, rating);
  res.json(getCourse(course.id, userId));
});
