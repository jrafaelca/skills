---
name: jenkins-installing
description: Install and operate a Jenkins controller on Docker with a persistent volume, localhost-only forwarding, initial unlock, and SSH agents.
---

# Jenkins Installing

Use for a lightweight Jenkins controller on a host that already has Docker. Keep the controller small, persist data in Docker, and publish only a local port.

## Required Inputs

Ask only if missing:

- SSH target, for example `ubuntu@1.2.3.4`
- SSH user, for example `ubuntu`
- SSH private key path, for example `~/.ssh/key.pem`
- public Jenkins hostname, if the user wants one documented
- optional forwarded port; default `8080`

## Core Rules

- Use `jenkins/jenkins:lts-jdk21` unless the user explicitly wants a different tag.
- Bind Jenkins only to `127.0.0.1:${FORWARD_PORT:-8080}`.
- Do not add `container_name`.
- Keep Jenkins data in a Docker volume named `jenkins_home`.
- Do not expose Jenkins directly to the public internet.

## Compose

Create or update `compose.yaml`:

```yaml
services:
  jenkins:
    image: jenkins/jenkins:lts-jdk21
    restart: unless-stopped
    ports:
      - "127.0.0.1:${FORWARD_PORT:-8080}:8080"
    volumes:
      - jenkins_home:/var/jenkins_home

volumes:
  jenkins_home:
    name: jenkins_home
```

## Bootstrap

1. Start the stack with `docker compose up -d`.
2. Unlock Jenkins with:

```bash
docker compose exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

3. Install the suggested plugins unless the user wants a custom set.
4. Keep the controller for orchestration and UI; move heavy builds to agents.

## SSH Agents

Prefer SSH agents on remote hosts for heavier pipelines.

- Use a dedicated SSH credential in Jenkins.
- Launch agents via SSH.
- Label agents clearly, for example `linux-docker` or `prod-builder`.
- Ensure the agent host has Java and the runtime the pipeline needs.
- Keep the controller out of build-heavy work.

## Validation

```bash
docker compose config
docker compose ps
curl -I http://127.0.0.1:${FORWARD_PORT:-8080}/login
docker compose exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

## Notes

- Use the host proxy layer separately if the user wants HTTPS.
- Keep runtime data in the `jenkins_home` volume, not on the host filesystem.
- Use `FORWARD_PORT` only if the user wants to override the default port mapping.
