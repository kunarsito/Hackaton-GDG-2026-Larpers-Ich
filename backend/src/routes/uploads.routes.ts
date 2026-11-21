/**
 * RF-12 Archivos adjuntos: POST /api/uploads (multipart, campo "file").
 * Límite 10 MB. Se guardan en UPLOADS_DIR y se sirven en /uploads/<archivo>.
 * Sólo extensiones de la lista blanca (nada de .html/.svg/.js ejecutables en el navegador).
 */
import { Router } from 'express';
import multer from 'multer';
import { mkdirSync } from 'node:fs';
import { extname, resolve } from 'node:path';
import { getDb, newId } from '../db/database.js';
import { HttpError, requireSessionUserId } from '../utils/http.js';
import type { Attachment } from '../types/models.js';

export const MAX_UPLOAD_BYTES = 10 * 1024 * 1024;
export const MAX_ATTACHMENTS_PER_ITEM = 4;

/** extensión -> tipo MIME con el que se sirve (no se confía en el que manda el cliente). */
const ALLOWED: Record<string, string> = {
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.webp': 'image/webp',
  '.pdf': 'application/pdf',
  '.zip': 'application/zip',
  '.txt': 'text/plain',
  '.md': 'text/plain',
  '.csv': 'text/plain',
  '.json': 'text/plain',
  '.dart': 'text/plain',
  '.ts': 'text/plain',
  '.py': 'text/plain',
  '.java': 'text/plain',
  '.c': 'text/plain',
  '.cpp': 'text/plain',
  '.kt': 'text/plain',
  '.go': 'text/plain',
  '.rs': 'text/plain',
  '.sql': 'text/plain',
};

export const uploadsDir = () => resolve(process.env.UPLOADS_DIR ?? './uploads');

export const mimeForStoredName = (name: string) => ALLOWED[extname(name).toLowerCase()];

interface AttachmentRow {
  id: string;
  owner_id: string;
  file_name: string;
  mime_type: string;
  size_bytes: number;
  stored_name: string;
}

const toAttachment = (r: AttachmentRow): Attachment => ({
  id: r.id,
  fileName: r.file_name,
  mimeType: r.mime_type,
  sizeBytes: r.size_bytes,
  url: `/uploads/${r.stored_name}`,
});

/**
 * Convierte la lista que manda el cliente (Attachment[] o ids) en adjuntos reales
 * del usuario. Rechaza ids ajenos o inexistentes.
 */
export function resolveAttachments(raw: unknown, ownerId: string): Attachment[] {
  if (raw == null) return [];
  if (!Array.isArray(raw)) throw new HttpError(400, '"attachments" debe ser una lista.');
  if (raw.length > MAX_ATTACHMENTS_PER_ITEM) {
    throw new HttpError(400, `Máximo ${MAX_ATTACHMENTS_PER_ITEM} archivos por publicación.`);
  }
  const stmt = getDb().prepare('SELECT * FROM attachments WHERE id = ? AND owner_id = ?');
  return raw.map((item) => {
    const id = typeof item === 'string' ? item : (item as { id?: unknown })?.id;
    if (typeof id !== 'string') throw new HttpError(400, 'Adjunto inválido.');
    const row = stmt.get(id, ownerId) as AttachmentRow | undefined;
    if (!row) throw new HttpError(400, 'Uno de los archivos adjuntos no existe o no es tuyo.');
    return toAttachment(row);
  });
}

/** Valida que una URL (CV, avatar) apunte a un archivo subido por el propio usuario. */
export function ownUploadUrl(url: string, ownerId: string, kind: 'pdf' | 'image'): string {
  const stored = url.replace(/^.*\/uploads\//, '');
  const row = getDb()
    .prepare('SELECT * FROM attachments WHERE stored_name = ? AND owner_id = ?')
    .get(stored, ownerId) as AttachmentRow | undefined;
  if (!row) throw new HttpError(400, 'Sube el archivo primero con /api/uploads.');
  if (kind === 'pdf' && row.mime_type !== 'application/pdf') throw new HttpError(400, 'El CV debe ser un PDF.');
  if (kind === 'image' && !row.mime_type.startsWith('image/')) throw new HttpError(400, 'La foto debe ser una imagen.');
  return `/uploads/${row.stored_name}`;
}

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    mkdirSync(uploadsDir(), { recursive: true });
    cb(null, uploadsDir());
  },
  filename: (_req, file, cb) => cb(null, `${newId('file')}${extname(file.originalname).toLowerCase()}`),
});

const upload = multer({
  storage,
  limits: { fileSize: MAX_UPLOAD_BYTES, files: 1 },
  fileFilter: (_req, file, cb) => {
    if (ALLOWED[extname(file.originalname).toLowerCase()]) cb(null, true);
    else cb(new HttpError(400, `Tipo de archivo no permitido. Usa: ${Object.keys(ALLOWED).join(' ')}`));
  },
});

export const uploadsRouter = Router();

uploadsRouter.post(
  '/',
  (req, _res, next) => {
    // Exige sesión antes de aceptar bytes
    try {
      requireSessionUserId(req);
      next();
    } catch (e) {
      next(e);
    }
  },
  (req, res, next) => {
    upload.single('file')(req, res, (err: unknown) => {
      if (err instanceof multer.MulterError && err.code === 'LIMIT_FILE_SIZE') {
        next(new HttpError(413, 'El archivo supera 10 MB.'));
      } else {
        next(err);
      }
    });
  },
  (req, res) => {
    const userId = requireSessionUserId(req);
    const file = req.file;
    if (!file) throw new HttpError(400, 'Falta el archivo (campo "file").');
    const id = newId('att');
    const mime = ALLOWED[extname(file.filename).toLowerCase()];
    const fileName = Buffer.from(file.originalname, 'latin1').toString('utf8').slice(0, 200);
    getDb()
      .prepare(
        'INSERT INTO attachments (id, owner_id, file_name, mime_type, size_bytes, stored_name) VALUES (?, ?, ?, ?, ?, ?)',
      )
      .run(id, userId, fileName, mime, file.size, file.filename);
    const row = getDb().prepare('SELECT * FROM attachments WHERE id = ?').get(id) as unknown as AttachmentRow;
    res.status(201).json(toAttachment(row));
  },
);
