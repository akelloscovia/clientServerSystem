#!/usr/bin/env bash
# Build the Flutter web client locally and push it to the VPS.
# Run from monitoring-system/client/ on a machine with the Flutter SDK.
#   ./deploy-web.sh
set -euo pipefail

VPS="root@188.166.8.72"
DEST="/var/www/MinisterReceptionSystem/flutter-web/"

flutter build web --base-href /app/
rsync -az --delete build/web/ "$VPS:$DEST"

echo "Deployed to http://188.166.8.72:9046/app/"
