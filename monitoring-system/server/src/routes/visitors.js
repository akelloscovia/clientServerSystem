import { Router } from 'express';
import { asyncHandler } from '../middleware/error.js';
import { requireAuth, staffRequired, adminRequired } from '../middleware/auth.js';
import {
  visitorCreateSchema, visitorStatusSchema, visitorAssignSchema, visitorReplySchema,
} from '../validation.js';
import {
  createVisitor, getVisitors, getVisitor, updateVisitorStatus,
  assignVisitor, addReply, deleteVisitor,
} from '../services/visitorService.js';

export const visitorsRouter = Router();

// Public — the reception-kiosk QR form posts here with no login.
visitorsRouter.post('/', asyncHandler(async (req, res) => {
  const r = await createVisitor(visitorCreateSchema.parse(req.body || {}));
  res.status(r.status).json(r.body);
}));

visitorsRouter.get('/', requireAuth, staffRequired, asyncHandler(async (req, res) => {
  const toInt = (v, dflt) => {
    const n = Number(v);
    return v != null && v !== '' && Number.isInteger(n) ? n : dflt;
  };
  res.json(await getVisitors(
    toInt(req.query.page, 1), toInt(req.query.per_page, 20), req.query.status || undefined,
  ));
}));

visitorsRouter.get('/:id(\\d+)', requireAuth, staffRequired, asyncHandler(async (req, res) => {
  res.json(await getVisitor(Number(req.params.id)));
}));

visitorsRouter.patch('/:id(\\d+)/status', requireAuth, staffRequired, asyncHandler(async (req, res) => {
  const { status } = visitorStatusSchema.parse(req.body || {});
  res.json(await updateVisitorStatus(Number(req.params.id), status));
}));

visitorsRouter.post('/:id(\\d+)/assign', requireAuth, adminRequired, asyncHandler(async (req, res) => {
  const { assigned_to } = visitorAssignSchema.parse(req.body || {});
  res.json(await assignVisitor(Number(req.params.id), assigned_to, req.user));
}));

visitorsRouter.post('/:id(\\d+)/replies', requireAuth, staffRequired, asyncHandler(async (req, res) => {
  const { message } = visitorReplySchema.parse(req.body || {});
  const r = await addReply(Number(req.params.id), req.user.id, message);
  res.status(r.status).json(r.body);
}));

visitorsRouter.delete('/:id(\\d+)', requireAuth, adminRequired, asyncHandler(async (req, res) => {
  res.json(await deleteVisitor(Number(req.params.id)));
}));
