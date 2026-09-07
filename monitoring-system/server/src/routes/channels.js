import { Router } from 'express';
import { asyncHandler } from '../middleware/error.js';
import { requireAuth, adminRequired } from '../middleware/auth.js';
import { channelSchema } from '../validation.js';
import {
  listChannels, createChannel, updateChannel, deleteChannel,
} from '../services/channelService.js';

export const channelsRouter = Router();

// Public — the reception kiosk fetches the channel list without logging in.
channelsRouter.get('/', asyncHandler(async (req, res) => {
  res.json(await listChannels(req.query.all !== '1'));
}));

channelsRouter.post('/', requireAuth, adminRequired, asyncHandler(async (req, res) => {
  const r = await createChannel(channelSchema.parse(req.body || {}));
  res.status(r.status).json(r.body);
}));

channelsRouter.put('/:id(\\d+)', requireAuth, adminRequired, asyncHandler(async (req, res) => {
  res.json(await updateChannel(Number(req.params.id), channelSchema.parse(req.body || {})));
}));

channelsRouter.delete('/:id(\\d+)', requireAuth, adminRequired, asyncHandler(async (req, res) => {
  res.json(await deleteChannel(Number(req.params.id)));
}));
