#!/bin/bash
# Installs the launchd agent that fixes the local network route bug

DOTFILES_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLIST_SRC="$DOTFILES_ROOT/network/com.user.fix-local-route.plist"
PLIST_DST="$HOME/Library/LaunchAgents/com.user.fix-local-route.plist"

# Inject the real dotfiles path into the plist
sed "s|DOTFILES_PATH|$DOTFILES_ROOT|g" "$PLIST_SRC" > "$PLIST_DST"

# Load the agent
launchctl unload "$PLIST_DST" 2>/dev/null
launchctl load "$PLIST_DST"

echo "  ✓ Local network route fix agent installed"

# Set up passwordless sudo for the route delete command
SUDOERS_FILE="/etc/sudoers.d/fix-route"
SUDOERS_LINE="$(whoami) ALL=(ALL) NOPASSWD: /sbin/route delete 10.0.0.0/23"

if ! sudo grep -qF "$SUDOERS_LINE" "$SUDOERS_FILE" 2>/dev/null; then
  echo "$SUDOERS_LINE" | sudo tee "$SUDOERS_FILE" > /dev/null
  sudo chmod 440 "$SUDOERS_FILE"
  echo "  ✓ Passwordless sudo rule added for route fix"
else
  echo "  ✓ Passwordless sudo rule already exists"
fi
