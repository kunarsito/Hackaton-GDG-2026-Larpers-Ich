import type { NextFunction, Request, RequestHandler, Response } from 'express';
import { userIdFromToken } from '../services/auth.service.js';

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

/** Token de `Authorization: Bearer <token>`, o null. */
export function bearerToken(req: Request): string | null {
  const auth = req.header('authorization') ?? '';
  const match = /^Bearer\s+(\S+)$/i.exec(auth);
  return match ? match[1] : null;
}

/**
 * Usuario de la sesión. Lanza 401 si el token no es válido o expiró;
 * devuelve null si no se envió token.
 */
export function sessionUserId(req: Request): string | null {
  const token = bearerToken(req);
  if (!token) return null;
  const userId = userIdFromToken(token);
  if (!userId) throw new HttpError(401, 'Sesión inválida o expirada. Vuelve a iniciar sesión.');
  return userId;
}

/**
 * Usuario actual: el de la sesión (`Authorization: Bearer`). Si no hay token y
 * REQUIRE_AUTH no es "true", cae al modo invitado: cabecera `x-user-id`,
 * body (`userId` / `authorId`) o usuario demo.
 */
export function currentUserId(req: Request): string {
  const fromSession = sessionUserId(req);
  if (fromSession) return fromSession;
  if (process.env.REQUIRE_AUTH === 'true') throw new HttpError(401, 'Inicia sesión para continuar.');

  const header = req.header('x-user-id');
  const body = (req.body ?? {}) as Record<string, unknown>;
  const fromBody = typeof body.userId === 'string' ? body.userId : typeof body.authorId === 'string' ? body.authorId : '';
  return (header || fromBody || process.env.DEMO_USER_ID || 'usr-001').trim();
}

/**
 * Para funciones privadas (mensajes, editar perfil, postulaciones, regalar Karma):
 * exige sesión real, sin caer al modo invitado.
 */
export function requireSessionUserId(req: Request): string {
  const userId = sessionUserId(req);
  if (!userId) throw new HttpError(401, 'Inicia sesión para usar esta función.');
  return userId;
}

/** Lista de textos (p. ej. skills o tags): recorta, quita vacíos y duplicados. */
export function optionalStringArray(body: Record<string, unknown>, field: string, maxItems = 20, maxLen = 40): string[] {
  const v = body[field];
  if (v == null) return [];
  if (!Array.isArray(v)) throw new HttpError(400, `El campo "${field}" debe ser una lista.`);
  const items = v
    .filter((x): x is string => typeof x === 'string')
    .map((x) => x.trim())
    .filter(Boolean);
  if (items.some((x) => x.length > maxLen)) throw new HttpError(400, `Cada elemento de "${field}" admite ${maxLen} caracteres.`);
  return [...new Set(items)].slice(0, maxItems);
}

/** ?sort=top|new (por defecto "top", RF-13). */
export function sortParam(req: Request): 'top' | 'new' {
  return req.query.sort === 'new' ? 'new' : 'top';
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
