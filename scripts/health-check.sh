#!/usr/bin/env bash
set -euo pipefail

ZONE="${1:-us-west1-b}"
INSTANCE="${2:-openclaw-gateway}"

echo "Checking gateway health on ${INSTANCE} (${ZONE})..."

gcloud compute ssh "$INSTANCE" --zone="$ZONE" \
  --command="curl -fsS http://127.0.0.1:18789/healthz && echo"

echo ""
echo "Checking readiness..."

gcloud compute ssh "$INSTANCE" --zone="$ZONE" \
  --command="curl -fsS http://127.0.0.1:18789/readyz && echo"

echo ""
echo "Container status:"

gcloud compute ssh "$INSTANCE" --zone="$ZONE" \
  --command="docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' --filter name=openclaw"
