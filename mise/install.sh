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

# Interactive shells get mise via `mise activate` in zshrc, but non-interactive
# login shells (VS Code tasks, `zsh -l -c ...`) never source zshrc and end up
# without node/ruby/go on PATH. Put the shims into ~/.zprofile, which login
# shells do read, after /etc/zprofile has run path_helper.
ensure_zprofile_shims () {
  local zprofile="$HOME/.zprofile"
  local marker="# dotfiles: mise shims for non-interactive login shells"

  if [ -f "$zprofile" ] && grep -qF "$marker" "$zprofile"; then
    echo "  [ OK ] $zprofile already exports mise shims"
    return
  fi

  cat >> "$zprofile" <<'BLOCK'

# dotfiles: mise shims for non-interactive login shells (VS Code tasks, zsh -l -c)
export PATH="$HOME/.local/share/mise/shims:$PATH"
BLOCK

  echo "  [ OK ] added mise shims to $zprofile"
}

ensure_zprofile_shims
