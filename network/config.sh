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
