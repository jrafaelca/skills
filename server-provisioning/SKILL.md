---
name: server-provisioning
description: Provision or harden a new Ubuntu host with apt upgrades, unattended upgrades, host-RAM swap sizing, SSH hardening, fail2ban, automation user creation, authorized_keys setup, and access validation.
---

# Server Provisioning

Use for fresh servers. Do not install Grafana, Loki, Prometheus, or app stacks here unless user explicitly asks.

## Required Inputs

Ask only if missing:

- SSH target, for example `ubuntu@1.2.3.4`
- SSH user, for example `ubuntu`
- SSH private key path, for example `~/.ssh/key.pem`
- automation public key source: copy current `ubuntu` key, paste GitHub public key, or path to local `.pub`
- whether to enable UFW; default no if security groups already control access

## SSH Key Resolution

- If the user gives only a key name like `my-server.pem` or `id_ed25519`, assume `~/.ssh/<name>`.
- If the user gives no key path, prefer `~/.ssh/id_ed25519`, then `~/.ssh/id_rsa`.
- Do not invent a key path outside `~/.ssh` unless the user explicitly gives one.

## Safety Rules

- Keep current admin user reachable.
- If adding `AllowUsers`, include both `ubuntu` and `automation`.
- Validate SSH config with `sshd -t` before reload.
- Do not disable sudo for `ubuntu`.
- Do not give `automation` sudo unless user explicitly asks.
- Prefer idempotent commands.

## Workflow

1. Inspect server.
2. Update packages.
3. Enable unattended upgrades.
4. Create swap sized from host RAM.
5. Install and configure fail2ban.
6. Create `automation`.
7. Configure automation SSH.
8. Harden SSH.
9. Validate access and services.

## Inspect

```bash
ssh -i <pem> <user>@<host> 'set -euo pipefail
. /etc/os-release
echo "$PRETTY_NAME $VERSION_CODENAME"
id
id automation 2>&1 || true
grep -E '^MemTotal:' /proc/meminfo || true
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

mem_mb="$(awk '/MemTotal/ { print int($2 / 1024) }' /proc/meminfo)"
if [ "$mem_mb" -le 4096 ]; then
  swap_size="2G"
elif [ "$mem_mb" -le 8192 ]; then
  swap_size="4G"
else
  swap_size="8G"
fi

if ! swapon --show | grep -q '^'; then
  sudo fallocate -l "$swap_size" /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  grep -q '^/swapfile none swap sw 0 0$' /etc/fstab || echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab >/dev/null
fi

sudo tee /etc/apt/apt.conf.d/20auto-upgrades >/dev/null <<'APTCONF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
APTCONF
sudo dpkg-reconfigure -f noninteractive unattended-upgrades || true

if ! id automation >/dev/null 2>&1; then
  sudo adduser --disabled-password --gecos "" automation
fi

sudo install -d -o automation -g automation -m 700 /home/automation/.ssh
sudo cp /home/ubuntu/.ssh/authorized_keys /home/automation/.ssh/authorized_keys
sudo chown automation:automation /home/automation/.ssh/authorized_keys
sudo chmod 600 /home/automation/.ssh/authorized_keys

sudo install -d -o automation -g automation -m 0755 /home/automation/services
sudo install -d -o automation -g automation -m 0755 /home/automation/apps

sudo tee /home/automation/README.md >/dev/null <<'AUTOREADME'
# automation

This home directory is reserved for the automation operator user.

## Layout

- `services/`: infrastructure and service stacks managed on this host, for example Jenkins.
- `apps/`: application checkouts and deployment working trees for app hosts.

## Conventions

- Keep host-level service files under `services/<service>`.
- Keep application deployment trees under `apps/<app>`.
- Use Docker volumes for runtime data; store only operational files here.
- Jenkins on a services host should live under `services/jenkins`.
- Jenkins data stays in Docker volumes, not under this home directory.
AUTOREADME

sudo chown automation:automation /home/automation/README.md

sudo install -d -m 0755 /run/sshd
sudo tee /etc/ssh/sshd_config.d/99-position-hardening.conf >/dev/null <<'SSHCONF'
PermitRootLogin no
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
PubkeyAuthentication yes
AllowUsers ubuntu automation
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
id automation
sudo ls -ld /home/automation /home/automation/.ssh /home/automation/.ssh/authorized_keys /home/automation/services /home/automation/apps /home/automation/README.md
sudo sshd -T | grep -E '^(permitrootlogin|passwordauthentication|kbdinteractiveauthentication|pubkeyauthentication|allowusers)'
sudo fail2ban-client status sshd || true
cat /etc/apt/apt.conf.d/20auto-upgrades
swapon --show
free -h
```

Also test a new SSH connection before closing the original session:

```bash
ssh -i <pem> automation@<host> 'id && hostname'
```
