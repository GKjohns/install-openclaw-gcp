# Day-to-Day Operations

Commands for managing the OpenClaw gateway after installation. All run from your local machine via SSH.

## Health check

```bash
gcloud compute ssh openclaw-gateway --zone=us-west1-b \
  --command="curl -fsS http://127.0.0.1:18789/healthz && echo"
```

## Container status

```bash
gcloud compute ssh openclaw-gateway --zone=us-west1-b \
  --command="sudo docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}' --filter name=openclaw"
```

## View logs

```bash
gcloud compute ssh openclaw-gateway --zone=us-west1-b \
  --command="sudo docker logs openclaw-gw --tail 50"
```

Change `50` to however many lines needed.

## Restart the gateway

```bash
gcloud compute ssh openclaw-gateway --zone=us-west1-b \
  --command="sudo docker restart openclaw-gw"
```

The gateway can take 2-3 minutes to become healthy after a restart. Poll with:
```bash
gcloud compute ssh openclaw-gateway --zone=us-west1-b \
  --command="curl -s http://127.0.0.1:18789/healthz"
```

## Open a tunnel

```bash
gcloud compute ssh openclaw-gateway --zone=us-west1-b \
  -- -N -L 19000:127.0.0.1:18789
```

Then open `http://127.0.0.1:19000/` and paste the token.

## SSH into the VM

```bash
gcloud compute ssh openclaw-gateway --zone=us-west1-b
```

## Update OpenClaw

SSH into the VM, then:
```bash
sudo docker pull ghcr.io/openclaw/openclaw:latest
sudo docker restart openclaw-gw
```

## Start a stopped VM

If the VM was stopped (manually or by GCP):
```bash
gcloud compute instances start openclaw-gateway --zone=us-west1-b
```

Wait 1-2 minutes, then verify the container auto-started:
```bash
gcloud compute ssh openclaw-gateway --zone=us-west1-b \
  --command="docker ps --filter name=openclaw"
```

If the container didn't start, start it manually:
```bash
gcloud compute ssh openclaw-gateway --zone=us-west1-b \
  --command="sudo docker start openclaw-gw"
```
