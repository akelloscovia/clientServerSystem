import { Router } from 'express';
import { asyncHandler } from '../middleware/error.js';
import { requireAuth, staffRequired, activeUserRequired } from '../middleware/auth.js';
import { responseCreateSchema } from '../validation.js';
import { addResponse, getResponses } from '../services/responseService.js';

export const responsesRouter = Router();

responsesRouter.post('/', requireAuth, staffRequired, asyncHandler(async (req, res) => {
  const r = await addResponse(responseCreateSchema.parse(req.body || {}), req.user, req.ip);
  res.status(r.status).json(r.body);
}));

responsesRouter.get('/:submissionId(\\d+)', requireAuth, activeUserRequired, asyncHandler(async (req, res) => {
  res.json(await getResponses(Number(req.params.submissionId), req.user));
}));
