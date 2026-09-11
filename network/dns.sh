#!/bin/bash
# Manual DNS profile switcher.
#
#   dns.sh <profile>   set DNS to that profile and hold it against dns-switch.sh
#   dns.sh auto        clear the override and hand control back to dns-switch.sh
#   dns.sh status      show current DNS, the matching profile and override state
#   dns.sh list        list the profiles declared in the config
#
# Profiles live in network.local.conf as DNS_PROFILE_<name>="server ...", which
# is the only place a DNS server address is written down. Alfred and any other
# front end should call this script rather than running networksetup directly,
# otherwise dns-switch.sh reverts the change within five minutes.
#
# Holding works through an override file that records the gateway MAC at the
# time of the switch. dns-switch.sh honours the override while that gateway is
# still the current one, and drops it as soon as the machine joins a different
# network - so forcing a LAN-only resolver at home cannot follow the laptop to
# a cafe and leave it without a working resolver.

set -uo pipefail

. "$(dirname "${BASH_SOURCE[0]}")/config.sh"

usage() {
  echo "usage: dns.sh <profile|auto|status|list>" >&2
  echo "profiles: $(dns_profile_names | tr '\n' ' ')" >&2
  exit 64
}

current_dns() {
  local out
  out=$(networksetup -getdnsservers "$SERVICE" 2>/dev/null)
  case "$out" in
    *"aren't any DNS Servers"*) printf 'Empty' ;;
    *) printf '%s' "$(echo "$out" | tr '\n' ' ' | sed 's/ *$//')" ;;
  esac
}

gateway_mac() {
  local dev gw
  dev=$(networksetup -listnetworkserviceorder 2>/dev/null \
    | awk -v svc="$SERVICE" '
        $0 ~ "\\) " svc "$" { found=1; next }
        found && /Device:/ { match($0, /Device: [a-z0-9]+/); print substr($0, RSTART+8, RLENGTH-8); exit }')
  dev=${dev:-en0}
  gw=$(ipconfig getoption "$dev" router 2>/dev/null)
  [ -n "$gw" ] || return 1
  arp -n "$gw" 2>/dev/null \
    | awk '{ for (i = 1; i <= NF; i++) if ($i ~ /^([0-9a-f]{1,2}:){5}[0-9a-f]{1,2}$/) { print tolower($i); exit } }'
}

# Name of the profile whose server list matches what is configured right now.
matching_profile() {
  local now name
  now=$(current_dns)
  for name in $(dns_profile_names); do
    if [ "$(dns_profile_servers "$name")" = "$now" ]; then
      printf '%s' "$name"
      return 0
    fi
  done
  printf '(none)'
}

apply_dns() {
  # shellcheck disable=SC2086
  local servers=($1)
  if networksetup -setdnsservers "$SERVICE" "${servers[@]}" 2>/dev/null; then
    :
  elif sudo -n networksetup -setdnsservers "$SERVICE" "${servers[@]}" 2>/dev/null; then
    :
  else
    echo "dns: failed to set DNS, needs admin rights - rerun network/install.darwin.sh" >&2
    return 1
  fi
  dscacheutil -flushcache 2>/dev/null
  sudo -n killall -HUP mDNSResponder 2>/dev/null
}

case "${1:-}" in
  ''|-h|--help) usage ;;

  list)
    for name in $(dns_profile_names); do
      printf '%-8s %s\n' "$name" "$(dns_profile_servers "$name")"
    done
    ;;

  status)
    echo "service:  $SERVICE"
    echo "current:  $(current_dns)"
    echo "profile:  $(matching_profile)"
    echo "enforced: ${TARGET_PROFILE:-<unset>} (on the home network)"
    if [ -r "$DNS_OVERRIDE_FILE" ]; then
      local_age=$(( $(date +%s) - $(sed -n 's/^set_at=//p' "$DNS_OVERRIDE_FILE") ))
      echo "override: $(sed -n 's/^profile=//p' "$DNS_OVERRIDE_FILE")" \
           "set ${local_age}s ago, pinned to gateway $(sed -n 's/^gw_mac=//p' "$DNS_OVERRIDE_FILE")"
    else
      echo "override: none, dns-switch.sh is in control"
    fi
    ;;

  auto)
    rm -f "$DNS_OVERRIDE_FILE"
    echo "dns: override cleared, dns-switch.sh is back in control"
    # Let the agent reassert immediately rather than waiting for its next tick.
    launchctl kickstart -k "gui/$(id -u)/com.local.dnsswitch" 2>/dev/null \
      || echo "dns: could not kick dns-switch, it will catch up within 5 minutes"
    ;;

  *)
    profile="$1"
    servers=$(dns_profile_servers "$profile")
    if [ -z "$servers" ]; then
      echo "dns: unknown profile '$profile'" >&2
      usage
    fi

    apply_dns "$servers" || exit 1

    gw=$(gateway_mac)
    if [ -n "$gw" ]; then
      {
        echo "profile=$profile"
        echo "gw_mac=$gw"
        echo "set_at=$(date +%s)"
      } > "$DNS_OVERRIDE_FILE"
      echo "dns: $profile -> $servers (held until you run 'dns.sh auto' or leave this network)"
    else
      echo "dns: $profile -> $servers (no gateway found, override not written)"
    fi
    ;;
esac
