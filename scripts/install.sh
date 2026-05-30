#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST_DIR="${CODEX_HOME:-$HOME/.codex}/skills/fyxtrack"

mkdir -p "$DEST_DIR"
rsync -a --delete \
  --exclude '.git' \
  --exclude '.DS_Store' \
  "$ROOT_DIR/" \
  "$DEST_DIR/"

printf 'Installed skills to %s\n' "$DEST_DIR"
