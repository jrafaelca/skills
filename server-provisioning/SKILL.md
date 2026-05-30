---
name: server-provisioning
description: Provision a new Ubuntu production server for our Docker-based deploy flow. Use when asked to bootstrap or harden a fresh server with apt update/upgrade, unattended upgrades, SSH hardening, fail2ban, deploy user creation, deploy SSH authorized_keys, and base security checks before app deployments.
---

# Server Provisioning

Use for fresh servers. Do not install Grafana, Loki, Prometheus, app stacks, or Alloy here unless user explicitly asks. Pair with `docker-production-install` for Docker, and `alloy-docker-logs` for logs.

## Required Inputs

Ask only if missing:

- SSH target, for example `ubuntu@1.2.3.4`
- SSH user, for example `ubuntu`
- SSH private key path, for example `~/.ssh/key.pem`
- deploy public key source: copy current `ubuntu` key, paste GitHub deploy public key, or path to local `.pub`
- whether to enable UFW; default no if security groups already control access

## Safety Rules

- Keep current admin user reachable.
- If adding `AllowUsers`, include both `ubuntu` and `deploy`.
- Validate SSH config with `sshd -t` before reload.
- Do not disable sudo for `ubuntu`.
- Do not give `deploy` sudo unless user explicitly asks.
- Prefer idempotent commands.

## Workflow

1. Inspect server.
2. Update packages.
3. Enable unattended upgrades.
4. Install and configure fail2ban.
5. Create `deploy`.
6. Configure deploy SSH.
7. Harden SSH.
8. Validate access and services.

## Inspect

```bash
ssh -i <pem> <user>@<host> 'set -euo pipefail
. /etc/os-release
echo "$PRETTY_NAME $VERSION_CODENAME"
id
id deploy 2>&1 || true
sudo sshd -T 2>/dev/null | grep -E "^(permitrootlogin|passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication|allowusers)" || true
df -h /
'
```

## Bootstrap Commands

Run through SSH as `ubuntu` or another sudo-capable admin:

```bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y ca-certificates curl gnupg unattended-upgrades fail2ban

sudo tee /etc/apt/apt.conf.d/20auto-upgrades >/dev/null <<'APTCONF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
APTCONF
sudo dpkg-reconfigure -f noninteractive unattended-upgrades || true

if ! id deploy >/dev/null 2>&1; then
  sudo adduser --disabled-password --gecos "" deploy
fi

sudo install -d -o deploy -g deploy -m 700 /home/deploy/.ssh
sudo cp /home/ubuntu/.ssh/authorized_keys /home/deploy/.ssh/authorized_keys
sudo chown deploy:deploy /home/deploy/.ssh/authorized_keys
sudo chmod 600 /home/deploy/.ssh/authorized_keys

sudo install -d -m 0755 /run/sshd
sudo tee /etc/ssh/sshd_config.d/99-position-hardening.conf >/dev/null <<'SSHCONF'
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
PubkeyAuthentication yes
AllowUsers ubuntu deploy
SSHCONF
sudo sshd -t
sudo systemctl reload ssh || sudo systemctl reload sshd

sudo tee /etc/fail2ban/jail.d/sshd.local >/dev/null <<'JAIL'
[sshd]
enabled = true
port = ssh
maxretry = 5
findtime = 10m
bantime = 1h
backend = systemd
JAIL
sudo systemctl enable --now fail2ban
sudo systemctl restart fail2ban
```

## Validation

```bash
id deploy
sudo ls -ld /home/deploy /home/deploy/.ssh /home/deploy/.ssh/authorized_keys
sudo sshd -T | grep -E '^(permitrootlogin|passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication|allowusers)'
sudo fail2ban-client status sshd || true
cat /etc/apt/apt.conf.d/20auto-upgrades
```

Also test a new SSH connection before closing the original session:

```bash
ssh -i <pem> deploy@<host> 'id && hostname'
```
