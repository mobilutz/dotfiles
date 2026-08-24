#!/bin/bash
# Installs the launchd agents of the network topic and their sudoers rules.
# All host specific values come from the private config,
# see network/network.conf.example.

DOTFILES_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

. "$DOTFILES_ROOT/network/config.sh"

mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"

# ---------------------------------------------------------------------------
# Route fix: deletes the corrupted subnet route Docker injects
# ---------------------------------------------------------------------------

PLIST_SRC="$DOTFILES_ROOT/network/com.user.fix-local-route.plist"
PLIST_DST="$HOME/Library/LaunchAgents/com.user.fix-local-route.plist"

# Inject the real dotfiles path into the plist
sed "s|DOTFILES_PATH|$DOTFILES_ROOT|g" "$PLIST_SRC" > "$PLIST_DST"

launchctl unload "$PLIST_DST" 2>/dev/null
launchctl load "$PLIST_DST"

echo "  ✓ Local network route fix agent installed"

SUDOERS_FILE="/etc/sudoers.d/fix-route"
SUDOERS_LINE="$(whoami) ALL=(ALL) NOPASSWD: /sbin/route delete $BAD_ROUTE"

if ! sudo grep -qF "$SUDOERS_LINE" "$SUDOERS_FILE" 2>/dev/null; then
  echo "$SUDOERS_LINE" | sudo tee "$SUDOERS_FILE" > /dev/null
  sudo chmod 440 "$SUDOERS_FILE"
  if ! sudo visudo -cf "$SUDOERS_FILE" > /dev/null; then
    sudo rm -f "$SUDOERS_FILE"
    echo "  ✗ Invalid sudoers rule for route fix, removed again"
  else
    echo "  ✓ Passwordless sudo rule added for route fix"
  fi
else
  echo "  ✓ Passwordless sudo rule for route fix already exists"
fi

# ---------------------------------------------------------------------------
# DNS switch: sets DNS servers based on the network the machine is attached to
# ---------------------------------------------------------------------------

DNS_PLIST_SRC="$DOTFILES_ROOT/network/com.local.dnsswitch.plist"
DNS_PLIST_DST="$HOME/Library/LaunchAgents/com.local.dnsswitch.plist"

# Inject the real dotfiles path into the plist
sed "s|DOTFILES_PATH|$DOTFILES_ROOT|g" "$DNS_PLIST_SRC" > "$DNS_PLIST_DST"
chmod 644 "$DNS_PLIST_DST"

launchctl bootout "gui/$UID/com.local.dnsswitch" 2>/dev/null || true
launchctl bootstrap "gui/$UID" "$DNS_PLIST_DST"
launchctl kickstart -k "gui/$UID/com.local.dnsswitch"

echo "  ✓ DNS switch agent installed (log: ~/Library/Logs/dns-switch.log)"

# Grant the exact argument lists the script uses, not a wildcard: a wildcard
# would let any process running as this user repoint DNS to a rogue resolver.
DNS_SUDOERS_FILE="/etc/sudoers.d/dns-switch"
DNS_SUDOERS_CONTENT="$(whoami) ALL=(ALL) NOPASSWD: /usr/sbin/networksetup -setdnsservers $SERVICE $TARGET_DNS
$(whoami) ALL=(ALL) NOPASSWD: /usr/sbin/networksetup -setdnsservers $SERVICE $FALLBACK_DNS
$(whoami) ALL=(ALL) NOPASSWD: /usr/bin/killall -HUP mDNSResponder"

if ! sudo grep -qF "networksetup -setdnsservers $SERVICE $TARGET_DNS" "$DNS_SUDOERS_FILE" 2>/dev/null; then
  echo "$DNS_SUDOERS_CONTENT" | sudo tee "$DNS_SUDOERS_FILE" > /dev/null
  sudo chmod 440 "$DNS_SUDOERS_FILE"
  if ! sudo visudo -cf "$DNS_SUDOERS_FILE" > /dev/null; then
    sudo rm -f "$DNS_SUDOERS_FILE"
    echo "  ✗ Invalid sudoers rule for DNS switch, removed again"
  else
    echo "  ✓ Passwordless sudo rule added for DNS switch"
  fi
else
  echo "  ✓ Passwordless sudo rule for DNS switch already exists"
fi

echo "  → Edit $NETWORK_CONF to change network, DNS servers or route"
