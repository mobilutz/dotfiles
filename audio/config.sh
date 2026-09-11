#!/bin/bash
# Shared config loader for the "audio" topic.
# Source this, do not execute it. Exits the caller when no config is present,
# because the scripts in this topic restart system daemons and must not guess
# which devices they are allowed to act on.
#
# audio.local.conf holds the host specific values (which USB audio devices to
# watch). It is ignored by this public repo via the "*.local.*" rule and
# versioned in the private dotfiles repo instead.

AUDIO_TOPIC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUDIO_CONF="${AUDIO_CONF:-$AUDIO_TOPIC_DIR/audio.local.conf}"

if [ ! -r "$AUDIO_CONF" ]; then
  echo "audio: no config at $AUDIO_CONF" >&2
  echo "audio: copy audio/audio.local.conf.example there and fill in your values" >&2
  exit 78   # EX_CONFIG
fi

# shellcheck source=/dev/null
. "$AUDIO_CONF"

: "${WATCHED_USB_AUDIO_DEVICES:=}"
: "${MISSES_BEFORE_FIX:=2}"
: "${FIX_COOLDOWN:=300}"
: "${SETTLE_SECONDS:=3}"
: "${DRY_RUN:=0}"

# The product name is deliberately the only identifier in the config: macOS
# prints the exact same string in both places this script has to compare,
# the USB bus ("USB Product Name" in ioreg) and the CoreAudio device list
# (system_profiler SPAudioDataType). No VID/PID mapping table needed.
watched_devices() {
  printf '%s\n' "$WATCHED_USB_AUDIO_DEVICES" | sed '/^[[:space:]]*$/d'
}
