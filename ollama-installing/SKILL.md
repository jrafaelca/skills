---
name: ollama-installing
description: Create or harden Ollama Docker Compose deployments on servers, using the official image and explicit model pulls.
---

# Ollama Installing

## Overview

Use the official `ollama/ollama` image and keep the stack simple unless the user explicitly asks for more services or customization. Prefer Compose-first deployments with persistent storage, predictable defaults, and explicit model installation after the container is up.

## Workflow

1. Start from the existing `compose.yml` and preserve repo conventions.
2. Default to `linux/arm64` for Apple Silicon and AWS Graviton.
3. Prefer a simple `compose.yml` with hardcoded defaults unless the user explicitly wants overrides.
4. Mount persistent storage at `/root/.ollama` for the official image.
5. Pull models explicitly after the service starts.

```bash
docker compose up -d
docker compose exec ollama ollama pull qwen2.5:0.5b
```

6. For server installs, place the stack under `/home/automation/ollama` and keep the Compose file self-contained unless the user asks for `.env`.
7. Expose Ollama through a reverse proxy for public access. Avoid publishing it directly unless the user explicitly wants that.
8. Add a `Dockerfile` only when the user explicitly asks for non-root execution or image customization.

## Hardening

- Put authentication in the proxy layer, not in Ollama.
- Prefer private networking or localhost between Ollama and the proxy.
- Keep restart policy and persistent volume enabled.
- Add or keep a healthcheck, then verify the final Compose config.
- If the stack is being mirrored onto a server, copy the repo `compose.yml` into `/home/automation/ollama/compose.yaml` and avoid introducing a separate `.env` unless the user requests overrides.

## Validation

Use these checks after edits:

```bash
docker compose config
docker compose ps
docker compose exec ollama ollama list
docker compose exec ollama ollama run qwen2.5:0.5b
```

## Repo Updates

When the user asks to apply the workflow to the repo, update the Compose file and README together. Only add `.env` / `.env.example` when the workflow explicitly uses overrides.
