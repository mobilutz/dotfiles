#!/usr/bin/env bash
#
# Claude Code config installer.
#
# The base bootstrap only handles `*.symlink` files at depth 2 (mapped to
# `$HOME/.<name>`), which can't place files inside `~/.claude/`. This script
# symlinks each tracked file into the correct location under `~/.claude/`,
# and seeds `settings.local.json` from the example on first run.

set -e

DOTFILES_CLAUDE="$(cd "$(dirname "$0")" && pwd -P)"
TARGET="$HOME/.claude"

mkdir -p "$TARGET/agents"

link () {
  local src="$1"
  local dst="$2"

  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "  [ OK ] $dst already linked"
    return
  fi

  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "$dst.backup.$(date +%s)"
    echo "  [WARN] backed up existing $dst"
  fi

  ln -sfn "$src" "$dst"
  echo "  [ OK ] linked $dst"
}

link "$DOTFILES_CLAUDE/CLAUDE.md"             "$TARGET/CLAUDE.md"
link "$DOTFILES_CLAUDE/settings.json"         "$TARGET/settings.json"
link "$DOTFILES_CLAUDE/statusline-command.sh" "$TARGET/statusline-command.sh"

# Link every agent in claude/agents/ — no need to enumerate them here.
shopt -s nullglob
for agent in "$DOTFILES_CLAUDE"/agents/*; do
  link "$agent" "$TARGET/agents/$(basename "$agent")"
done
shopt -u nullglob

# Seed settings.local.json (machine-local secrets, never linked back into the repo)
LOCAL="$TARGET/settings.local.json"
if [ ! -e "$LOCAL" ]; then
  cp "$DOTFILES_CLAUDE/settings.local.json.example" "$LOCAL"
  echo "  [WARN] created $LOCAL — fill in your MCP API keys"
fi
