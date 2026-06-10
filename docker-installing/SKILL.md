---
name: docker-installing
description: Install Docker and Compose on Ubuntu production hosts, add ubuntu and automation to the docker group, set json-file log rotation, and validate container access.
---

# Docker Installing

Use after base server provisioning. This skill installs Docker only; it does not deploy app stacks or monitoring suites.

## Required Inputs

Ask only if missing:

- SSH target, for example `ubuntu@1.2.3.4`
- SSH user, for example `ubuntu`
- SSH private key path, for example `~/.ssh/key.pem`
- users that need Docker access; default `ubuntu automation`
- Docker log limit; default `50m` and `1` file

## SSH Key Resolution

- If the user gives only a key name like `my-server.pem` or `id_ed25519`, assume `~/.ssh/<name>`.
- If the user gives no key path, prefer `~/.ssh/id_ed25519`, then `~/.ssh/id_rsa`.
- Do not invent a key path outside `~/.ssh` unless the user explicitly gives one.

## Rules

- Prefer Ubuntu repo packages on Ubuntu 26.04 unless user asks for Docker upstream repo.
- Configure log rotation before long-running app containers start.
- Restart Docker after writing `/etc/docker/daemon.json`.
- Warn that users may need a new SSH session for docker group membership.

## Install

```bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

sudo apt-get update

if ! command -v docker >/dev/null 2>&1; then
  sudo apt-get install -y docker.io
fi

if ! docker compose version >/dev/null 2>&1; then
  sudo apt-get install -y docker-compose-v2 || sudo apt-get install -y docker-compose-plugin
fi

sudo install -d -m 0755 /etc/docker
sudo tee /etc/docker/daemon.json >/dev/null <<'JSON'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m",
    "max-file": "1"
  }
}
JSON

sudo systemctl enable --now docker
sudo systemctl restart docker

sudo usermod -aG docker ubuntu
sudo usermod -aG docker automation
```

## Validate

```bash
docker version --format 'Docker {{.Server.Version}}'
docker compose version
cat /etc/docker/daemon.json
id ubuntu
id automation
docker info --format '{{.LoggingDriver}}'
```

For a container created after the daemon config:

```bash
docker inspect <container> --format '{{json .HostConfig.LogConfig}}'
```

Expected:

```json
{"Type":"json-file","Config":{"max-file":"1","max-size":"50m"}}
```

## Notes

- Existing containers keep old log settings until recreated.
- `docker compose up -d --force-recreate` applies new log opts to a project.
- Do not use `rm -rf /var/lib/docker` unless user explicitly requests destructive cleanup.
