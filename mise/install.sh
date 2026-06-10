#!/usr/bin/env bash
#
# mise config installer.
#
# The base bootstrap only handles `*.symlink` files at depth 2 (mapped to
# `$HOME/.<name>`), which can't place files inside `~/.config/mise/`. This
# script symlinks the tracked config.toml into the correct location.

set -e

DOTFILES_MISE="$(cd "$(dirname "$0")" && pwd -P)"
TARGET_DIR="$HOME/.config/mise"
TARGET="$TARGET_DIR/config.toml"

mkdir -p "$TARGET_DIR"

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

link "$DOTFILES_MISE/global.toml" "$TARGET"
