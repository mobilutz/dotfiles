#!/bin/bash
# dns-switch.sh - set DNS based on which network we are actually attached to.
# Triggered by the LaunchAgent com.local.dnsswitch on every network change.
#
# The network is identified by the MAC address of the default gateway, not by
# SSID: recent macOS versions return the literal string "<redacted>" from
# "ipconfig getsummary" unless the calling process holds Location Services
# authorization, which a LaunchAgent does not.
#
# Gateway MAC, network name and DNS servers come from the private config,
# see network/network.conf.example.

set -uo pipefail

. "$(dirname "$0")/config.sh"

LOG="$HOME/Library/Logs/dns-switch.log"
mkdir -p "$(dirname "$LOG")"
exec >>"$LOG" 2>&1
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*"; }

# Config values arrive as space separated strings, DNS handling needs arrays
read -r -a TARGET_DNS_LIST <<<"$TARGET_DNS"
read -r -a FALLBACK_DNS_LIST <<<"$FALLBACK_DNS"

# Pass the text as an argument so odd characters cannot break the AppleScript
notify() {
  osascript -e 'on run argv
    display notification item 1 of argv with title "DNS Switch"
  end run' "$1" 2>/dev/null
}

# Debounce: network changes fire several filesystem events in a row.
LOCK="${TMPDIR:-/tmp}/dns-switch.$(id -u).lock"
if ! mkdir "$LOCK" 2>/dev/null; then
  # Reap a lock left behind by a run that was killed before its trap fired
  if [ -n "$(find "$LOCK" -maxdepth 0 -mmin +2 2>/dev/null)" ]; then
    log "removing stale lock $LOCK"
    rmdir "$LOCK" 2>/dev/null
    mkdir "$LOCK" 2>/dev/null || exit 0
  else
    exit 0
  fi
fi
trap 'rmdir "$LOCK" 2>/dev/null' EXIT
sleep 3   # let the network settle before reading the gateway

# --- Find the BSD device for the network service (usually en0) ---
DEV=$(networksetup -listnetworkserviceorder 2>/dev/null \
  | awk -v svc="$SERVICE" '
      $0 ~ "\\) " svc "$" { found=1; next }
      found && /Device:/ { match($0, /Device: [a-z0-9]+/); print substr($0, RSTART+8, RLENGTH-8); exit }')
DEV=${DEV:-en0}

# --- Identify the network by the MAC address of its default gateway ---
GW=$(ipconfig getoption "$DEV" router 2>/dev/null)
if [ -z "$GW" ]; then
  log "no default gateway on $DEV (offline or still associating) - leaving DNS alone"
  exit 0
fi

gw_mac() {
  arp -n "$GW" 2>/dev/null \
    | awk '{ for (i = 1; i <= NF; i++) if ($i ~ /^([0-9a-f]{1,2}:){5}[0-9a-f]{1,2}$/) { print tolower($i); exit } }'
}

GW_MAC=$(gw_mac)
if [ -z "$GW_MAC" ]; then
  # Empty ARP cache right after a network change: one ping populates it
  ping -c 1 -t 1 "$GW" >/dev/null 2>&1
  GW_MAC=$(gw_mac)
fi

if [ -z "$GW_MAC" ]; then
  log "gateway $GW has no ARP entry on $DEV - leaving DNS alone"
  exit 0
fi

# --- Decide what DNS should be ---
if [ "$GW_MAC" = "$TARGET_GW_MAC" ]; then
  NET="$TARGET_NAME"
  WANT=("${TARGET_DNS_LIST[@]}")
else
  NET="$GW via $GW_MAC"
  WANT=("${FALLBACK_DNS_LIST[@]}")
fi

# --- Read current DNS ---
CURRENT=$(networksetup -getdnsservers "$SERVICE" 2>/dev/null)
case "$CURRENT" in
  *"aren't any DNS Servers"*) CURRENT_LIST="Empty" ;;
  *) CURRENT_LIST=$(echo "$CURRENT" | tr '\n' ' ' | sed 's/ *$//') ;;
esac
WANT_LIST=$(printf '%s ' "${WANT[@]}" | sed 's/ *$//')

if [ "$CURRENT_LIST" = "$WANT_LIST" ]; then
  log "net=$NET - DNS already [$CURRENT_LIST], nothing to do"
  exit 0
fi

# --- Apply ---
if networksetup -setdnsservers "$SERVICE" "${WANT[@]}" 2>/dev/null; then
  :
elif sudo -n networksetup -setdnsservers "$SERVICE" "${WANT[@]}" 2>/dev/null; then
  :
else
  log "net=$NET - FAILED to set DNS (needs admin rights; rerun network/install.sh for the sudoers rule)"
  notify "$NET: FAILED to set DNS - needs admin rights"
  exit 1
fi

dscacheutil -flushcache 2>/dev/null
sudo -n killall -HUP mDNSResponder 2>/dev/null

log "net=$NET - DNS [$CURRENT_LIST] -> [$WANT_LIST]"

notify "$NET: DNS -> $WANT_LIST"
