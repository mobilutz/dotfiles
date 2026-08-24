#!/bin/bash
# Shared config loader for the "network" topic.
# Source this, do not execute it. Exits the caller when no config is present,
# because every script in this topic changes system state and must not guess.

NETWORK_CONF="${NETWORK_CONF:-$HOME/.dotfiles-private/network/network.conf}"

if [ ! -r "$NETWORK_CONF" ]; then
  echo "network: no config at $NETWORK_CONF" >&2
  echo "network: copy network/network.conf.example there and fill in your values" >&2
  exit 78   # EX_CONFIG
fi

# shellcheck source=/dev/null
. "$NETWORK_CONF"
