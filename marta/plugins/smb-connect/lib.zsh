# Shared helpers for bin/smb-connect and plugin/smb-connect.sh

zmodload zsh/datetime
SCAN_SECONDS=${SCAN_SECONDS:-3}
CACHE_DIR=${CACHE_DIR:-$HOME/Library/Caches/net.lengemann.smbconnect}
SERVERS_FILE=$CACHE_DIR/servers.tsv   # last-seen-epoch <TAB> host or "-" <TAB> name
USERS_FILE=$CACHE_DIR/users.tsv       # host <TAB> user
SCAN_STAMP=$CACHE_DIR/last-scan
FORGET_AFTER_DAYS=30

typeset -ga MENU_LABELS
typeset -gA MENU_NAME

# Percent-encode a string for use in an smb:// URL (byte-wise, UTF-8 safe)
urlencode() {
  local LC_ALL=C s="$1" out="" c i
  for (( i = 1; i <= ${#s}; i++ )); do
    c="${s[i]}"
    case "$c" in
      [a-zA-Z0-9.~_-]) out+="$c" ;;
      *) out+=$(printf '%%%02X' "'$c") ;;
    esac
  done
  print -r -- "$out"
}

# Run a command for N seconds, capture its output
run_for() {
  local secs=$1; shift
  local tmp=$(mktemp)
  "$@" >"$tmp" 2>/dev/null &
  local pid=$!
  sleep "$secs"
  kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
  cat "$tmp"; rm -f "$tmp"
}

# Discover SMB servers advertised via Bonjour
discover() {
  local me=$(scutil --get ComputerName 2>/dev/null)
  run_for "$SCAN_SECONDS" dns-sd -B _smb._tcp local. |
    awk '$2 == "Add" { n = $7; for (i = 8; i <= NF; i++) n = n " " $i; print n }' |
    sort -u | grep -vxF -- "$me"
}

# Resolve a Bonjour instance name to a hostname
resolve() {
  local host
  host=$(run_for 2 dns-sd -L "$1" _smb._tcp local. |
         sed -nE 's/.*can be reached at ([^ ]+):[0-9]+.*/\1/p' | head -1)
  host=${host%.}
  [[ -n $host ]] && print -r -- "$host" || print -r -- "$1.local"
}

# Atomically replace FILE with stdin
write_file() {
  mkdir -p "$CACHE_DIR"
  local tmp=$(mktemp "$CACHE_DIR/.tmp.XXXXXX")
  cat >"$tmp" && mv "$tmp" "$1"
}

# ---------- server cache ----------

last_scan() {
  [[ -r $SCAN_STAMP ]] && print -r -- "$(<$SCAN_STAMP)" || print 0
}

# Scan the network and merge the result into the cache.
# Servers not seen for FORGET_AFTER_DAYS are dropped.
refresh_cache() {
  local -A host seen
  local t h name now=$EPOCHSECONDS
  if [[ -r $SERVERS_FILE ]]; then
    while IFS=$'\t' read -r t h name; do
      [[ -n $name ]] || continue
      seen[$name]=$t
      host[$name]=$h
    done <"$SERVERS_FILE"
  fi
  for name in "${(@f)$(discover)}"; do
    [[ -n $name ]] && seen[$name]=$now
  done
  for name in ${(k)seen}; do
    (( now - seen[$name] > FORGET_AFTER_DAYS * 86400 )) && continue
    print -r -- "${seen[$name]}"$'\t'"${host[$name]:--}"$'\t'"$name"
  done | sort -t $'\t' -k3 | write_file "$SERVERS_FILE"
  print $now | write_file "$SCAN_STAMP"
}

# Fill MENU_LABELS (ordered) and MENU_NAME (label -> server name) from the cache.
# Servers missing from the most recent scan are flagged with the day last seen.
build_server_menu() {
  local scanned=$(last_scan) t h name label
  MENU_LABELS=()
  MENU_NAME=()
  [[ -r $SERVERS_FILE ]] || return
  while IFS=$'\t' read -r t h name; do
    [[ -n $name ]] || continue
    label=$name
    (( t < scanned )) && label+="  (not seen since $(strftime '%f %b' $t))"
    MENU_LABELS+=("$label")
    MENU_NAME[$label]=$name
  done <"$SERVERS_FILE"
}

last_scan_label() {
  local t=$(last_scan)
  (( t )) && strftime '%f %b %H:%M' $t || print never
}

# Hostname for a server name; resolved once, then taken from the cache
server_host() {
  local h
  h=$(awk -F'\t' -v n="$1" '$3 == n { print $2; exit }' "$SERVERS_FILE" 2>/dev/null)
  if [[ -n $h && $h != - ]]; then
    print -r -- "$h"
    return
  fi
  h=$(resolve "$1")
  awk -F'\t' -v OFS='\t' -v n="$1" -v h="$h" '$3 == n { $2 = h } 1' "$SERVERS_FILE" |
    write_file "$SERVERS_FILE"
  print -r -- "$h"
}

# ---------- shares and mounts ----------

# Disk shares from `smbutil view` output on stdin, hidden ($) shares dropped
parse_shares() {
  sed -nE 's/^(.*[^ ]) +Disk( .*)?$/\1/p' | grep -v '\$$'
}

# Mount point of a share on a host. With "any", fall back to the same share
# mounted under another host name (Finder may use the Bonjour name).
find_mount() {  # find_mount host share [any]
  local mounts
  mounts=$(mount -t smbfs | grep -F -- "/$(urlencode "$2") on ")
  { print -r -- "$mounts" | grep -iF -- "@$1/"
    [[ $3 == any ]] && print -r -- "$mounts"
  } | sed -nE 's/^.* on (.*) \(smbfs.*$/\1/p' | head -1
}

# ---------- remembered users ----------

remembered_user() {
  awk -F'\t' -v h="$1" '$1 == h { print $2; exit }' "$USERS_FILE" 2>/dev/null
}

# Default username for a host: remembered one, else the Keychain account, else $USER.
# Reads only the account attribute, never the password, so no Keychain prompt.
default_user() {
  local u srv
  u=$(remembered_user "$1")
  if [[ -z $u ]]; then
    for srv in "$1" "$1."; do
      u=$(security find-internet-password -s "$srv" 2>/dev/null |
          sed -nE 's/^ *"acct"<blob>="(.*)"$/\1/p')
      [[ -n $u ]] && break
    done
  fi
  print -r -- "${u:-$USER}"
}

remember_user() {
  { awk -F'\t' -v h="$1" '$1 != h' "$USERS_FILE" 2>/dev/null
    print -r -- "$1"$'\t'"$2"
  } | sort | write_file "$USERS_FILE"
}
