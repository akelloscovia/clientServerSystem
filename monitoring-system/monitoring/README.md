# Monitoring Dashboard

React + Vite admin dashboard for the monitoring system.

## Setup

```bash
npm install
npm run dev
```

Dashboard runs at: **http://localhost:5173**

## Accounts

| Role      | Email                    | Password        |
|-----------|--------------------------|-----------------|
| Admin     | admin@system.com         | Admin@123       |
| Secretary | secretary@system.com     | Secretary@123   |

> Note: Regular users cannot access this dashboard.

## Features

- 📊 **Dashboard** — Stats overview with charts (daily trend, category pie, priority bar)
- 📋 **Submissions** — Filterable case list with status and category filters
- 🔎 **Case Detail** — Full case view with status management, assignment, and response thread
- 👥 **Users** _(Admin only)_ — Manage user accounts and promote to secretary/admin
- 🔍 **Audit Logs** _(Admin only)_ — Full action trail with timestamps and IP addresses
