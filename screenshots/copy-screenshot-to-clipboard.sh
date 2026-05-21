#!/bin/bash
# Triggered by launchd when ~/Pictures/Screenshots changes.
# Copies the newest screenshot file into the system clipboard so the
# standard screenshot shortcut produces both a saved file AND a clipboard image.
# Logs to ~/Library/Logs/copy-screenshot-to-clipboard.log for diagnostics.

set -u

DIR="$HOME/Pictures/Screenshots"
STATE="$HOME/.copy-screenshot-last"
LOG="$HOME/Library/Logs/copy-screenshot-to-clipboard.log"

[ -d "$DIR" ] || exit 0

# Newest image file in the folder (png/jpg/jpeg, case-insensitive).
NEWEST=$(/usr/bin/find "$DIR" -maxdepth 1 -type f \
  \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) \
  -print0 2>/dev/null \
  | xargs -0 ls -t 2>/dev/null \
  | head -1)

[ -n "$NEWEST" ] || exit 0

# Skip if we already copied this exact file (WatchPaths can fire multiple times).
LAST=$(cat "$STATE" 2>/dev/null || true)
[ "$NEWEST" = "$LAST" ] && exit 0

# macOS sometimes writes the screenshot atomically via rename; give it a moment
# to settle so we don't read a half-written file.
sleep 0.2

case "$NEWEST" in
  *.png|*.PNG) KIND='«class PNGf»' ;;
  *.jpg|*.JPG|*.jpeg|*.JPEG) KIND='JPEG picture' ;;
  *) exit 0 ;;
esac

if /usr/bin/osascript -e "set the clipboard to (read (POSIX file \"$NEWEST\") as $KIND)" 2>>"$LOG"; then
  echo "$NEWEST" > "$STATE"
  echo "$(date '+%Y-%m-%d %H:%M:%S') copied: $NEWEST" >> "$LOG"
else
  echo "$(date '+%Y-%m-%d %H:%M:%S') FAILED: $NEWEST" >> "$LOG"
fi
