# Monitoring System — API Server

Node.js REST API for the monitoring system. Express for routing, Prisma as the
ORM over MySQL/MariaDB, JWT auth (`jsonwebtoken`), password hashing with
`bcryptjs`, request validation with `zod`.

Rewritten from the original Python/Flask server — the HTTP contract is
unchanged, so the Flutter client and the React dashboard talk to it without
modification.

## Requirements

- Node.js 18+
- MySQL or MariaDB with a `monitoring_system` database

## Setup

```bash
npm install
cp .env.example .env        # then edit DATABASE_URL etc. (or edit .env directly)
npx prisma generate         # generate the Prisma client from prisma/schema.prisma
npm run seed                # default accounts + sample kiosk data (idempotent)
npm run dev                 # http://localhost:5000  (nodemon auto-reload; npm start for no-watch)
```

### Environment (`.env`)

| Var | Default | Notes |
|-----|---------|-------|
| `DATABASE_URL` | — | `mysql://user:pass@host:3306/monitoring_system` (plain `mysql://`, not `mysql+pymysql://`) |
| `PORT` | `5000` | |
| `NODE_ENV` | `development` | |
| `CORS_ORIGINS` | `*` | comma-separated list, or `*` |
| `JWT_SECRET` | `jwt-dev-secret` | |
| `JWT_ACCESS_TTL` | `3600` | access-token lifetime, seconds |
| `JWT_REFRESH_TTL` | `2592000` | refresh-token lifetime, seconds |

## Pusher live notifications

Copy the Pusher values from the Pusher Channels app into the server `.env`:

```env
PUSHER_APP_ID=...
PUSHER_KEY=...
PUSHER_SECRET=...
PUSHER_CLUSTER=...
```

Put the public `PUSHER_KEY` and `PUSHER_CLUSTER` in the dashboard `.env` as
`VITE_PUSHER_KEY` and `VITE_PUSHER_CLUSTER`. The server authenticates each
private `private-user-{id}` channel with the logged-in JWT. Staff can send
notifications from the Staff Messages page; notifications are also stored in
the database, so they are not lost when a recipient is offline. Visitor
creation and status changes are also published on the public
`visitor-updates` channel as `visitor.updated`, allowing reception and
minister kiosk views to refresh immediately.

## The database schema

`prisma/schema.prisma` was generated with `npx prisma db pull` against the
existing database, then hand-tuned (readable relation names, Prisma-level
`@default` / `@updatedAt`). The DB columns themselves are unchanged.

- Re-introspect after a manual DB change: `npm run prisma:pull` then re-add the
  defaults/relation names, then `npm run prisma:generate`.
- This project does **not** use `prisma migrate` — the schema is owned by the
  database.

## Layout

```
prisma/schema.prisma     data model
src/
  index.js               process entry — starts the HTTP server
  app.js                 builds the Express app, mounts routers at /api and /api/v1
  config.js  db.js       env config; shared PrismaClient
  middleware/            auth (JWT + role gates), error formatting
  utils/                 jwt, date formatting, response serializers, HttpError
  validation.js          zod schemas
  services/              business logic (one module per domain)
  routes/                thin Express routers -> services
seed.js                  seed script
```

## API groups

Everything is mounted under both `/api/<group>` and `/api/v1/<group>`:
`auth`, `submissions`, `responses`, `monitoring`, `users`, `visitors`,
`programs`, `channels`. Plus `GET /api/health` and a legacy `GET /api/` alias of
the submissions list.
