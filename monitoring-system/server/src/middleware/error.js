import { ZodError } from 'zod';
import { HttpError } from '../utils/httpError.js';

/** 404 for anything that fell through the routers (mirrors Flask's handler). */
export function notFoundHandler(_req, res) {
  res.status(404).json({ error: 'Resource not found.' });
}

/** Central error formatter. */
// eslint-disable-next-line no-unused-vars
export function errorHandler(err, _req, res, _next) {
  if (err instanceof ZodError) {
    return res.status(422).json({ errors: err.flatten().fieldErrors });
  }
  if (err instanceof HttpError) {
    return res.status(err.status).json(err.body);
  }
  console.error(err);
  return res.status(500).json({ error: 'Internal server error.' });
}

/** Wrap an async route handler so thrown errors reach errorHandler. */
export const asyncHandler = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);
