#!/bin/bash
# Shared config loader for the "network" topic.
# Source this, do not execute it. Exits the caller when no config is present,
# because every script in this topic changes system state and must not guess.
#
# network.local.conf holds the host specific values (SSID name, gateway MAC,
# DNS servers, local subnet). It is ignored by this public repo via the
# "*.local.*" rule and versioned in the private dotfiles repo instead.

NETWORK_TOPIC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NETWORK_CONF="${NETWORK_CONF:-$NETWORK_TOPIC_DIR/network.local.conf}"

if [ ! -r "$NETWORK_CONF" ]; then
  echo "network: no config at $NETWORK_CONF" >&2
  echo "network: copy network/network.local.conf.example there and fill in your values" >&2
  exit 78   # EX_CONFIG
fi

# shellcheck source=/dev/null
. "$NETWORK_CONF"

# --- DNS profiles -----------------------------------------------------------
# Profiles are declared in the config as DNS_PROFILE_<name>="server ...".
# Both dns.sh (manual switching) and dns-switch.sh (automatic enforcement)
# resolve them through these two helpers, so the config stays the only place
# where a DNS server address is written down.

# Print the server list of a profile. Prints nothing for an unknown profile.
dns_profile_servers() {
  local varname="DNS_PROFILE_$1"
  printf '%s' "${!varname-}"
}

# Print the names of all declared profiles, one per line.
dns_profile_names() {
  compgen -v | sed -n 's/^DNS_PROFILE_//p' | sort -u
}

# File written by dns.sh to tell dns-switch.sh to keep its hands off.
DNS_OVERRIDE_FILE="${DNS_OVERRIDE_FILE:-$HOME/.dns-override}"

# How long a manual override survives, in seconds. It is also dropped as soon
# as the machine moves to a different network, see dns-switch.sh.
DNS_OVERRIDE_MAX_AGE="${DNS_OVERRIDE_MAX_AGE:-28800}"   # 8 hours
