---
name: ollama-compose
description: Production Docker Compose workflows for Ollama. Use when creating, updating, or hardening Ollama deployments on Linux, Apple Silicon, or AWS Graviton, including official-image Compose stacks, .env overrides, manual model pulls, reverse proxies, and repo updates.
---

# Ollama Compose

## Overview

Use the official `ollama/ollama` image and keep the stack simple unless the user explicitly asks for more services or customization. Prefer Compose-first deployments with persistent storage, predictable defaults, and explicit model installation after the container is up.

## Workflow

1. Start from the existing `compose.yml` and preserve repo conventions.
2. Default to `linux/arm64` for Apple Silicon and AWS Graviton.
3. Keep tunables in `.env` with sensible defaults: forwarded port, container name, restart policy, and volume name.
4. Mount persistent storage at `/root/.ollama` for the official image.
5. Pull models explicitly after the service starts.

```bash
docker compose up -d
docker compose exec ollama ollama pull qwen2.5:0.5b
```

6. Expose Ollama through a reverse proxy for public access. Avoid publishing it directly unless the user explicitly wants that.
7. Add a `Dockerfile` only when the user explicitly asks for non-root execution or image customization.

## Hardening

- Put authentication in the proxy layer, not in Ollama.
- Prefer private networking or localhost between Ollama and the proxy.
- Keep restart policy and persistent volume enabled.
- Add or keep a healthcheck, then verify the final Compose config.

## Validation

Use these checks after edits:

```bash
docker compose config
docker compose ps
docker compose exec ollama ollama list
docker compose exec ollama ollama run qwen2.5:0.5b
```

## Repo Updates

When the user asks to apply the workflow to the repo, update the Compose file, `.env`, `.env.example`, and README together so the docs match the runtime behavior.
