# Skills

Collection of reusable Codex skills for server and deployment work.

## Install

Install this repo into Codex's skills path with:

```bash
make install
```

That copies the repo into `${CODEX_HOME:-$HOME/.codex}/skills`.
It installs under `${CODEX_HOME:-$HOME/.codex}/skills/fyxtrack` to avoid overwriting other skills.

## Order

Recommended run order for server work:

1. `server-provisioning`
2. `docker-production-install`
3. `install-ssh-authorized-key`
4. `alloy-docker-logs`
5. `install-caddy-on-server`

## Safety

- Do not store IPs, usernames, PEM files, private keys, tokens, or passwords in the skills.
- Ask for connection details at runtime.
- Keep examples generic and redact real infrastructure values.
- If a user gives only a key name, assume `~/.ssh/<name>`.
- If no key path is given, prefer `~/.ssh/id_ed25519`, then `~/.ssh/id_rsa`.

## Skills

- [`server-provisioning`](./server-provisioning)
- [`docker-production-install`](./docker-production-install)
- [`install-ssh-authorized-key`](./install-ssh-authorized-key)
- [`alloy-docker-logs`](./alloy-docker-logs)
- [`install-caddy-on-server`](./install-caddy-on-server)
