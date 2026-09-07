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

const GROUPS = {
  auth: authRouter,
  submissions: submissionsRouter,
  responses: responsesRouter,
  monitoring: monitoringRouter,
  users: usersRouter,
  visitors: visitorsRouter,
  programs: programsRouter,
  channels: channelsRouter,
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
  app.use(express.json());

  app.use('/api/v1', buildApiRouter());
  app.use('/api', buildApiRouter());

  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
}
