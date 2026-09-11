#!/bin/bash
# Recovers a USB audio device that macOS enumerated on the USB bus but never
# published to CoreAudio.
#
# The failure this addresses: usbaudiod accepts the XPC handoff from
# coreaudiod and then goes silent, so the device is fully matched in IOKit
# while no CoreAudio device is ever created. The headset is invisible to Teams
# and to System Settings > Sound while ioreg still shows it, and replugging
# does not help because the replug repeats the same wedged handoff. The log
# signature is a success path that simply stops:
#
#   (AppleUSBAudio) AppleUSBAudioDevice probe OverrideWantsHidden returned false
#   coreaudiod (usbaudiodxpc) usbaudioxpc matched a service
#   coreaudiod (usbaudiodxpc) usbaudioxpc starting session
#   usbaudiod  accepted XPC connection
#   <nothing further, no error, no timeout>
#
# Restarting the daemons clears it. The escalation order matters: killing
# usbaudiod alone re-runs the handoff without tearing down streams on other
# devices, so it is tried first. coreaudiod is only killed when that did not
# help, because afterwards every application re-picks its device and a running
# call loses its selection.
#
# Nothing is restarted while audio is actually in use. A wedged headset means
# any call is running on some other input, and killing the daemons underneath
# it would drop that too. The wedge persists until it is fixed, so waiting for
# the next quiet interval costs nothing.
#
# IMPORTANT: presence on the USB bus is not evidence that the device works.
# Both halves of the comparison are required. Restarting the audio daemons
# because a device is merely absent would fire constantly for every headset
# that is simply unplugged.
#
# Logs to ~/Library/Logs/fix-usb-audio.log. Set DRY_RUN=1 in the config to log
# findings without restarting anything.
#
# Usage:
#   fix-usb-audio.sh            check once, restart only if wedged and idle
#   fix-usb-audio.sh --now      ignore the idle guard and the cooldown
#   fix-usb-audio.sh --status   report what the checks currently see

set -uo pipefail

. "$(dirname "$0")/config.sh"

LOG="$HOME/Library/Logs/fix-usb-audio.log"
STATE_DIR="$HOME/.local/state/fix-usb-audio"
LAST_FIX="$STATE_DIR/last-fix"
mkdir -p "$(dirname "$LOG")" "$STATE_DIR"
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >>"$LOG"; }

FORCE=0
STATUS_ONLY=0
case "${1-}" in
  --now)    FORCE=1 ;;
  --status) STATUS_ONLY=1 ;;
  "")       ;;
  *)        echo "usage: $(basename "$0") [--now|--status]" >&2; exit 64 ;;
esac

# --- The two halves of the diagnosis -------------------------------------
# Read the CoreAudio device list once per run, it costs about 0.3s.
AUDIO_DEVICES=$(system_profiler SPAudioDataType 2>/dev/null)
USB_DEVICES=$(ioreg -w0 -l -c IOUSBHostDevice 2>/dev/null | grep '"USB Product Name"')

on_usb_bus() { printf '%s' "$USB_DEVICES" | grep -qF "\"$1\""; }
in_coreaudio() { printf '%s' "$AUDIO_DEVICES" | grep -qF "$1"; }

# --- Is audio in use right now -------------------------------------------
# coreaudiod holds a power assertion naming its audio resources for as long as
# a stream is live, and drops it when everything goes quiet. Absence of the
# assertion is the signal that a restart is safe.
audio_in_use() {
  pmset -g assertions 2>/dev/null | grep -q 'Resources:.*audio'
}

# --- Restart one daemon and give the handoff time to run again -----------
restart_daemon() {
  local daemon="$1"
  if [ "$DRY_RUN" = "1" ]; then
    log "DRY_RUN=1 - would restart $daemon"
    return 1
  fi
  if ! sudo -n /usr/bin/killall "$daemon" >>"$LOG" 2>&1; then
    log "FAILED to restart $daemon (needs the sudoers rule from audio/install.sh)"
    return 1
  fi
  log "restarted $daemon"
  sleep "$SETTLE_SECONDS"
  AUDIO_DEVICES=$(system_profiler SPAudioDataType 2>/dev/null)
  return 0
}

