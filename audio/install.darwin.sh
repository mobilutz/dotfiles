#!/bin/bash
# Installs the launchd agent of the audio topic and its sudoers rules.
# All host specific values come from the local config,
# see audio/audio.local.conf.example.

DOTFILES_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

. "$DOTFILES_ROOT/audio/config.sh"

mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"

# ---------------------------------------------------------------------------
# USB audio fix: restarts the audio daemons when a plugged in USB audio device
# never reaches CoreAudio, never while audio is in use
# ---------------------------------------------------------------------------

PLIST_SRC="$DOTFILES_ROOT/audio/com.user.fix-usb-audio.plist"
PLIST_DST="$HOME/Library/LaunchAgents/com.user.fix-usb-audio.plist"

# Inject the real dotfiles path into the plist
sed "s|DOTFILES_PATH|$DOTFILES_ROOT|g" "$PLIST_SRC" > "$PLIST_DST"
chmod 644 "$PLIST_DST"

launchctl bootout "gui/$UID/com.user.fix-usb-audio" 2>/dev/null || true
launchctl bootstrap "gui/$UID" "$PLIST_DST"

echo "  ✓ USB audio fix agent installed (log: ~/Library/Logs/fix-usb-audio.log)"

# Grant the two exact commands the script runs, not a killall wildcard: a
# wildcard would let any process running as this user kill any root daemon.
AUDIO_SUDOERS_FILE="/etc/sudoers.d/fix-usb-audio"
AUDIO_SUDOERS_CONTENT="$(
  echo "$(whoami) ALL=(ALL) NOPASSWD: /usr/bin/killall usbaudiod"
  echo "$(whoami) ALL=(ALL) NOPASSWD: /usr/bin/killall coreaudiod"
)"

if [ "$(sudo cat "$AUDIO_SUDOERS_FILE" 2>/dev/null)" != "$AUDIO_SUDOERS_CONTENT" ]; then
  echo "$AUDIO_SUDOERS_CONTENT" | sudo tee "$AUDIO_SUDOERS_FILE" > /dev/null
  sudo chmod 440 "$AUDIO_SUDOERS_FILE"
  if ! sudo visudo -cf "$AUDIO_SUDOERS_FILE" > /dev/null; then
    sudo rm -f "$AUDIO_SUDOERS_FILE"
    echo "  ✗ Invalid sudoers rule for USB audio fix, removed again"
  else
    echo "  ✓ Passwordless sudo rule added for USB audio fix"
  fi
else
  echo "  ✓ Passwordless sudo rule for USB audio fix already exists"
fi

echo "  → Edit $AUDIO_CONF to change which USB audio devices are watched"
