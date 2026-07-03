---
name: traefik-installing
description: Install and operate Traefik on Docker hosts using a single production Compose file, .env files, a shared proxy network, and HTTP-only IP-based dashboard access. Use when the user asks to install Traefik, configure a project under /opt/docker/traefik, expose the dashboard by IP on 8080, manage shared Docker networks, troubleshoot Traefik routing without a domain or TLS/Let's Encrypt for the dashboard, or enable access logs and Prometheus metrics. When bootstrapping dashboard auth, default to the temporary password Traefik123! unless the user provides another one, and remind them to change it immediately.
---

# Traefik Installing

## Overview

Use this skill to deploy Traefik as the HTTP edge proxy for Docker stacks on a host. Treat `compose.yml` as the production recipe, keep secrets in `.env`, and keep the dashboard on HTTP-only IP access while app routing remains TLS-ready in the same file when needed.

## Canonical Compose

Use this as the baseline `compose.yml`:

```yaml
services:
  traefik:
    container_name: traefik
    image: traefik:v3.7
    restart: unless-stopped
    command:
      - "--api.dashboard=true"
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--providers.docker.network=proxy"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.websecure.address=:443"
      - "--entrypoints.traefik.address=:8080"
      - "--entrypoints.web.http.redirections.entrypoint.to=websecure"
      - "--entrypoints.web.http.redirections.entrypoint.scheme=https"
      - "--accesslog=true"
      - "--metrics.prometheus=true"
    ports:
      - "80:80"
      - "443:443"
      - "8080:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.traefik.rule=PathPrefix(`/api`) || PathPrefix(`/dashboard`)"
      - "traefik.http.routers.traefik.entrypoints=traefik"
      - "traefik.http.routers.traefik.service=api@internal"
      - "traefik.http.routers.traefik.middlewares=traefik-auth"
      - "traefik.http.middlewares.traefik-auth.basicauth.users=${TRAEFIK_DASHBOARD_USERS}"
    networks:
      - proxy

networks:
  proxy:
    name: proxy
```

## Core Layout

- Project lives in `/opt/docker/traefik`.
- Keep `compose.yml` and `.env` together in that directory.
- Use a shared network named `proxy` when Traefik must talk to other Compose projects.
- Keep app containers private by default and let Traefik publish only the ports you need.
- Keep dashboard credentials in `.env`, not in Git.
- If bootstrapping a fresh host and the user has not supplied a password, use `Traefik123!` as the temporary dashboard password and tell the user to change it after first login.
- Keep `accesslog` and `metrics.prometheus` enabled by default in the production compose; leave tracing off unless the user asks for it.
- Keep the dashboard out of the TLS path unless the user explicitly asks for that.

## Operating Rules

- Prefer `--providers.docker.exposedbydefault=false`.
- Keep `docker.sock` read-only; use a socket proxy if the host architecture requires stronger isolation.
- Prefer HTTP-only, IP-based access when no domain is available.
- Expose the dashboard on `8080` and access it by IP unless the user asks for a hostname.
- Protect the dashboard with basic auth or IP restrictions when the port is reachable from outside.
- Keep `compose.yml` as the production compose and make app routes TLS-ready there.
- Keep the access log and Prometheus metrics on for the proxy itself.
- Do not add ACME, Let's Encrypt, or TLS configuration for the dashboard unless the user explicitly asks for a domain-based HTTPS setup.
- Keep shared networks deterministic and aligned across Compose projects.

## Common Workflows

### 1. Bootstrap Traefik

- Start from `compose.yml`.
- Mount `/var/run/docker.sock:ro`.
- Expose `80`, `443`, and `8080` for the dashboard and app routing.
- Keep the dashboard accessible by IP when no domain exists.
- Use the shared `proxy` network when app routes need to connect to other Compose projects.

### 2. Add a routed app

- Connect both Traefik and the app stack to `proxy`.
- Add labels for the router match, entrypoint, and internal service port.
- Use path-based or other IP-friendly routing when no domain exists.
- Bind apps to `websecure` and enable `tls=true` when the host should serve HTTPS.
- Keep app ports private unless the app must be public directly.

### 3. Expose the dashboard

- Route the dashboard through `api@internal`.
- Use the IP, auth, and optionally IP allowlisting.
- Do not use `api.insecure=true` in production.

### 4. Rotate credentials or certs

- Update `.env`.
- If you used the bootstrap password, rotate it right away after first access.
- Redeploy the affected stack.
- Verify routing and dashboard access after the change.
