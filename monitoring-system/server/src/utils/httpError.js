/**
 * Throwable HTTP error. `body` defaults to `{ error: message }` but can be any
 * JSON-serialisable value (used for the `{ errors: {...} }` validation shape).
 */
export class HttpError extends Error {
  constructor(status, message, body) {
    super(typeof message === 'string' ? message : 'Error');
    this.status = status;
    this.body = body ?? { error: message };
  }
}

export const notFound = (msg = 'Resource not found.') => new HttpError(404, msg);
export const forbidden = (msg = 'Insufficient permissions.') => new HttpError(403, msg);
export const badRequest = (msg) => new HttpError(400, msg);
export const conflict = (msg) => new HttpError(409, msg);
