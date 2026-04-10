# Troubleshooting

Common problems and fixes for OpenClaw on GCP.

## Problem reference

| Problem | Cause | Fix |
|---------|-------|-----|
| `gcloud compute ssh` hangs | VM still booting or SSH keys not propagated | Wait 1-2 minutes after VM creation and retry |
| `ZONE_RESOURCE_POOL_EXHAUSTED` | No GCP capacity in the chosen zone | Try a different zone (e.g., `us-central1-a`) |
| Docker image pull fails with exit 137 (OOM) | Not enough RAM | Use `e2-medium` (4 GB). `e2-small` is too small. |
| `curl: (7) Failed to connect to 127.0.0.1 port 18789` on VM | Container hasn't finished starting | Wait 2-3 minutes, check `docker ps` |
| Browser shows "unauthorized" or "token missing" | Gateway token not provided | Paste the token. Get it with `sudo docker exec openclaw-gw printenv OPENCLAW_GATEWAY_TOKEN` |
| Browser shows "pairing required" | First-time device authorization | SSH to VM, check pending devices (see below), restart container |
| Browser shows "origin not allowed" | Tunnel port not in allowed origins | Add origin to `controlUi.allowedOrigins` in `~/.openclaw/openclaw.json`, restart |
| Tunnel says "bind: Address already in use" | Local port conflict | Use a different local port: `-L 19000:127.0.0.1:18789` |
| `/v1/models` returns 404 | HTTP API disabled by default | Enable in gateway config (see optional-config.md) |
| "No API key found for provider" | Keys not in `.env` | Add keys to `~/.openclaw/.env`, restart container |
| `docker: permission denied` on VM | Docker group not applied | Exit and SSH back in |
| VM shows `TERMINATED` | VM was stopped | `gcloud compute instances start openclaw-gateway --zone=us-west1-b` |
| Billing not enabled error | No billing account linked | Link at https://console.cloud.google.com/billing |

## Handling "pairing required"

If the browser shows "pairing required" after entering the gateway token:

1. SSH into the VM in another terminal:
   ```bash
   gcloud compute ssh openclaw-gateway --zone=us-west1-b
   ```

2. Check for pending device requests:
   ```bash
   sudo docker exec openclaw-gw cat /home/node/.openclaw/devices/pending.json
   ```

3. Restart the container to process pending requests:
   ```bash
   sudo docker restart openclaw-gw
   ```

4. Wait a minute, then refresh the browser and try connecting again.

## Diagnostic commands

Run these from the VM to diagnose issues:

```bash
# Container status
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' --filter name=openclaw

# Container logs (last 100 lines)
sudo docker logs openclaw-gw --tail 100

# Health check
curl -fsS http://127.0.0.1:18789/healthz

# Readiness check
curl -fsS http://127.0.0.1:18789/readyz

# Check config file
cat ~/.openclaw/openclaw.json

# Check env file (API keys)
cat ~/.openclaw/.env

# Check disk space
df -h

# Check memory
free -h
```

## Container paths

| Host path | Container path | Purpose |
|-----------|---------------|---------|
| `~/.openclaw/` | `/home/node/.openclaw/` | Config directory |
| `~/.openclaw/devices/` | `/home/node/.openclaw/devices/` | Device authorization state |
