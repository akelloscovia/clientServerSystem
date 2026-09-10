#!/usr/bin/env bash
# Pull the latest code and redeploy on the VPS.
#   ssh root@188.166.8.72 '/var/www/MinisterReceptionSystem/clientServerSystem/monitoring-system/deploy.sh'
#
# Schema changes are NOT applied automatically. If prisma/schema.prisma changed,
# run this once by hand afterwards:
#   cd .../monitoring-system/server && npx prisma db push
set -euo pipefail

ROOT="/var/www/MinisterReceptionSystem/clientServerSystem"
APP="$ROOT/monitoring-system"

echo "==> git pull"
# npm rewrites package-lock.json on install; discard that so --ff-only never trips
git -C "$ROOT" checkout -- monitoring-system/server/package-lock.json \
                            monitoring-system/dashboard/package-lock.json 2>/dev/null || true
git -C "$ROOT" pull --ff-only origin master

echo "==> server: install + prisma generate + restart"
cd "$APP/server"
npm ci --no-audit --no-fund
npx prisma generate
pm2 restart minister-reception-api --update-env

echo "==> dashboard: install + build"
cd "$APP/dashboard"
npm ci --no-audit --no-fund
npm run build

echo "==> done"
pm2 status minister-reception-api
