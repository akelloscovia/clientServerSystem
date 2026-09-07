import { Router } from 'express';
import { asyncHandler } from '../middleware/error.js';
import { requireAuth, requireRefresh, activeUserRequired } from '../middleware/auth.js';
import { prisma } from '../db.js';
import { HttpError } from '../utils/httpError.js';
import { signAccess } from '../utils/jwt.js';
import { userDict } from '../utils/serialize.js';
import { registerSchema, loginSchema } from '../validation.js';
import { registerUser, loginUser, userPortalAccess } from '../services/authService.js';

export const authRouter = Router();

authRouter.post('/register', asyncHandler(async (req, res) => {
  const r = await registerUser(registerSchema.parse(req.body || {}), req.ip);
  res.status(r.status).json(r.body);
}));

authRouter.post('/login', asyncHandler(async (req, res) => {
  const r = await loginUser(loginSchema.parse(req.body || {}), req.ip);
  res.status(r.status).json(r.body);
}));

authRouter.post('/refresh', requireRefresh, asyncHandler(async (req, res) => {
  const user = await prisma.users.findUnique({ where: { id: Number(req.auth.sub) } });
  if (!user) throw new HttpError(404, 'User not found.');
  if (!user.is_active) throw new HttpError(403, 'Account is disabled.');
  res.json({ access_token: signAccess(user) });
}));

authRouter.get('/me', requireAuth, activeUserRequired, (req, res) => {
  res.json({ user: userDict(req.user) });
});

authRouter.post('/user-portal', asyncHandler(async (req, res) => {
  const r = await userPortalAccess(req.body || {});
  res.status(r.status).json(r.body);
}));
