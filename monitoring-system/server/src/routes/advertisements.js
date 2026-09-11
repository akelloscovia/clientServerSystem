import { Router } from 'express';
import { asyncHandler } from '../middleware/error.js';
import { requireAuth, staffRequired } from '../middleware/auth.js';
import { advertisementSchema } from '../validation.js';
import {
  listAdvertisements, createAdvertisement, updateAdvertisement, deleteAdvertisement,
} from '../services/advertisementService.js';

export const advertisementsRouter = Router();

advertisementsRouter.get('/', asyncHandler(async (req, res) => {
  res.json(await listAdvertisements(req.query.all !== '1'));
}));

advertisementsRouter.post('/', requireAuth, staffRequired, asyncHandler(async (req, res) => {
  const result = await createAdvertisement(advertisementSchema.parse(req.body || {}), req.user.id);
  res.status(result.status).json(result.body);
}));

advertisementsRouter.put('/:id(\\d+)', requireAuth, staffRequired, asyncHandler(async (req, res) => {
  res.json(await updateAdvertisement(Number(req.params.id), advertisementSchema.parse(req.body || {})));
}));

advertisementsRouter.delete('/:id(\\d+)', requireAuth, staffRequired, asyncHandler(async (req, res) => {
  res.json(await deleteAdvertisement(Number(req.params.id)));
}));
