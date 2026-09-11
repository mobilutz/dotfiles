#!/bin/bash
# Links the Marta configuration into the app's support directory.
# Marta reads its config from ~/Library/Application Support/org.yanex.marta,
# not from $HOME, so the *.symlink convention does not apply here.

DOTFILES_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MARTA_DIR="$HOME/Library/Application Support/org.yanex.marta"

mkdir -p "$MARTA_DIR"

for file in conf.marco favorites.marco; do
  src="$DOTFILES_ROOT/marta/$file"
  dst="$MARTA_DIR/$file"

  if [ -L "$dst" ]; then
    rm "$dst"
  elif [ -e "$dst" ]; then
    mv "$dst" "$dst.backup"
    echo "  ✓ Existing $file moved to $file.backup"
  fi

  ln -s "$src" "$dst"
  echo "  ✓ Linked $file"
done
