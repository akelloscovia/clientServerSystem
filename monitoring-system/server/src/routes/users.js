import { Router } from 'express';
import { asyncHandler } from '../middleware/error.js';
import { requireAuth, adminRequired } from '../middleware/auth.js';
import { prisma } from '../db.js';
import { HttpError } from '../utils/httpError.js';
import { userDict } from '../utils/serialize.js';
import { registerSchema } from '../validation.js';
import { createStaffUser } from '../services/authService.js';
import { writeAudit } from '../services/audit.js';

export const usersRouter = Router();

const ROLES = ['user', 'admin', 'secretary'];

usersRouter.post('/', requireAuth, adminRequired, asyncHandler(async (req, res) => {
  const parsed = registerSchema.parse(req.body || {});
  const role = ((req.body && req.body.role) || 'secretary').trim();
  const r = await createStaffUser({ ...parsed, role }, req.user.id, req.ip);
  res.status(r.status).json(r.body);
}));

usersRouter.get('/', requireAuth, adminRequired, asyncHandler(async (req, res) => {
  const where = req.query.role ? { role: req.query.role } : {};
  const users = await prisma.users.findMany({ where, orderBy: { created_at: 'desc' } });
  res.json({ users: users.map(userDict) });
}));

usersRouter.get('/secretaries', requireAuth, adminRequired, asyncHandler(async (_req, res) => {
  const secretaries = await prisma.users.findMany({ where: { role: 'secretary', is_active: true } });
  res.json({ secretaries: secretaries.map(userDict) });
}));

usersRouter.get('/:id(\\d+)', requireAuth, adminRequired, asyncHandler(async (req, res) => {
  const user = await prisma.users.findUnique({ where: { id: Number(req.params.id) } });
  if (!user) throw new HttpError(404, 'Resource not found.');
  res.json({ user: userDict(user) });
}));

usersRouter.patch('/:id(\\d+)/role', requireAuth, adminRequired, asyncHandler(async (req, res) => {
  const newRole = req.body && req.body.role;
  if (!ROLES.includes(newRole)) {
    throw new HttpError(400, 'Invalid role. Must be user, admin, or secretary.');
  }
  const id = Number(req.params.id);
  const user = await prisma.users.findUnique({ where: { id } });
  if (!user) throw new HttpError(404, 'Resource not found.');
  const oldRole = user.role;
  const updated = await prisma.$transaction(async (tx) => {
    const u = await tx.users.update({ where: { id }, data: { role: newRole } });
    await writeAudit(tx, {
      userId: req.user.id, action: 'UPDATE_USER_ROLE', entityType: 'user', entityId: id,
      details: `${oldRole} -> ${newRole}`, ip: req.ip,
    });
    return u;
  });
  res.json({ message: `Role updated to '${newRole}'.`, user: userDict(updated) });
}));

usersRouter.patch('/:id(\\d+)/toggle-active', requireAuth, adminRequired, asyncHandler(async (req, res) => {
  const id = Number(req.params.id);
  const user = await prisma.users.findUnique({ where: { id } });
  if (!user) throw new HttpError(404, 'Resource not found.');
  if (user.id === req.user.id) {
    throw new HttpError(409, 'You cannot deactivate your own account.');
  }
  const nextActive = !user.is_active;
  const updated = await prisma.$transaction(async (tx) => {
    const u = await tx.users.update({ where: { id }, data: { is_active: nextActive } });
    await writeAudit(tx, {
      userId: req.user.id, action: 'TOGGLE_USER_ACTIVE', entityType: 'user', entityId: id,
      details: `is_active=${nextActive ? 'True' : 'False'}`, ip: req.ip,
    });
    return u;
  });
  const state = nextActive ? 'activated' : 'deactivated';
  res.json({ message: `User ${state}.`, user: userDict(updated) });
}));
