---
name: install-openclaw-gcp
description: Install and deploy an OpenClaw gateway on Google Cloud Platform from scratch. Walks through GCP project setup, VM creation, Docker installation, OpenClaw deployment, SSH tunnel configuration, and verification. Use when setting up OpenClaw on GCP, creating a VM for an OpenClaw gateway, deploying OpenClaw to the cloud, or connecting to a remote OpenClaw instance.
---

# Install OpenClaw on GCP

Deploy an OpenClaw gateway on a GCP Debian 12 VM running Docker, accessible through an SSH tunnel. Docker compose binds the gateway to `0.0.0.0:18789` on the VM, but GCP's default firewall rules block all inbound traffic except SSH (port 22), so the gateway is not reachable from the public internet without explicit firewall changes.

**End state:** A running OpenClaw gateway you can reach from your local machine at `http://127.0.0.1:18789/` (or a custom local port) through an SSH tunnel.

**Time:** 15-30 minutes. **Prerequisites:** A Google Cloud account with billing enabled.

## Installation procedure

Walk the user through these steps in order. Each step includes verification commands; confirm each one succeeds before moving on.

### Step 1: Install and authenticate the gcloud CLI

Skip if the user already has `gcloud` installed and authenticated.

**macOS:**
```bash
brew install --cask google-cloud-sdk
```

**Linux (Debian/Ubuntu):**
```bash
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
sudo apt-get update && sudo apt-get install -y google-cloud-cli
```

**Windows:** Download from https://cloud.google.com/sdk/docs/install

Then authenticate:
```bash
gcloud auth login
```

**Verify:** `gcloud auth list` should show the account as ACTIVE.

### Step 2: Create and configure a GCP project

```bash
gcloud projects create openclaw-gateway --name="OpenClaw Gateway"
gcloud config set project openclaw-gateway
```

Project IDs are globally unique. If `openclaw-gateway` is taken, append a suffix (e.g., `openclaw-gateway-<username>`). Substitute the chosen ID in all subsequent commands.

Enable billing at https://console.cloud.google.com/billing then enable Compute Engine:

```bash
gcloud services enable compute.googleapis.com
```

**Verify:** `gcloud services list --enabled --filter="name:compute.googleapis.com"` returns one row.

### Step 3: Create the VM

```bash
gcloud compute instances create openclaw-gateway \
  --zone=us-west1-b \
  --machine-type=e2-medium \
  --boot-disk-size=20GB \
  --image-family=debian-12 \
  --image-project=debian-cloud
```

Key choices:
- `e2-medium` (2 vCPU, 4 GB RAM) is the minimum. `e2-small` (2 GB) can OOM during Docker image pulls.
- `us-west1-b` is the default zone. The user can pick another with `gcloud compute zones list`.
- 20 GB disk is sufficient for OS + Docker + OpenClaw image.

If `ZONE_RESOURCE_POOL_EXHAUSTED` occurs, try a different zone (e.g., `us-central1-a`, `us-east1-b`). Update the zone in all subsequent commands.

**Verify:**
```bash
gcloud compute instances describe openclaw-gateway \
  --zone=us-west1-b \
  --format="table(name, status, networkInterfaces[0].accessConfigs[0].natIP)"
```
Should show `RUNNING` status. Wait 1-2 minutes after creation before SSHing.

### Step 4: Install Docker on the VM

```bash
gcloud compute ssh openclaw-gateway --zone=us-west1-b
```

First SSH generates and registers a key pair. Accept any prompts.

On the VM:
```bash
sudo apt-get update
sudo apt-get install -y git curl ca-certificates
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
```

Exit and reconnect so the Docker group takes effect:
```bash
exit
gcloud compute ssh openclaw-gateway --zone=us-west1-b
```

**Verify:** `docker run --rm hello-world` should print "Hello from Docker!" without needing `sudo`. If permission denied, exit and reconnect again.

### Step 5: Install and start OpenClaw

On the VM:
```bash
git clone https://github.com/openclaw/openclaw.git
cd openclaw
mkdir -p ~/.openclaw ~/.openclaw/workspace
export OPENCLAW_IMAGE="ghcr.io/openclaw/openclaw:latest"
./scripts/docker/setup.sh
```

The setup script:
- Pulls the Docker image
- Runs onboarding (token generation, initial config)
- Starts the gateway via docker compose

