#!/usr/bin/env bash
# Build the Flutter web client locally and push it to the VPS.
# Run from monitoring-system/client/ on a machine with the Flutter SDK.
#   ./deploy-web.sh
set -euo pipefail

VPS="root@188.166.8.72"
DEST="/var/www/MinisterReceptionSystem/flutter-web/"

flutter build web --base-href /app/ \
	--dart-define=VISITOR_FORM_BASE_URL=http://188.166.8.72:9046 \
	--dart-define=PUSHER_KEY="${PUSHER_KEY:-}" \
	--dart-define=PUSHER_CLUSTER="${PUSHER_CLUSTER:-mt1}"
rsync -az --delete build/web/ "$VPS:$DEST"

echo "Deployed to http://188.166.8.72:9046/app/"
