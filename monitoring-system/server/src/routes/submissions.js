import { Router } from 'express';
import { asyncHandler } from '../middleware/error.js';
import { requireAuth, activeUserRequired, staffRequired, adminRequired } from '../middleware/auth.js';
import { HttpError } from '../utils/httpError.js';
import { submissionCreateSchema, submissionUpdateSchema, assignmentSchema } from '../validation.js';
import {
  createSubmission, getSubmissions, getSubmission, getStatusHistory,
  updateStatus, deleteSubmission, assignSubmission, listAssignments,
} from '../services/submissionService.js';

export const submissionsRouter = Router();

/** Shared parsing of the list-filter query string. */
export function listParams(query) {
  const int = (v) => {
    if (v == null || v === '') return undefined;
    const n = Number(v);
    return Number.isFinite(n) ? Math.trunc(n) : undefined;
  };
  return {
    page: int(query.page) ?? 1,
    perPage: int(query.per_page) ?? 20,
    status: query.status || undefined,
    category: query.category || undefined,
    priority: query.priority || undefined,
    search: query.search || undefined,
    from: query.from ?? undefined,
    to: query.to ?? undefined,
    assignedTo: int(query.assigned_to) || undefined,
  };
}

submissionsRouter.post('/', requireAuth, activeUserRequired, asyncHandler(async (req, res) => {
  const r = await createSubmission(req.user.id, submissionCreateSchema.parse(req.body || {}), req.ip);
  res.status(r.status).json(r.body);
}));

submissionsRouter.get('/', requireAuth, activeUserRequired, asyncHandler(async (req, res) => {
  res.json(await getSubmissions(req.user, listParams(req.query)));
}));

submissionsRouter.get('/assignments', requireAuth, staffRequired, asyncHandler(async (req, res) => {
  res.json(await listAssignments(req.user));
}));

submissionsRouter.get('/user', requireAuth, asyncHandler(async (req, res) => {
  if (!req.user.is_active) throw new HttpError(403, 'Account is inactive');
  const p = listParams(req.query);
  const result = await getSubmissions(req.user, {
    page: p.page, perPage: p.perPage,
  });
  res.json({
    user: { id: req.user.id, email: req.user.email, name: req.user.name },
    submissions: result.submissions,
    total: result.total,
    pages: result.pages,
    page: p.page,
  });
}));

submissionsRouter.post('/assign', requireAuth, adminRequired, asyncHandler(async (req, res) => {
  res.json(await assignSubmission(assignmentSchema.parse(req.body || {}), req.user, req.ip));
}));

submissionsRouter.get('/:id(\\d+)', requireAuth, activeUserRequired, asyncHandler(async (req, res) => {
  res.json(await getSubmission(Number(req.params.id), req.user));
}));

submissionsRouter.patch('/:id(\\d+)/status', requireAuth, staffRequired, asyncHandler(async (req, res) => {
  const { status } = submissionUpdateSchema.parse(req.body || {});
  res.json(await updateStatus(Number(req.params.id), status, req.user, req.ip));
}));

submissionsRouter.delete('/:id(\\d+)', requireAuth, adminRequired, asyncHandler(async (req, res) => {
  res.json(await deleteSubmission(Number(req.params.id), req.user, req.ip));
}));

submissionsRouter.get('/:id(\\d+)/status-history', requireAuth, activeUserRequired, asyncHandler(async (req, res) => {
  res.json(await getStatusHistory(Number(req.params.id), req.user));
}));
