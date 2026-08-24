#!/bin/bash
# Installs the launchd agent that fixes the local network route bug

DOTFILES_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLIST_SRC="$DOTFILES_ROOT/network/com.user.fix-local-route.plist"
PLIST_DST="$HOME/Library/LaunchAgents/com.user.fix-local-route.plist"

# Inject the real dotfiles path into the plist
sed "s|DOTFILES_PATH|$DOTFILES_ROOT|g" "$PLIST_SRC" > "$PLIST_DST"

# Load the agent
launchctl unload "$PLIST_DST" 2>/dev/null
launchctl load "$PLIST_DST"

echo "  ✓ Local network route fix agent installed"

# Set up passwordless sudo for the route delete command
SUDOERS_FILE="/etc/sudoers.d/fix-route"
SUDOERS_LINE="$(whoami) ALL=(ALL) NOPASSWD: /sbin/route delete 192.0.2.0/23"

if ! sudo grep -qF "$SUDOERS_LINE" "$SUDOERS_FILE" 2>/dev/null; then
  echo "$SUDOERS_LINE" | sudo tee "$SUDOERS_FILE" > /dev/null
  sudo chmod 440 "$SUDOERS_FILE"
  echo "  ✓ Passwordless sudo rule added for route fix"
else
  echo "  ✓ Passwordless sudo rule already exists"
fi

# ---------------------------------------------------------------------------
# DNS switch: sets DNS servers based on the currently joined Wi-Fi network
# ---------------------------------------------------------------------------

DNS_PLIST_SRC="$DOTFILES_ROOT/network/com.local.dnsswitch.plist"
DNS_PLIST_DST="$HOME/Library/LaunchAgents/com.local.dnsswitch.plist"

mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"

# Inject the real dotfiles path into the plist
sed "s|DOTFILES_PATH|$DOTFILES_ROOT|g" "$DNS_PLIST_SRC" > "$DNS_PLIST_DST"
chmod 644 "$DNS_PLIST_DST"

launchctl bootout "gui/$UID/com.local.dnsswitch" 2>/dev/null || true
launchctl bootstrap "gui/$UID" "$DNS_PLIST_DST"
launchctl kickstart -k "gui/$UID/com.local.dnsswitch"

echo "  ✓ DNS switch agent installed (log: ~/Library/Logs/dns-switch.log)"

# Set up passwordless sudo for the DNS commands
DNS_SUDOERS_FILE="/etc/sudoers.d/dns-switch"
DNS_SUDOERS_CONTENT="$(whoami) ALL=(ALL) NOPASSWD: /usr/sbin/networksetup -setdnsservers Wi-Fi *
$(whoami) ALL=(ALL) NOPASSWD: /usr/bin/killall -HUP mDNSResponder"

if ! sudo grep -qF "/usr/sbin/networksetup -setdnsservers Wi-Fi" "$DNS_SUDOERS_FILE" 2>/dev/null; then
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

echo "  → Edit the CONFIG block in network/dns-switch.sh to change SSID/DNS"
