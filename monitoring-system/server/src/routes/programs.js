import { Router } from 'express';
import { asyncHandler } from '../middleware/error.js';
import { requireAuth, staffRequired } from '../middleware/auth.js';
import { programSchema } from '../validation.js';
import {
  listPrograms, createProgram, updateProgram, deleteProgram,
} from '../services/programService.js';

export const programsRouter = Router();

// Public — the reception kiosk shows today's schedule without logging in.
programsRouter.get('/', asyncHandler(async (req, res) => {
  const activeOnly = req.query.all !== '1';
  res.json(await listPrograms(req.query.day || undefined, activeOnly));
}));

programsRouter.post('/', requireAuth, staffRequired, asyncHandler(async (req, res) => {
  const r = await createProgram(programSchema.parse(req.body || {}));
  res.status(r.status).json(r.body);
}));

programsRouter.put('/:id(\\d+)', requireAuth, staffRequired, asyncHandler(async (req, res) => {
  res.json(await updateProgram(Number(req.params.id), programSchema.parse(req.body || {})));
}));

programsRouter.delete('/:id(\\d+)', requireAuth, staffRequired, asyncHandler(async (req, res) => {
  res.json(await deleteProgram(Number(req.params.id)));
}));
