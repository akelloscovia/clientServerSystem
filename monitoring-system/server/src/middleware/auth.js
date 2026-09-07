import { prisma } from '../db.js';
import { HttpError } from '../utils/httpError.js';
import { bearer, verifyToken } from '../utils/jwt.js';
import { asyncHandler } from './error.js';

const ROLES = ['user', 'admin', 'secretary'];

/**
 * Verify the access token and attach `req.user` (the DB row) and `req.auth`
 * (the decoded claims). Mirrors flask_jwt_extended's @jwt_required().
 */
export const requireAuth = asyncHandler(async (req, _res, next) => {
  const token = bearer(req);
  if (!token) throw new HttpError(401, undefined, { msg: 'Missing Authorization Header' });

  let claims;
  try {
    claims = verifyToken(token);
  } catch (e) {
    const msg = e.name === 'TokenExpiredError' ? 'Token has expired' : 'Invalid token';
    throw new HttpError(401, undefined, { msg });
  }
  if (claims.type === 'refresh') {
    throw new HttpError(401, undefined, { msg: 'Only non-refresh tokens are allowed' });
  }

  const user = await prisma.users.findUnique({ where: { id: Number(claims.sub) } });
  if (!user) throw new HttpError(404, 'User not found.');

  req.auth = claims;
  req.user = user;
  next();
});

/**
 * Same as requireAuth but for the refresh endpoint — requires a refresh token.
 */
export const requireRefresh = asyncHandler(async (req, _res, next) => {
  const token = bearer(req);
  if (!token) throw new HttpError(401, undefined, { msg: 'Missing Authorization Header' });

  let claims;
  try {
    claims = verifyToken(token);
  } catch (e) {
    const msg = e.name === 'TokenExpiredError' ? 'Token has expired' : 'Invalid token';
    throw new HttpError(401, undefined, { msg });
  }
  if (claims.type !== 'refresh') {
    throw new HttpError(401, undefined, { msg: 'Only refresh tokens are allowed' });
  }
  req.auth = claims;
  next();
});

/**
 * Role gate. Reproduces app/utils/permissions.py::roles_required — checks the
 * role set first, then the active flag.
 */
export function requireRoles(...roles) {
  return (req, _res, next) => {
    const user = req.user;
    if (!user || !roles.includes(user.role)) {
      return next(new HttpError(403, 'Insufficient permissions.'));
    }
    if (!user.is_active) {
      return next(new HttpError(403, 'Account is disabled.'));
    }
    next();
  };
}

export const adminRequired = requireRoles('admin');
export const staffRequired = requireRoles('admin', 'secretary');
export const activeUserRequired = requireRoles(...ROLES);
