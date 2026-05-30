# Skills

Collection of reusable Codex skills for server and deployment work.

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

## Skills

- [`server-provisioning`](./server-provisioning)
- [`docker-production-install`](./docker-production-install)
- [`install-ssh-authorized-key`](./install-ssh-authorized-key)
- [`alloy-docker-logs`](./alloy-docker-logs)
- [`install-caddy-on-server`](./install-caddy-on-server)
