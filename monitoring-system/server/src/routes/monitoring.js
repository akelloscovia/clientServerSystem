import { Router } from 'express';
import { asyncHandler } from '../middleware/error.js';
import { requireAuth, adminRequired, activeUserRequired } from '../middleware/auth.js';
import { HttpError } from '../utils/httpError.js';
import { getStats, getAuditLogs } from '../services/monitoringService.js';
import { getNotifications, markRead, markAllRead } from '../services/notificationService.js';

export const monitoringRouter = Router();

monitoringRouter.get('/stats', requireAuth, adminRequired, asyncHandler(async (_req, res) => {
  res.json(await getStats());
}));

monitoringRouter.get('/audit-logs', requireAuth, adminRequired, asyncHandler(async (req, res) => {
  const toInt = (v, dflt) => {
    const n = Number(v);
    return v != null && v !== '' && Number.isInteger(n) ? n : dflt;
  };
  const page = toInt(req.query.page, 1);
  const perPage = toInt(req.query.per_page, 50);
  if (page < 1 || perPage < 1 || perPage > 100) {
    throw new HttpError(400, 'page must be >= 1 and per_page must be between 1 and 100.');
  }
  res.json(await getAuditLogs(page, perPage));
}));

monitoringRouter.get('/notifications', requireAuth, activeUserRequired, asyncHandler(async (req, res) => {
  res.json(await getNotifications(req.user.id));
}));

monitoringRouter.patch('/notifications/read-all', requireAuth, activeUserRequired, asyncHandler(async (req, res) => {
  res.json(await markAllRead(req.user.id));
}));

monitoringRouter.patch('/notifications/:id(\\d+)/read', requireAuth, activeUserRequired, asyncHandler(async (req, res) => {
  res.json(await markRead(Number(req.params.id), req.user.id));
}));
