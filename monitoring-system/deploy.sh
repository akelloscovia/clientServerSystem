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
git -C "$ROOT" pull --ff-only origin master

echo "==> server: install + prisma generate + restart"
cd "$APP/server"
npm install --no-audit --no-fund
npx prisma generate
pm2 restart minister-reception-api --update-env

echo "==> dashboard: install + build"
cd "$APP/dashboard"
npm install --no-audit --no-fund
npm run build

echo "==> done"
pm2 status minister-reception-api