The compose stack creates a container named `openclaw-openclaw-gateway-1` and binds ports 18789-18790 on the VM. The setup script prints the gateway token at the end. Save it.

The setup also configures `gateway.controlUi.allowedOrigins` to `["http://localhost:18789","http://127.0.0.1:18789"]`. If you tunnel to a different local port (e.g., 19000), you must add that origin to the allowlist (see Step 8).

This step takes several minutes for the image pull. Wait for it to finish.

### Step 6: Verify the gateway

On the VM:
```bash
curl -fsS http://127.0.0.1:18789/healthz
curl -fsS http://127.0.0.1:18789/readyz
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' --filter name=openclaw
```

Both curl commands should return successful JSON (`{"ok":true,"status":"live"}` and `{"ready":true}`). `docker ps` should show `openclaw-openclaw-gateway-1` with status `Up`. If they fail, the container may still be starting; wait 2-3 minutes and retry.

### Step 7: Retrieve the gateway token

The setup script prints the token at the end. If you need to retrieve it again:

```bash
docker exec openclaw-openclaw-gateway-1 printenv OPENCLAW_GATEWAY_TOKEN
```

Save this token securely. It grants full operator access.

Exit the VM:
```bash
exit
```

### Step 8: Connect from your local machine

Open an SSH tunnel from the local machine:
```bash
gcloud compute ssh openclaw-gateway --zone=us-west1-b \
  -- -N -L 18789:127.0.0.1:18789
```

`-N` keeps the tunnel open without an interactive shell. Leave this terminal running.

If local port 18789 is in use (e.g., a local OpenClaw instance), use a different port:
```bash
gcloud compute ssh openclaw-gateway --zone=us-west1-b \
  -- -N -L 19000:127.0.0.1:18789
```

**Important:** If you use a non-default tunnel port, you must add it to the gateway's allowed origins on the VM, or the Control UI will reject the connection with "origin not allowed":

```bash
gcloud compute ssh openclaw-gateway --zone=us-west1-b
```

On the VM, edit `~/.openclaw/openclaw.json` and add the tunnel origin to `gateway.controlUi.allowedOrigins`:
```json
"allowedOrigins": [
  "http://localhost:18789",
  "http://127.0.0.1:18789",
  "http://localhost:19000",
  "http://127.0.0.1:19000"
]
```

Then restart the container:
```bash
cd ~/openclaw && docker compose restart openclaw-gateway
```

Open `http://127.0.0.1:18789/` (or `:19000`) in a browser, paste the gateway token, and click Connect.

## Post-install configuration

After the gateway is running and accessible, the user may want to:

- **Add API keys** for model providers (OpenAI, Anthropic, etc.) - see [references/optional-config.md](references/optional-config.md)
- **Enable the OpenAI-compatible HTTP API** for use with Open WebUI, LobeChat, or custom scripts - see [references/optional-config.md](references/optional-config.md)
- **Day-to-day operations** (health checks, logs, restarts, updates) - see [references/day-to-day.md](references/day-to-day.md)
- **Troubleshooting** common problems - see [references/troubleshooting.md](references/troubleshooting.md)

## Quick reference

| Setting | Value |
|---------|-------|
| Machine type | `e2-medium` (2 vCPU, 4 GB RAM) |
| OS | Debian 12 |
| Boot disk | 20 GB |
| Gateway port | `18789` (bound to `0.0.0.0`, protected by GCP firewall) |
| Container name | `openclaw-openclaw-gateway-1` (docker compose) |
| Docker image | `ghcr.io/openclaw/openclaw:latest` |
| Config dir (VM) | `~/.openclaw/` |
| API keys file (VM) | `~/.openclaw/.env` |
| Gateway config (VM) | `~/.openclaw/openclaw.json` |
| Workspace (VM) | `~/.openclaw/workspace/` |
| Health endpoint | `GET /healthz` |
| Readiness endpoint | `GET /readyz` |

## Scripts

This skill includes helper scripts that can be run from your local machine:

- `scripts/health-check.sh` - Check gateway health via SSH
- `scripts/tunnel.sh` - Open an SSH tunnel to the gateway
- `scripts/vm-logs.sh` - View gateway container logs

All scripts accept `--zone` and `--instance` arguments to override defaults.
