# install-openclaw-gcp

A [Claude Code skill](https://code.claude.com/docs/en/skills) that walks you through deploying an [OpenClaw](https://docs.openclaw.ai) gateway on Google Cloud Platform.

You end up with a Debian 12 VM running OpenClaw in Docker, accessible from your local machine through an SSH tunnel. No public internet exposure.

## Install

Clone into your Claude Code skills directory:

```bash
# Personal (available across all projects)
git clone https://github.com/GKjohns/install-openclaw-gcp.git ~/.claude/skills/install-openclaw-gcp

# Or project-level (shared via version control)
git clone https://github.com/GKjohns/install-openclaw-gcp.git .claude/skills/install-openclaw-gcp
```

## Usage

In Claude Code, invoke with:

```
/install-openclaw-gcp
```

Or just ask Claude something like "help me set up OpenClaw on GCP" and it will pick up the skill automatically.

The skill covers the full process:

1. Installing and authenticating the `gcloud` CLI
2. Creating a GCP project with Compute Engine enabled
3. Provisioning an `e2-medium` VM (Debian 12, 20 GB disk)
4. Installing Docker
5. Running the OpenClaw setup script (image pull, onboarding, container start)
6. Verifying the gateway
7. Retrieving the gateway token
8. Connecting via SSH tunnel

## What's included

```
SKILL.md                          Core installation procedure
LICENSE.txt                       MIT license
reference/
  troubleshooting.md              Common problems and diagnostic commands
  optional-config.md              API keys, OpenAI-compatible HTTP API
  day-to-day.md                   Health checks, logs, restarts, updates
scripts/
  health-check.sh                 Check gateway health via SSH
  tunnel.sh                       Open SSH tunnel to the gateway
  vm-logs.sh                      View container logs
```

## Prerequisites

- A Google Cloud account with billing enabled
- ~15-30 minutes

## Tested

This skill was tested with a full from-scratch deployment on GCP (April 2026). The container naming, port bindings, allowed-origins behavior, and docker compose commands all reflect what the setup script actually produces.

## Links

- [OpenClaw Docs](https://docs.openclaw.ai)
- [Claude Code Skills](https://code.claude.com/docs/en/skills)
- [GCP Compute Engine](https://cloud.google.com/compute)
