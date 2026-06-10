---
name: caddy-installing
description: Install Caddy as the per-host reverse proxy for local upstreams, including subdomain routing and path routing.
---

# Caddy Installing

Use this skill when setting up Caddy on a host that runs app containers locally. The goal is one Caddy per server, not one shared proxy for many projects.

## Required Inputs

Ask only if missing:

- SSH target, for example `ubuntu@1.2.3.4`
- SSH user, for example `ubuntu`
- SSH private key path, for example `~/.ssh/key.pem`

## SSH Key Resolution

- If the user gives only a key name like `my-server.pem` or `id_ed25519`, assume `~/.ssh/<name>`.
- If the user gives no key path, prefer `~/.ssh/id_ed25519`, then `~/.ssh/id_rsa`.
- Do not invent a key path outside `~/.ssh` unless the user explicitly gives one.

## Core rule

- Keep Caddy outside the app compose file.
- Proxy only to `127.0.0.1` upstreams on the same server.
- Expose only the app ports the server actually needs.

## Pick a routing style

Choose one:

- Subdomains:
  - `textbee.example.com` -> web
  - `api.example.com` -> API
- IP + path:
  - `http://32.195.43.162/textbee`
  - `http://32.195.43.162/textbee-api`

## App requirements

- Web app must know its public base path when using IP + path.
- API and web must publish local host ports if Caddy runs on the host.
- Internal services like MongoDB stay unexposed unless needed.

## Caddyfile patterns

Subdomain:

```caddyfile
textbee.example.com {
  encode zstd gzip
  reverse_proxy 127.0.0.1:3002
}

api.example.com {
  encode zstd gzip
  reverse_proxy 127.0.0.1:3001
}
```

IP + path:

```caddyfile
http://32.195.43.162 {
  encode zstd gzip

  handle_path /textbee-api/* {
    reverse_proxy 127.0.0.1:3001
  }

  handle_path /textbee/* {
    reverse_proxy 127.0.0.1:3002
  }
}
```

## Deployment checklist

1. Install Caddy on the server.
2. Put the app stack on the same host.
3. Publish only the local ports Caddy needs.
4. Point Caddy at `127.0.0.1`.
5. Set public URLs in env:
   - `NEXT_PUBLIC_SITE_URL`
   - `NEXT_PUBLIC_API_BASE_URL`
   - `FRONTEND_URL`
   - `API_BASE_URL`
   - `NEXT_PUBLIC_BASE_PATH` when using a subpath
6. Reload Caddy and verify the public URL.

## Validation

- Check Caddy logs.
- Curl the local upstreams first.
- Then test the public URL.
- If routing by path, verify assets, auth redirects, and API calls still resolve under the subpath.
