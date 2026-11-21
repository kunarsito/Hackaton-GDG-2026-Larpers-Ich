/** Módulo C — Bolsa de Trabajo colaborativa (RF-08). */
import { Router } from 'express';
import { getDb, newId } from '../db/database.js';
import { HttpError, optionalString, requireString } from '../utils/http.js';
import type { JobOpportunity, JobType } from '../types/models.js';

const JOB_TYPES: JobType[] = ['Pasantía', 'Junior', 'Freelance'];

interface JobRow {
  id: string;
  title: string;
  company_or_poster: string;
  type: JobType;
  modality: string;
  description: string;
  requirements: string;
  contact_url: string;
  created_at: string;
}

const toJob = (r: JobRow): JobOpportunity => ({
  id: r.id,
  title: r.title,
  companyOrPoster: r.company_or_poster,
  type: r.type,
  modality: r.modality,
  description: r.description,
  requirements: JSON.parse(r.requirements),
  contactUrl: r.contact_url,
  createdAt: r.created_at,
});

export const jobsRouter = Router();

/** GET /api/jobs?type=Pasantía&modality=Remoto&q=flutter */
jobsRouter.get('/', (req, res) => {
  const where: string[] = [];
  const params: string[] = [];
  if (typeof req.query.type === 'string' && req.query.type !== 'Todos') {
    where.push('type = ?');
    params.push(req.query.type);
  }
  if (typeof req.query.modality === 'string') {
    where.push('modality LIKE ?');
    params.push(`%${req.query.modality}%`);
  }
  if (typeof req.query.q === 'string' && req.query.q.trim()) {
    where.push('(title LIKE ? OR description LIKE ? OR company_or_poster LIKE ?)');
    const q = `%${req.query.q.trim()}%`;
    params.push(q, q, q);
  }
  const rows = getDb()
    .prepare(`SELECT * FROM jobs ${where.length ? 'WHERE ' + where.join(' AND ') : ''} ORDER BY created_at DESC`)
    .all(...params) as unknown as JobRow[];
  res.json(rows.map(toJob));
});

jobsRouter.get('/:id', (req, res) => {
  const row = getDb().prepare('SELECT * FROM jobs WHERE id = ?').get(req.params.id) as JobRow | undefined;
  if (!row) throw new HttpError(404, 'Oportunidad no encontrada.');
  res.json(toJob(row));
});

/** POST /api/jobs — cualquier usuario o empresa puede publicar. */
jobsRouter.post('/', (req, res) => {
  const body = (req.body ?? {}) as Record<string, unknown>;
  const title = requireString(body, 'title', 200);
  const companyOrPoster = requireString(body, 'companyOrPoster', 200);
  const type = requireString(body, 'type', 20) as JobType;
  if (!JOB_TYPES.includes(type)) throw new HttpError(400, `"type" debe ser uno de: ${JOB_TYPES.join(', ')}.`);
  const modality = optionalString(body, 'modality', 100) || 'Remoto';
  const description = requireString(body, 'description', 5_000);
  const contactUrl = requireString(body, 'contactUrl', 500);
  if (!/^(https?:\/\/|mailto:)/i.test(contactUrl)) {
    throw new HttpError(400, '"contactUrl" debe empezar con http(s):// o mailto:.');
  }
  const requirements = Array.isArray(body.requirements)
    ? body.requirements.filter((r): r is string => typeof r === 'string').map((r) => r.trim()).slice(0, 20)
    : [];

  const id = newId('job');
  getDb()
    .prepare(
      `INSERT INTO jobs (id, title, company_or_poster, type, modality, description, requirements, contact_url)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    )
    .run(id, title, companyOrPoster, type, modality, description, JSON.stringify(requirements), contactUrl);

  const row = getDb().prepare('SELECT * FROM jobs WHERE id = ?').get(id) as unknown as JobRow;
  res.status(201).json(toJob(row));
});
