# Optional Configuration

Post-install configuration for API keys and the OpenAI-compatible HTTP API.

## Add API keys for model providers

The gateway needs API keys to talk to model providers. SSH into the VM and create a `.env` file:

```bash
gcloud compute ssh openclaw-gateway --zone=us-west1-b
```

```bash
cat > ~/.openclaw/.env << 'EOF'
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
GEMINI_API_KEY=AIza...
GROQ_API_KEY=gsk_...
EOF
```

Replace placeholders with real keys. Only include providers the user wants to use.

Restart the container:
```bash
cd ~/openclaw && docker compose restart openclaw-gateway
```

Wait a couple minutes, then verify:
```bash
curl -fsS http://127.0.0.1:18789/healthz
```

## Enable the OpenAI-compatible HTTP API

By default the gateway only exposes its native Control UI. To use OpenClaw as an OpenAI-compatible drop-in (Open WebUI, LobeChat, custom scripts), enable the HTTP API.

SSH into the VM and create or edit the gateway config:

```bash
cat > ~/.openclaw/openclaw.json << 'JSONEOF'
{
  "gateway": {
    "http": {
      "endpoints": {
        "chatCompletions": { "enabled": true }
      }
    }
  }
}
JSONEOF
```

If `~/.openclaw/openclaw.json` already exists, merge this into the existing JSON rather than overwriting.

Restart the container:
```bash
cd ~/openclaw && docker compose restart openclaw-gateway
```

### Available endpoints

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/v1/models` | List available models |
| POST | `/v1/chat/completions` | Chat completion (OpenAI format) |
| POST | `/v1/embeddings` | Embeddings |

### Testing the API

Through the SSH tunnel:

```bash
curl -fsS http://127.0.0.1:18789/v1/models \
  -H "Authorization: Bearer YOUR_GATEWAY_TOKEN"
```

Use `model: "openclaw/default"` as the model name. To force a specific backend, add the `x-openclaw-model` header:

```bash
curl -fsS http://127.0.0.1:18789/v1/chat/completions \
  -H "Authorization: Bearer YOUR_GATEWAY_TOKEN" \
  -H "Content-Type: application/json" \
  -H "x-openclaw-model: openai/gpt-5.4" \
  -d '{"model":"openclaw/default","messages":[{"role":"user","content":"Hello"}]}'
```