# --- Report mode ----------------------------------------------------------
if [ "$STATUS_ONLY" = "1" ]; then
  audio_in_use && echo "audio in use: yes" || echo "audio in use: no"
  watched_devices | while read -r device; do
    on_usb_bus "$device" && usb=yes || usb=no
    in_coreaudio "$device" && ca=yes || ca=no
    if [ "$usb" = yes ] && [ "$ca" = no ]; then
      verdict="WEDGED"
    elif [ "$usb" = no ]; then
      verdict="not plugged in"
    else
      verdict="ok"
    fi
    printf '%-28s usb=%-3s coreaudio=%-3s %s\n' "$device" "$usb" "$ca" "$verdict"
  done
  exit 0
fi

# --- Decide, per watched device ------------------------------------------
WEDGED=""
while read -r device; do
  [ -n "$device" ] || continue
  miss_file="$STATE_DIR/misses-$(echo "$device" | tr -c '[:alnum:]' '-')"

  if ! on_usb_bus "$device"; then
    rm -f "$miss_file"
    continue
  fi
  if in_coreaudio "$device"; then
    rm -f "$miss_file"
    continue
  fi

  # Present on the bus, absent from CoreAudio. Count it, but do not act on a
  # single observation: a device plugged in a second ago looks exactly the
  # same while its handoff is still in flight.
  misses=$(( $(cat "$miss_file" 2>/dev/null || echo 0) + 1 ))
  echo "$misses" >"$miss_file"
  log "$device: on USB bus but not in CoreAudio ($misses/$MISSES_BEFORE_FIX)"

  if [ "$misses" -ge "$MISSES_BEFORE_FIX" ]; then
    WEDGED="$WEDGED$device"$'\n'
  fi
done < <(watched_devices)

[ -n "$WEDGED" ] || exit 0

# --- Guards ---------------------------------------------------------------
NOW=$(date +%s)
LAST=$(cat "$LAST_FIX" 2>/dev/null || echo 0)

if [ "$FORCE" = "0" ]; then
  if audio_in_use; then
    log "wedged device(s) found, but audio is in use - waiting for the next quiet interval"
    exit 0
  fi
  if (( NOW - LAST < FIX_COOLDOWN )); then
    log "wedged device(s) found, but last restart was $(( NOW - LAST ))s ago (cooldown ${FIX_COOLDOWN}s)"
    exit 0
  fi
fi

# --- Context that helps explain a wedge that keeps coming back -----------
{
  echo "--- wedged devices ---"
  printf '%s' "$WEDGED"
  echo "--- audio daemons ---"
  ps -Ao pid,etime,comm | grep -E 'coreaudiod|usbaudiod' | grep -v grep
  echo "--- third party CoreAudio plug-ins ---"
  ls /Library/Audio/Plug-Ins/HAL/ 2>/dev/null
} >>"$LOG"

# --- Escalate, least disruptive first ------------------------------------
still_wedged() {
  while read -r device; do
    [ -n "$device" ] || continue
    in_coreaudio "$device" || return 0
  done < <(printf '%s' "$WEDGED")
  return 1
}

FIXED_BY=""
if restart_daemon usbaudiod && ! still_wedged; then
  FIXED_BY="usbaudiod"
elif restart_daemon coreaudiod && ! still_wedged; then
  FIXED_BY="coreaudiod"
fi

echo "$NOW" >"$LAST_FIX"

if [ -n "$FIXED_BY" ]; then
  rm -f "$STATE_DIR"/misses-*
  log "recovered after restarting $FIXED_BY"
  # Applications re-pick their device after a coreaudiod restart, so the
  # notification is worth showing even though the fix succeeded.
  osascript -e 'display notification "USB audio device recovered. Re-check the microphone in Teams." with title "Audio Fix"' 2>/dev/null
else
  log "still wedged after restarting both daemons - not a daemon problem, check the log for plug-ins and cabling"
  osascript -e 'display notification "USB audio device still missing after restarting the audio daemons." with title "Audio Fix"' 2>/dev/null
  exit 1
fi
