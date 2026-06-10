---
name: alloy-installing
description: Install Alloy on Docker hosts to collect container logs and forward them to Loki.
---

# Alloy Installing

Use on app servers that already run Docker. Do not install Grafana, Loki, Prometheus, or the monitoring stack here. Always ask for Loki push URL if missing.

## Required Inputs

Ask only if missing:

- SSH target, for example `ubuntu@1.2.3.4`
- SSH user, for example `ubuntu`
- SSH private key path, for example `~/.ssh/key.pem`
- Loki push URL, for example `http://ip-10-0-7-49.ec2.internal:3300/loki/api/v1/push`
- environment label; default `production`
- host label; default `hostname`

## SSH Key Resolution

- If the user gives only a key name like `my-server.pem` or `id_ed25519`, assume `~/.ssh/<name>`.
- If the user gives no key path, prefer `~/.ssh/id_ed25519`, then `~/.ssh/id_rsa`.
- Do not invent a key path outside `~/.ssh` unless the user explicitly gives one.

## Layout

```text
/home/automation/alloy/
├─ config.alloy
└─ compose.yaml
```

## Config

Create `/home/automation/alloy/config.alloy`:

```hcl
logging {
  level = "info"
  format = "logfmt"
}

discovery.docker "containers" {
  host = "unix:///var/run/docker.sock"
}

discovery.relabel "containers" {
  targets = discovery.docker.containers.targets

  rule {
    source_labels = ["__meta_docker_container_name"]
    regex = "/(.*)"
    target_label = "container"
  }

  rule {
    source_labels = ["__meta_docker_container_label_com_docker_compose_project"]
    target_label = "project_name"
  }

  rule {
    source_labels = ["__meta_docker_container_label_com_docker_compose_service"]
    target_label = "service_name"
  }

  rule {
    target_label = "platform"
    replacement = "docker"
  }

  rule {
    target_label = "host"
    replacement = "<HOSTNAME>"
  }

  rule {
    target_label = "environment"
    replacement = "<ENVIRONMENT>"
  }
}

loki.source.docker "containers" {
  host = "unix:///var/run/docker.sock"
  targets = discovery.relabel.containers.output
  forward_to = [loki.process.docker.receiver]
}

loki.process "docker" {
  stage.drop {
    older_than = "168h"
    drop_counter_reason = "too_old"
  }

  forward_to = [loki.write.default.receiver]
}

loki.write "default" {
  endpoint {
    url = "<LOKI_PUSH_URL>"
  }
}
```

## Compose

Create `/home/automation/alloy/compose.yaml`:

```yaml
services:
  alloy:
    image: grafana/alloy:latest
    container_name: alloy
    restart: unless-stopped
    ports:
      - "127.0.0.1:12345:12345"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./config.alloy:/etc/alloy/config.alloy:ro
      - alloy-data:/var/lib/alloy/data
    command:
      - run
      - --server.http.listen-addr=0.0.0.0:12345
      - --storage.path=/var/lib/alloy/data
      - /etc/alloy/config.alloy

volumes:
  alloy-data:
```

## Install

```bash
set -euo pipefail

sudo install -d -o automation -g automation -m 0755 /home/automation/alloy
# write config.alloy and compose.yaml
sudo chown alloy:alloy /home/automation/alloy/config.alloy /home/automation/alloy/compose.yaml
sudo chmod 0644 /home/automation/alloy/config.alloy /home/automation/alloy/compose.yaml

sudo -u automation sh -lc 'cd /home/automation/alloy && docker compose pull && docker compose up -d --remove-orphans'
```

## Validate

```bash
sudo -u automation sh -lc 'cd /home/automation/alloy && docker compose ps'
curl --max-time 5 -fsS http://127.0.0.1:12345/-/ready
sudo -u automation sh -lc 'cd /home/automation/alloy && docker compose logs --tail=80 alloy'
curl --max-time 5 -fsS <LOKI_READY_URL> || true
```

For Loki ready URL, convert push URL:

```text
http://host:port/loki/api/v1/push -> http://host:port/ready
```

## Grafana Queries

Use Loki labels:

```logql
{project_name="my-app", service_name="app"}
```

With logfmt app logs:

```logql
{project_name="my-app", service_name="app"} | logfmt | imei="865124078606938"
```

By event name when log line starts with `LEVEL event.name key=value`:

```logql
{project_name="my-app", service_name="app"} |= "device.imei.accepted" | logfmt
```

## Notes

- Alloy UI must stay bound to `127.0.0.1` unless user explicitly wants network access.
- Docker socket is read-only.
- `stage.drop older_than = "168h"` avoids sending stale Docker logs that Loki may reject.
- Existing app deployment flow stays unchanged; Alloy auto-discovers containers.
