import express from 'express';
import cors from 'cors';

import { config } from './config.js';
import { notFoundHandler, errorHandler, asyncHandler } from './middleware/error.js';
import { requireAuth, activeUserRequired } from './middleware/auth.js';
import { getSubmissions } from './services/submissionService.js';

import { authRouter } from './routes/auth.js';
import { submissionsRouter, listParams } from './routes/submissions.js';
import { responsesRouter } from './routes/responses.js';
import { monitoringRouter } from './routes/monitoring.js';
import { usersRouter } from './routes/users.js';
import { visitorsRouter } from './routes/visitors.js';
import { programsRouter } from './routes/programs.js';
import { channelsRouter } from './routes/channels.js';
import { advertisementsRouter } from './routes/advertisements.js';
import Pusher from 'pusher';

const GROUPS = {
  auth: authRouter,
  submissions: submissionsRouter,
  responses: responsesRouter,
  monitoring: monitoringRouter,
  users: usersRouter,
  visitors: visitorsRouter,
  programs: programsRouter,
  channels: channelsRouter,
  advertisements: advertisementsRouter,
};

/** Build a fresh `/api`-style router (mounted at both /api and /api/v1). */
function buildApiRouter() {
  const api = express.Router();

  api.get('/health', (_req, res) => {
    res.json({ status: 'ok', service: 'monitoring-system' });
  });

  // Legacy alias older clients used before the /submissions prefix existed.
  api.get('/', requireAuth, activeUserRequired, asyncHandler(async (req, res) => {
    res.json(await getSubmissions(req.user, listParams(req.query)));
  }));

  for (const [name, router] of Object.entries(GROUPS)) {
    api.use(`/${name}`, router);
  }
  return api;
}

export function createApp() {
  const app = express();

  const origins = config.corsOrigins;
  app.use(cors({
    origin: origins.length === 1 && origins[0] === '*' ? true : origins,
    credentials: true,
  }));
  app.use(express.json({ limit: '5mb' }));

  app.post('/api/pusher/auth', requireAuth, activeUserRequired, asyncHandler(async (req, res) => {
    if (!config.pusher.appId || !config.pusher.key || !config.pusher.secret) {
      throw new Error('Pusher is not configured on the server.');
    }
    const channelName = String(req.body?.channel_name || '');
    const expectedChannel = `private-user-${req.user.id}`;
    if (channelName !== expectedChannel) throw new Error('Invalid private channel.');
    const pusher = new Pusher({
      appId: config.pusher.appId,
      key: config.pusher.key,
      secret: config.pusher.secret,
      cluster: config.pusher.cluster,
      useTLS: true,
    });
    res.send(pusher.authenticate(req.body.socket_id, channelName));
  }));

  app.use('/api/v1', buildApiRouter());
  app.use('/api', buildApiRouter());

  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
}
