#!/bin/bash
# Sets up macOS screenshot behaviour:
#   - saves screenshots to ~/Pictures/Screenshots as JPG
#   - hides the floating thumbnail preview
#   - auto-copies each new screenshot to the system clipboard via a launchd agent

set -e

DOTFILES_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
PLIST_SRC="$DOTFILES_ROOT/screenshots/com.user.copy-screenshot-to-clipboard.plist"
PLIST_DST="$HOME/Library/LaunchAgents/com.user.copy-screenshot-to-clipboard.plist"

mkdir -p "$SCREENSHOT_DIR"
mkdir -p "$HOME/Library/LaunchAgents"

# Screenshot defaults
defaults write com.apple.screencapture location -string "$SCREENSHOT_DIR"
defaults write com.apple.screencapture type -string "jpg"
defaults write com.apple.screencapture show-thumbnail -bool false
defaults write com.apple.screencapture disable-shadow -bool true
defaults write com.apple.screencapture target -string "file"

# Inject paths into the plist (launchd does not expand $HOME or relative paths).
sed -e "s|DOTFILES_PATH|$DOTFILES_ROOT|g" \
    -e "s|SCREENSHOT_DIR|$SCREENSHOT_DIR|g" \
    "$PLIST_SRC" > "$PLIST_DST"

launchctl unload "$PLIST_DST" 2>/dev/null || true
launchctl load "$PLIST_DST"

killall SystemUIServer 2>/dev/null || true

echo "  ✓ Screenshot auto-copy-to-clipboard agent installed"
