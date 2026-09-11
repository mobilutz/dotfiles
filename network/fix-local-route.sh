#!/bin/bash
# Deletes an anomalous route for the local subnet.
#
# IMPORTANT: the local subnet also has a legitimate on-link route that macOS
# creates from the interface address and netmask. For a 10.0.0.111/23 address
# on en0 (interface index 14) netstat prints it as
#
#   10/23  link#14  UCS  en0
#
# That route must never be deleted. Without it every LAN destination is sent
# to the default gateway instead of being resolved by ARP, which breaks local
# device reachability and makes macOS tear down and rebuild the default route.
# An earlier version of this script deleted it unconditionally every 10
# seconds, which is what caused the "kicked out of the network" symptom it was
# supposed to fix.
#
# A route is only treated as broken when it is NOT that on-link route, i.e.
# when it carries a real gateway or points at an interface that is not the one
# currently holding the default route.
#
# The route is read BEFORE it is deleted, so the log records what was actually
# removed. Set DRY_RUN=1 in the config to log findings without deleting.
#
# Logs to ~/Library/Logs/fix-local-route.log.

set -uo pipefail

. "$(dirname "$0")/config.sh"

: "${HEALTH_HOST:=}"
: "${DRY_RUN:=0}"

LOG="$HOME/Library/Logs/fix-local-route.log"
LAST_FIX="$HOME/.local-network-fix-last"
mkdir -p "$(dirname "$LOG")"
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >>"$LOG"; }

# --- Which interface currently carries the default route ---
PRIMARY_IF=$(route -n get default 2>/dev/null | awk '/interface:/ { print $2; exit }')
if [ -z "$PRIMARY_IF" ]; then
  exit 0   # offline or still associating, nothing to judge against
fi

# --- Read the route before touching it, otherwise the evidence is gone ---
ROUTE_LINE=$(netstat -rn -f inet | awk -v pat="$BAD_ROUTE_PATTERN" '$0 ~ pat { print; exit }')
if [ -z "$ROUTE_LINE" ]; then
  exit 0   # no route for the subnet at all
fi

read -r R_DEST R_GW R_FLAGS R_IF _ <<<"$ROUTE_LINE"

# --- The on-link route is legitimate: link# gateway on the primary interface ---
if [[ "$R_GW" == link#* && "$R_IF" == "$PRIMARY_IF" ]]; then
  exit 0
fi

# --- Optional second opinion: only act while the LAN is actually broken ---
if [ -n "$HEALTH_HOST" ] && ping -c 1 -t 2 "$HEALTH_HOST" >/dev/null 2>&1; then
  log "anomalous route $R_DEST gw=$R_GW flags=$R_FLAGS if=$R_IF, but $HEALTH_HOST answers - not touching it"
  exit 0
fi

log "anomalous route: dest=$R_DEST gw=$R_GW flags=$R_FLAGS if=$R_IF (primary=$PRIMARY_IF)"

# --- Context that helps explain where the route came from ---
{
  echo "--- active network processes ---"
  ps aux | grep -E "citrix|docker|vpn|utun" | grep -v grep
  echo "--- full inet routing table ---"
  netstat -rn -f inet
} >>"$LOG"

if [ "$DRY_RUN" = "1" ]; then
  log "DRY_RUN=1 - would delete $BAD_ROUTE, leaving it in place"
  exit 0
fi

if sudo -n /sbin/route delete "$BAD_ROUTE" >>"$LOG" 2>&1; then
  log "deleted $BAD_ROUTE"
else
  log "FAILED to delete $BAD_ROUTE (needs the sudoers rule from network/install.darwin.sh)"
  exit 1
fi

# --- Notify at most once every 5 minutes ---
NOW=$(date +%s)
LAST=$(cat "$LAST_FIX" 2>/dev/null || echo 0)
if (( NOW - LAST > 300 )); then
  osascript -e 'display notification "Local network route fixed" with title "Network Fix"' 2>/dev/null
  echo "$NOW" >"$LAST_FIX"
fi
