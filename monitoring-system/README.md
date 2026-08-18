# Monitoring System

A full-stack case/submission monitoring system with three tiers:

```
USER (Flutter App)  →  Flask REST API  →  PostgreSQL
                              ↑
                    Admin / Secretary Dashboard (React)
```

## Components

| Component | Path | Technology |
|-----------|------|-----------|
| Mobile Client | `client/` | Flutter (Dart) |
| REST API | `server/` | Python Flask + PostgreSQL |
| Monitoring Dashboard | `monitoring/` | React + Vite |

## Quick Start

### 1. Server (Flask API)

```bash
cd server
python -m venv venv
venv\Scripts\activate       # Windows
pip install -r requirements.txt
# Edit .env with your database URL
flask db init
flask db migrate -m "initial"
flask db upgrade
python run.py
```

Server starts at: **http://localhost:5000**

### 2. Monitoring Dashboard (React)

```bash
cd monitoring
npm install
npm run dev
```

Dashboard starts at: **http://localhost:5173**

### 3. Flutter Client

```bash
cd client
flutter pub get
flutter run
```

## Default Admin Account

After running migrations, seed an admin:
```bash
cd server
python seed.py
```
- Email: `admin@system.com`
- Password: `Admin@123`

## Documentation

- [System Architecture](docs/system-architecture.md)
- [API Documentation](docs/api-documentation.md)
- [Database Design](docs/database-design.md)
