#!/usr/bin/env bash
#
# Claude Code config installer.
#
# The base bootstrap only handles `*.symlink` files at depth 2 (mapped to
# `$HOME/.<name>`), which can't place files inside `~/.claude/`. This script
# symlinks each tracked file into the correct location under `~/.claude/`.
#
# `settings.json` is the exception: it is generated, not linked, by merging the
# public settings in this repo with the `settings.local.json` overlay from the
# separate ~/.dotfiles-private repo. That keeps work-specific entries (private
# plugin marketplaces and the plugins from them) out of this public repo.
#
# Note that Claude Code itself does not read a `settings.local.json` next to
# `~/.claude/settings.json` — its `local` tier is per-project
# (`<project>/.claude/settings.local.json`). The overlay is merged here at
# install time instead of being left for Claude Code to pick up.

set -e

DOTFILES_CLAUDE="$(cd "$(dirname "$0")" && pwd -P)"
TARGET="$HOME/.claude"
LOCAL_SETTINGS="$HOME/.dotfiles-private/claude/settings.local.json"
SETTINGS_SNAPSHOT="$TARGET/.settings.generated.json"

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

# Deep-merges the local overlay over the public settings. Objects merge
# key-by-key, arrays are replaced wholesale by the overlay.
generate_settings () {
  local dst="$TARGET/settings.json"
  local tmp="$dst.new.$$"

  if ! command -v jq >/dev/null; then
    echo "  [FAIL] jq is required to generate $dst" >&2
    return 1
  fi

  if [ -f "$LOCAL_SETTINGS" ]; then
    jq -s '.[0] * .[1]' "$DOTFILES_CLAUDE/settings.json" "$LOCAL_SETTINGS" > "$tmp"
  else
    jq . "$DOTFILES_CLAUDE/settings.json" > "$tmp"
  fi

  # Anything that differs from what we generated last time was hand-edited
  # (e.g. by /config), so keep a copy before overwriting it.
  if [ -e "$dst" ] && [ ! -L "$dst" ] && ! cmp -s "$dst" "$SETTINGS_SNAPSHOT"; then
    cp "$dst" "$dst.backup.$(date +%s)"
    echo "  [WARN] backed up hand-edited $dst"
  fi

  cp "$tmp" "$SETTINGS_SNAPSHOT"
  rm -f "$dst"
  mv "$tmp" "$dst"

  if [ -f "$LOCAL_SETTINGS" ]; then
    echo "  [ OK ] generated $dst (public + local overlay)"
  else
    echo "  [ OK ] generated $dst (public only, no $LOCAL_SETTINGS)"
  fi
}

link "$DOTFILES_CLAUDE/CLAUDE.md"             "$TARGET/CLAUDE.md"
link "$DOTFILES_CLAUDE/statusline-command.sh" "$TARGET/statusline-command.sh"

generate_settings

# Link every agent in claude/agents/ — no need to enumerate them here.
shopt -s nullglob
for agent in "$DOTFILES_CLAUDE"/agents/*; do
  link "$agent" "$TARGET/agents/$(basename "$agent")"
done
shopt -u nullglob

if [ ! -f "$LOCAL_SETTINGS" ]; then
  echo "  [WARN] no $LOCAL_SETTINGS — copy claude/settings.local.json.example there for work-specific settings"
fi
