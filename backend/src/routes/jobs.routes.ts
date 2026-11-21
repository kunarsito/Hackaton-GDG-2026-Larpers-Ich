/**
 * Módulo C — Bolsa de Trabajo colaborativa (RF-08) + canal de empleo y CV (RF-17):
 * postularse con CV (envía mensaje privado al publicador) y ver postulantes.
 */
import { Router } from 'express';
import { getDb, newId, transaction } from '../db/database.js';
import { addRole, ensureUser, getUser, userSummary } from '../services/karma.service.js';
import {
  currentUserId,
  HttpError,
  optionalString,
  requireSessionUserId,
  requireString,
  sessionUserId,
} from '../utils/http.js';
import { getOrCreateConversation, sendMessage } from './messages.routes.js';
import { ownUploadUrl } from './uploads.routes.js';
import type { ApplicationStatus, JobApplication, JobOpportunity, JobType } from '../types/models.js';

const JOB_TYPES: JobType[] = ['Pasantía', 'Junior', 'Freelance'];
const STATUSES: ApplicationStatus[] = ['enviada', 'vista', 'contactado'];

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
  poster_id: string | null;
}

interface ApplicationRow {
  id: string;
  job_id: string;
  applicant_id: string;
  cv_url: string;
  message: string;
  status: ApplicationStatus;
  created_at: string;
}

function toJob(r: JobRow, viewerId: string | null): JobOpportunity {
  const db = getDb();
  const job: JobOpportunity = {
    id: r.id,
    title: r.title,
    companyOrPoster: r.company_or_poster,
    type: r.type,
    modality: r.modality,
    description: r.description,
    requirements: JSON.parse(r.requirements),
    contactUrl: r.contact_url,
    createdAt: r.created_at,
    posterId: r.poster_id ?? undefined,
  };
  if (viewerId) {
    job.hasApplied = Boolean(
      db.prepare('SELECT 1 FROM job_applications WHERE job_id = ? AND applicant_id = ?').get(r.id, viewerId),
    );
    if (r.poster_id === viewerId) {
      job.applicationsCount = (
        db.prepare('SELECT COUNT(*) AS n FROM job_applications WHERE job_id = ?').get(r.id) as { n: number }
      ).n;
    }
  }
  return job;
}

const toApplication = (r: ApplicationRow): JobApplication => {
  const job = getDb().prepare('SELECT title FROM jobs WHERE id = ?').get(r.job_id) as { title: string } | undefined;
  return {
    id: r.id,
    jobId: r.job_id,
    applicantId: r.applicant_id,
    cvUrl: r.cv_url,
    message: r.message,
    status: r.status,
    createdAt: r.created_at,
    applicant: userSummary(r.applicant_id) ?? undefined,
    jobTitle: job?.title,
  };
};

const getRow = (id: string) => getDb().prepare('SELECT * FROM jobs WHERE id = ?').get(id) as JobRow | undefined;

export const jobsRouter = Router();

/** GET /api/jobs?type=Pasantía&modality=Remoto&q=flutter&posterId= */
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
  if (typeof req.query.posterId === 'string') {
    where.push('poster_id = ?');
    params.push(req.query.posterId);
  }
  if (typeof req.query.q === 'string' && req.query.q.trim()) {
    where.push('(title LIKE ? OR description LIKE ? OR company_or_poster LIKE ?)');
    const q = `%${req.query.q.trim()}%`;
    params.push(q, q, q);
  }
  const rows = getDb()
    .prepare(`SELECT * FROM jobs ${where.length ? 'WHERE ' + where.join(' AND ') : ''} ORDER BY created_at DESC`)
    .all(...params) as unknown as JobRow[];
  const viewerId = sessionUserId(req);
  res.json(rows.map((r) => toJob(r, viewerId)));
});

/** GET /api/jobs/applications/mine — mis postulaciones. */
jobsRouter.get('/applications/mine', (req, res) => {
  const userId = requireSessionUserId(req);
  const rows = getDb()
    .prepare('SELECT * FROM job_applications WHERE applicant_id = ? ORDER BY created_at DESC')
    .all(userId) as unknown as ApplicationRow[];
  res.json(rows.map(toApplication));
});

jobsRouter.get('/:id', (req, res) => {
  const row = getRow(req.params.id);
  if (!row) throw new HttpError(404, 'Oportunidad no encontrada.');
  res.json(toJob(row, sessionUserId(req)));
});

