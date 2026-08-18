# Migrations

This directory contains Flask-Migrate (Alembic) migration files.

## Initialize (first time only)

```bash
cd server
flask db init
flask db migrate -m "initial schema"
flask db upgrade
```

## After model changes

```bash
flask db migrate -m "describe your change"
flask db upgrade
```
