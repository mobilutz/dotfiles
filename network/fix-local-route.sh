#!/bin/bash
# Fixes a corrupted subnet route injected by Docker that causes local network
# devices to become unreachable. The affected subnet comes from the private
# config, see network/network.conf.example.
# Logs to ~/Library/Logs/fix-local-route.log for diagnostics.

. "$(dirname "$0")/config.sh"

if netstat -rn -f inet | grep -qE "$BAD_ROUTE_PATTERN"; then
  mkdir -p "$HOME/Library/Logs"
  LOG="$HOME/Library/Logs/fix-local-route.log"
  LAST_FIX="$HOME/.local-network-fix-last"
  NOW=$(date +%s)
  LAST=$(cat "$LAST_FIX" 2>/dev/null || echo 0)

  # Delete the route regardless, but only log/notify every 5 minutes
  sudo /sbin/route delete "$BAD_ROUTE" 2>/dev/null

  if (( NOW - LAST > 300 )); then
    ROUTE_FLAGS=$(netstat -rn -f inet | awk -v pat="$BAD_ROUTE_PATTERN" '$0 ~ pat {print $3; exit}')
    ROUTE_GW=$(netstat -rn -f inet | awk -v pat="$BAD_ROUTE_PATTERN" '$0 ~ pat {print $2; exit}')

    echo "--- $(date) ---" >> "$LOG"
    echo "Route detected (flags: $ROUTE_FLAGS, gw: $ROUTE_GW), deleting" >> "$LOG"

    echo "--- Active network processes ---" >> "$LOG"
    ps aux | grep -E "citrix|docker|vpn|utun" | grep -v grep >> "$LOG"

    echo "--- System network events ---" >> "$LOG"
    log show --last 60s --predicate 'eventMessage contains "route" OR eventMessage contains "network"' --info 2>/dev/null | tail -20 >> "$LOG"

    echo "" >> "$LOG"

    osascript -e 'display notification "Local network route fixed" with title "Network Fix"'

    echo "$NOW" > "$LAST_FIX"
  fi
fi
