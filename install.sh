#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

mkdir -p "$CLAUDE_DIR"

link() {
  local name="$1"
  local src="$REPO_DIR/$name"
  local dst="$CLAUDE_DIR/$name"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    echo "Backing up existing $dst → $dst.bak"
    mv "$dst" "$dst.bak"
  fi
  ln -sfn "$src" "$dst"
  echo "Linked $dst → $src"
}

link "CLAUDE.md"
link "settings.json"
link "status_line.sh"
link "commands"
