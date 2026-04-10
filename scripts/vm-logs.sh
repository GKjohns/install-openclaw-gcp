#!/usr/bin/env bash
set -euo pipefail

ZONE="${1:-us-west1-b}"
INSTANCE="${2:-openclaw-gateway}"
LINES="${3:-50}"

echo "Fetching last ${LINES} log lines from ${INSTANCE} (${ZONE})..."
echo ""

gcloud compute ssh "$INSTANCE" --zone="$ZONE" \
  --command="sudo docker logs openclaw-gw --tail ${LINES}"
