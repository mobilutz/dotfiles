#!/bin/bash
# Fixes a corrupted 10.0.0.0/23 subnet route that occasionally appears on
# macOS (injected by Docker), causing local network devices to become
# unreachable. Logs to ~/Library/Logs/fix-local-route.log for diagnostics.

# Only fix if NAS is unreachable AND the subnet route exists
if ! ping -c 1 -t 2 10.0.0.10 &>/dev/null && netstat -rn -f inet | grep -q "^10\/23"; then
  mkdir -p "$HOME/Library/Logs"
  LOG="$HOME/Library/Logs/fix-local-route.log"
  ROUTE_FLAGS=$(netstat -rn -f inet | awk '/^10\/23/{print $3; exit}')
  ROUTE_GW=$(netstat -rn -f inet | awk '/^10\/23/{print $2; exit}')

  echo "--- $(date) ---" >> "$LOG"
  echo "Bad route detected (flags: $ROUTE_FLAGS, gw: $ROUTE_GW), NAS unreachable" >> "$LOG"

  # Log active network-related processes
  echo "--- Active network processes ---" >> "$LOG"
  ps aux | grep -E "citrix|docker|vpn|utun" | grep -v grep >> "$LOG"

  # Log system network events from the last 60 seconds
  echo "--- System network events ---" >> "$LOG"
  log show --last 60s --predicate 'eventMessage contains "route" OR eventMessage contains "network"' --info 2>/dev/null | tail -20 >> "$LOG"

  echo "--- Deleting route ---" >> "$LOG"
  sudo /sbin/route delete 10.0.0.0/23 2>&1 >> "$LOG"

  osascript -e 'display notification "Local network route fixed" with title "Network Fix"'

  echo "" >> "$LOG"
fi
