# Monitoring System

A full-stack case/submission monitoring system with three tiers:

```
USER (Flutter App)  →  Node.js REST API (Express + Prisma)  →  MySQL / MariaDB
                                   ↑
                     Admin / Secretary Dashboard (React + Vite)
```

The API and the dashboard are both JavaScript; the mobile/web client is Flutter.

## Components

| Component | Path | Technology |
|-----------|------|-----------|
| Client | `client/` | Flutter (Dart) |
| REST API | `server/` | Node.js, Express, Prisma, MySQL |
| Dashboard | `dashboard/` | React + Vite |

## Quick Start

### 1. Server (Node API)

```bash
cd server
npm install
npx prisma generate          # generate the Prisma client
# Edit .env — DATABASE_URL points at your MySQL/MariaDB instance
npm run seed                  # create the default accounts + sample data
npm run dev                   # or: npm start
```

Server starts at **http://localhost:5000**. See [server/README.md](server/README.md)
for details.

### 2. Dashboard (React)

```bash
cd dashboard
npm install
npm run dev
```

Dashboard starts at **http://localhost:5173** (proxies `/api` to the server).

### 3. Flutter Client

```bash
cd client
flutter pub get
flutter run                   # or: flutter run -d chrome --no-web-resources-cdn
```

## Default Accounts

`npm run seed` in `server/` creates:

| Role | Email | Password |
|------|-------|----------|
| Admin | `admin@system.com` | `Admin@123` |
| Secretary | `secretary@system.com` | `Secretary@123` |
| User | `user@example.com` | `User@1234` |

## Documentation

- [System Architecture](docs/system-architecture.md)
- [API Documentation](docs/api-documentation.md)
- [Database Design](docs/database-design.md)
