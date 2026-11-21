import type { NextFunction, Request, RequestHandler, Response } from 'express';

/** Error con código HTTP que el manejador global convierte en JSON. */
export class HttpError extends Error {
  constructor(
    public status: number,
    message: string,
  ) {
    super(message);
  }
}

/** Express 4 no captura promesas rechazadas: este wrapper las envía al manejador de errores. */
export const asyncHandler =
  (fn: (req: Request, res: Response, next: NextFunction) => unknown): RequestHandler =>
  (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
  };

/**
 * Sin autenticación en el MVP (modo invitado): el usuario sale de la cabecera
 * `x-user-id`, del body (`userId` / `authorId`) o del usuario demo.
 */
export function currentUserId(req: Request): string {
  const header = req.header('x-user-id');
  const body = (req.body ?? {}) as Record<string, unknown>;
  const fromBody = typeof body.userId === 'string' ? body.userId : typeof body.authorId === 'string' ? body.authorId : '';
  return (header || fromBody || process.env.DEMO_USER_ID || 'usr-001').trim();
}

export function requireString(body: Record<string, unknown>, field: string, max = 5_000): string {
  const v = body[field];
  if (typeof v !== 'string' || !v.trim()) throw new HttpError(400, `El campo "${field}" es obligatorio.`);
  if (v.length > max) throw new HttpError(400, `El campo "${field}" supera ${max} caracteres.`);
  return v.trim();
}

export function optionalString(body: Record<string, unknown>, field: string, max = 20_000): string {
  const v = body[field];
  if (v == null) return '';
  if (typeof v !== 'string') throw new HttpError(400, `El campo "${field}" debe ser texto.`);
  if (v.length > max) throw new HttpError(400, `El campo "${field}" supera ${max} caracteres.`);
  return v.trim();
}
