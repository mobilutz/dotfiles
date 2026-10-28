#!/bin/zsh
# GUI version of smb-connect, launched by the Marta plugin.
# Finds SMB servers via Bonjour, lists their shares, mounts the chosen one
# and opens it in Marta. All prompts are native macOS dialogs.

emulate -L zsh
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
source "${0:A:h}/lib.zsh"
TITLE="Connect to SMB Server"
source "${0:A:h}/dialogs.zsh"

# ---------- 1. pick a server ----------
# With a cache, show it right away and refresh it in the background for next time.
if [[ -s $SERVERS_FILE ]]; then
  refresh_cache &!
else
  notify "Scanning the network for SMB servers…"
  refresh_cache
fi

RESCAN="Rescan network…"
MANUAL="Enter address manually…"
while true; do
  build_server_menu
  choice=$(choose "SMB servers (last scan: $(last_scan_label)):" \
    "${MENU_LABELS[@]}" "$RESCAN" "$MANUAL") || exit 0
  [[ $choice == "$RESCAN" ]] || break
  notify "Scanning the network for SMB servers…"
  refresh_cache
done

if [[ $choice == "$MANUAL" ]]; then
  HOST=$(ask "Hostname or IP address of the server:" "") || exit 0
else
  HOST=$(server_host "${MENU_NAME[$choice]}")
fi
[[ -z $HOST ]] && exit 0

# ---------- 2. list shares ----------
# Try the remembered user without a password first: smbutil reuses an existing
# session to the server, so no dialog is needed. Ask only when that fails.
SMBUSER=$(remembered_user "$HOST")
if [[ -z $SMBUSER || $SMBUSER == guest ]] ||
   ! listing=$(smbutil view -N "//$(urlencode "$SMBUSER")@$HOST" 2>/dev/null); then
  SMBUSER=$(ask "Username on $HOST (enter \"guest\" for guest access):" "$(default_user "$HOST")") || exit 0
  if [[ $SMBUSER == guest ]]; then
    listing=$(smbutil view -G "//$HOST" 2>&1) ||
      die "Could not list shares on $HOST." "$listing"
  elif ! listing=$(smbutil view -N "//$(urlencode "$SMBUSER")@$HOST" 2>/dev/null); then
    PASS=$(ask "Password for $SMBUSER on $HOST:" "" hidden) || exit 0
    listing=$(smbutil view -N "//$(urlencode "$SMBUSER"):$(urlencode "$PASS")@$HOST" 2>&1) ||
      die "Could not list shares on $HOST." "Wrong username/password, or the server is unreachable.

$listing"
    unset PASS
  fi
fi
remember_user "$HOST" "$SMBUSER"

shares=("${(@f)$(print -r -- "$listing" | parse_shares)}")
shares=(${shares:#})
(( ${#shares} )) || die "No accessible shares on $HOST."

typeset -A SHARE_OF
labels=()
for s in "${shares[@]}"; do
  label=$s
  [[ -n $(find_mount "$HOST" "$s") ]] && label+="  (mounted)"
  labels+=("$label")
  SHARE_OF[$label]=$s
done
choice=$(choose "Shares on $HOST:" "${labels[@]}") || exit 0
SHARE=${SHARE_OF[$choice]}

# ---------- 3. mount ----------
MP=$(find_mount "$HOST" "$SHARE")
if [[ -z $MP ]]; then
  URL="smb://$(urlencode "$SMBUSER")@$HOST/$(urlencode "$SHARE")"
  open -g "$URL" || die "macOS could not open $URL"
  for i in {1..60}; do
    MP=$(find_mount "$HOST" "$SHARE" any); [[ -n $MP ]] && break
    sleep 1
  done
  [[ -z $MP ]] && die "“$SHARE” did not mount within 60 seconds."
fi

# ---------- 4. open in Marta ----------
LAUNCHER=/Applications/Marta.app/Contents/Resources/launcher
if [[ -x $LAUNCHER ]]; then
  "$LAUNCHER" "$MP"
else
  open -a Marta "$MP"
fi
