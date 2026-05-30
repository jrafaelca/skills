---
name: install-ssh-authorized-key
description: Install an SSH public key into a Linux user's authorized_keys safely and idempotently. Use when asked to add, install, append, replace, validate, or troubleshoot SSH keys for a server user such as ubuntu, deploy, github, or another Linux account.
---

# Install SSH Authorized Key

Install SSH public keys without deleting existing access. Use for deploy keys, GitHub Actions SSH access, or giving a user login access.

## Required Inputs

Ask if missing:

- SSH target, for example `ubuntu@1.2.3.4`
- SSH user, for example `ubuntu`
- SSH private key path, for example `~/.ssh/key.pem`
- target Linux user, for example `deploy`
- SSH public key text, starting with `ssh-ed25519`, `ssh-rsa`, or `ecdsa-sha2-*`

Optional:

- create user if missing; default no unless user asks
- replace all keys; default no, append only

## SSH Key Resolution

- If the user gives only a key name like `my-server.pem` or `id_ed25519`, assume `~/.ssh/<name>`.
- If the user gives no key path, prefer `~/.ssh/id_ed25519`, then `~/.ssh/id_rsa`.
- Do not invent a key path outside `~/.ssh` unless the user explicitly gives one.

## Safety Rules

- Never overwrite `authorized_keys` unless user explicitly asks to replace.
- Preserve existing keys.
- Deduplicate exact same public key.
- Set strict ownership and permissions.
- Validate access with a new SSH session before closing original session.
- Do not grant sudo unless user explicitly asks.

## Validate Public Key

Accept common public key prefixes:

```text
ssh-ed25519
ssh-rsa
ecdsa-sha2-nistp256
ecdsa-sha2-nistp384
ecdsa-sha2-nistp521
```

Reject private keys:

```text
-----BEGIN OPENSSH PRIVATE KEY-----
-----BEGIN RSA PRIVATE KEY-----
```

## Install Key

Run on server as a sudo-capable user:

```bash
set -euo pipefail

TARGET_USER="<USER>"
PUBLIC_KEY='<PUBLIC_KEY>'

if ! id "$TARGET_USER" >/dev/null 2>&1; then
  echo "User does not exist: $TARGET_USER" >&2
  exit 1
fi

USER_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"
if [ -z "$USER_HOME" ] || [ "$USER_HOME" = "/" ]; then
  echo "Invalid home for user: $TARGET_USER" >&2
  exit 1
fi

sudo install -d -o "$TARGET_USER" -g "$TARGET_USER" -m 700 "$USER_HOME/.ssh"
sudo touch "$USER_HOME/.ssh/authorized_keys"
sudo chown "$TARGET_USER:$TARGET_USER" "$USER_HOME/.ssh/authorized_keys"
sudo chmod 600 "$USER_HOME/.ssh/authorized_keys"

if ! sudo grep -Fxq "$PUBLIC_KEY" "$USER_HOME/.ssh/authorized_keys"; then
  printf '%s\n' "$PUBLIC_KEY" | sudo tee -a "$USER_HOME/.ssh/authorized_keys" >/dev/null
fi

sudo chown "$TARGET_USER:$TARGET_USER" "$USER_HOME/.ssh/authorized_keys"
sudo chmod 600 "$USER_HOME/.ssh/authorized_keys"
```

## Create User If Requested

Only if user explicitly asks:

```bash
if ! id "$TARGET_USER" >/dev/null 2>&1; then
  sudo adduser --disabled-password --gecos "" "$TARGET_USER"
fi
```

Then run install key flow.

## Replace Keys If Requested

Only if user explicitly asks to replace all keys:

```bash
printf '%s\n' "$PUBLIC_KEY" | sudo tee "$USER_HOME/.ssh/authorized_keys" >/dev/null
sudo chown "$TARGET_USER:$TARGET_USER" "$USER_HOME/.ssh/authorized_keys"
sudo chmod 600 "$USER_HOME/.ssh/authorized_keys"
```

## Validate

On server:

```bash
sudo ls -ld "$USER_HOME" "$USER_HOME/.ssh" "$USER_HOME/.ssh/authorized_keys"
sudo wc -l "$USER_HOME/.ssh/authorized_keys"
sudo grep -F "<KEY_COMMENT_OR_PREFIX>" "$USER_HOME/.ssh/authorized_keys" || true
sudo sshd -t
```

From local machine:

```bash
ssh -i <private-key> <user>@<host> 'id && hostname'
```

If SSH hardening uses `AllowUsers`, ensure target user appears:

```bash
sudo sshd -T | grep '^allowusers'
```
