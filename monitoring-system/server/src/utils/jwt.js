import jwt from 'jsonwebtoken';
import { config } from '../config.js';

// Token shape mirrors Flask-JWT-Extended: identity in `sub` (stringified id),
// a custom `role` claim on the access token, `type` distinguishes the two.

export function signAccess(user) {
  return jwt.sign({ role: user.role, type: 'access' }, config.jwtSecret, {
    subject: String(user.id),
    expiresIn: config.jwtAccessTtl,
  });
}

export function signRefresh(user) {
  return jwt.sign({ type: 'refresh' }, config.jwtSecret, {
    subject: String(user.id),
    expiresIn: config.jwtRefreshTtl,
  });
}

export function makeTokens(user) {
  return { access_token: signAccess(user), refresh_token: signRefresh(user) };
}

/** Verify and decode; throws jsonwebtoken errors on failure. */
export function verifyToken(token) {
  return jwt.verify(token, config.jwtSecret);
}

/** Pull the bearer token out of an Authorization header. */
export function bearer(req) {
  const h = req.headers.authorization || '';
  const [scheme, value] = h.split(' ');
  return scheme === 'Bearer' && value ? value.trim() : null;
}
