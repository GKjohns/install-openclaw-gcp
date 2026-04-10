#!/usr/bin/env bash
set -euo pipefail

ZONE="${1:-us-west1-b}"
INSTANCE="${2:-openclaw-gateway}"
LOCAL_PORT="${3:-19000}"

echo "Opening SSH tunnel: localhost:${LOCAL_PORT} -> ${INSTANCE}:18789"
echo "Open http://127.0.0.1:${LOCAL_PORT}/ in your browser"
echo "Press Ctrl+C to close the tunnel"
echo ""

gcloud compute ssh "$INSTANCE" --zone="$ZONE" \
  -- -N -L "${LOCAL_PORT}:127.0.0.1:18789"
