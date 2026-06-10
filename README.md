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
2. `docker-installing`
3. `ssh-key-installing`
4. `jenkins-installing`
5. `alloy-installing`
6. `caddy-installing`

## Safety

- Do not store IPs, usernames, PEM files, private keys, tokens, or passwords in the skills.
- Ask for connection details at runtime.
- Keep examples generic and redact real infrastructure values.
- If a user gives only a key name, assume `~/.ssh/<name>`.
- If no key path is given, prefer `~/.ssh/id_ed25519`, then `~/.ssh/id_rsa`.

## Skills

- [`server-provisioning`](./server-provisioning)
- [`docker-installing`](./docker-installing)
- [`ssh-key-installing`](./ssh-key-installing)
- [`jenkins-installing`](./jenkins-installing)
- [`alloy-installing`](./alloy-installing)
- [`caddy-installing`](./caddy-installing)