/** POST /api/jobs — cualquier usuario o empresa puede publicar (RF-18: obtiene el rol recruiter). */
jobsRouter.post('/', (req, res) => {
  const body = (req.body ?? {}) as Record<string, unknown>;
  const posterId = currentUserId(req);
  ensureUser(posterId);
  const title = requireString(body, 'title', 200);
  const companyOrPoster = requireString(body, 'companyOrPoster', 200);
  const type = requireString(body, 'type', 20) as JobType;
  if (!JOB_TYPES.includes(type)) throw new HttpError(400, `"type" debe ser uno de: ${JOB_TYPES.join(', ')}.`);
  const modality = optionalString(body, 'modality', 100) || 'Remoto';
  const description = requireString(body, 'description', 5_000);
  // El canal principal es "Postularme" dentro de la app; el enlace externo es opcional.
  const contactUrl = optionalString(body, 'contactUrl', 500);
  if (contactUrl && !/^(https?:\/\/|mailto:)/i.test(contactUrl)) {
    throw new HttpError(400, '"contactUrl" debe empezar con http(s):// o mailto:.');
  }
  const requirements = Array.isArray(body.requirements)
    ? body.requirements.filter((r): r is string => typeof r === 'string').map((r) => r.trim()).slice(0, 20)
    : [];

  const id = newId('job');
  transaction(() => {
    getDb()
      .prepare(
        `INSERT INTO jobs (id, title, company_or_poster, type, modality, description, requirements, contact_url, poster_id)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      )
      .run(id, title, companyOrPoster, type, modality, description, JSON.stringify(requirements), contactUrl, posterId);
    addRole(posterId, 'recruiter');
  });
  res.status(201).json(toJob(getRow(id)!, posterId));
});

/**
 * POST /api/jobs/:id/apply { message?, cvUrl? } — RF-17.
 * Usa el CV del perfil si no se manda otro. Envía el CV y el mensaje al publicador por mensaje privado.
 */
jobsRouter.post('/:id/apply', (req, res) => {
  const userId = requireSessionUserId(req);
  const job = getRow(req.params.id);
  if (!job) throw new HttpError(404, 'Oportunidad no encontrada.');
  if (job.poster_id === userId) throw new HttpError(400, 'No puedes postularte a tu propia vacante.');
  const body = (req.body ?? {}) as Record<string, unknown>;
  const user = getUser(userId)!;
  const cvRaw = optionalString(body, 'cvUrl', 300) || user.cvUrl || '';
  if (!cvRaw) throw new HttpError(400, 'Sube tu CV (PDF) en tu perfil antes de postularte.');
  const cvUrl = ownUploadUrl(cvRaw, userId, 'pdf');
  const message = optionalString(body, 'message', 2_000);

  const exists = getDb().prepare('SELECT 1 FROM job_applications WHERE job_id = ? AND applicant_id = ?').get(job.id, userId);
  if (exists) throw new HttpError(409, 'Ya te postulaste a esta vacante.');

  const id = newId('app');
  transaction(() => {
    getDb()
      .prepare('INSERT INTO job_applications (id, job_id, applicant_id, cv_url, message) VALUES (?, ?, ?, ?, ?)')
      .run(id, job.id, userId, cvUrl, message);
  });

  if (job.poster_id && getUser(job.poster_id)) {
    const cvAttachment = getDb()
      .prepare('SELECT id, file_name, mime_type, size_bytes, stored_name FROM attachments WHERE stored_name = ?')
      .get(cvUrl.replace('/uploads/', '')) as
      | { id: string; file_name: string; mime_type: string; size_bytes: number; stored_name: string }
      | undefined;
    const conv = getOrCreateConversation(userId, job.poster_id);
    sendMessage(
      conv.id,
      userId,
      `📄 Postulación a "${job.title}"${message ? `\n\n${message}` : ''}`,
      cvAttachment
        ? [
            {
              id: cvAttachment.id,
              fileName: cvAttachment.file_name,
              mimeType: cvAttachment.mime_type,
              sizeBytes: cvAttachment.size_bytes,
              url: `/uploads/${cvAttachment.stored_name}`,
            },
          ]
        : [],
    );
  }

  const row = getDb().prepare('SELECT * FROM job_applications WHERE id = ?').get(id) as unknown as ApplicationRow;
  res.status(201).json(toApplication(row));
});

/** GET /api/jobs/:id/applications — sólo quien publicó la vacante. Marca las nuevas como "vista". */
jobsRouter.get('/:id/applications', (req, res) => {
  const userId = requireSessionUserId(req);
  const job = getRow(req.params.id);
  if (!job) throw new HttpError(404, 'Oportunidad no encontrada.');
  if (job.poster_id !== userId) throw new HttpError(403, 'Sólo quien publicó la vacante ve los postulantes.');
  const rows = getDb()
    .prepare('SELECT * FROM job_applications WHERE job_id = ? ORDER BY created_at DESC')
    .all(job.id) as unknown as ApplicationRow[];
  const result = rows.map(toApplication);
  getDb().prepare("UPDATE job_applications SET status = 'vista' WHERE job_id = ? AND status = 'enviada'").run(job.id);
  res.json(result);
});

/** PATCH /api/jobs/:id/applications/:appId { status } — p. ej. "contactado". */
jobsRouter.patch('/:id/applications/:appId', (req, res) => {
  const userId = requireSessionUserId(req);
  const job = getRow(req.params.id);
  if (!job || job.poster_id !== userId) throw new HttpError(403, 'Sólo quien publicó la vacante puede cambiar el estado.');
  const status = optionalString((req.body ?? {}) as Record<string, unknown>, 'status', 20) as ApplicationStatus;
  if (!STATUSES.includes(status)) throw new HttpError(400, `"status" debe ser: ${STATUSES.join(', ')}.`);
  const result = getDb()
    .prepare('UPDATE job_applications SET status = ? WHERE id = ? AND job_id = ?')
    .run(status, req.params.appId, job.id);
  if (!Number(result.changes)) throw new HttpError(404, 'Postulación no encontrada.');
  const row = getDb().prepare('SELECT * FROM job_applications WHERE id = ?').get(req.params.appId) as unknown as ApplicationRow;
  res.json(toApplication(row));
});
