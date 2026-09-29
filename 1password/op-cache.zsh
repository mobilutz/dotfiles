# Disk cache for `op read`.
#
# Without it every new interactive shell calls the 1Password CLI, and every
# call can raise the "1Password Access Requested" authorization dialog -- once
# per calling app (Terminal, iTerm, VS Code, anything that spawns a login
# shell), and again after each app update. Caching the resolved secret keeps
# that dialog to roughly once per TTL instead of once per window.
#
# Load order matters: topics that resolve secrets (npm/, zsh/) must see this
# function already defined, and `1password` sorts ahead of both in the
# $DOTZSH/**/*.zsh glob. Consumers still guard defensively.

zmodload zsh/datetime
zmodload -F zsh/stat b:zstat

export OP_CACHE_DIR=${OP_CACHE_DIR:-$HOME/.cache/op}
export OP_CACHE_TTL=${OP_CACHE_TTL:-$((7 * 24 * 3600))}

# How long a failed read is remembered. A reference that does not resolve --
# wrong account, renamed item, revoked token -- otherwise caches nothing, so
# every new shell calls op again and raises the authorization dialog again.
export OP_CACHE_FAIL_TTL=${OP_CACHE_FAIL_TTL:-3600}

# op_cached_read <cache-name> <op://uri> [extra op args...]
#
# Prints the secret on stdout. Serves a fresh cache without touching op at all.
# On a miss it reads from 1Password and stores the result 0600. If op is
# unavailable (not installed, offline, vault locked) it falls back to a stale
# cache rather than returning nothing, so a locked vault degrades to an old
# token instead of an empty one.
#
# A failed read is remembered in <name>.fail for OP_CACHE_FAIL_TTL and warns
# once, so a broken reference backs off instead of prompting on every shell.
# `op_cache_clear <name>` drops the marker and retries immediately.
#
# Refuses to run when stdout is a terminal, so typing the command by hand
# cannot spill a secret into the scrollback, a screen share or a transcript.
# Command substitution and redirects give a pipe or a file, not a tty, so the
# intended `$(op_cached_read ...)` callers are unaffected. Set
# OP_CACHE_ALLOW_TTY=1 to override.
op_cached_read() {
  if [[ -t 1 && -z $OP_CACHE_ALLOW_TTY ]]; then
    print -u2 -- "op_cached_read: refusing to print a secret to a terminal."
    print -u2 -- "  use: VAR=\$(op_cached_read $1 ...)   or set OP_CACHE_ALLOW_TTY=1"
    return 2
  fi

  local name=$1 uri=$2
  shift 2

  local file=$OP_CACHE_DIR/$name
  local -a mtime
  local age=$OP_CACHE_TTL

  if [[ -f $file ]] && zstat -A mtime +mtime -- $file 2>/dev/null; then
    age=$(( EPOCHSECONDS - mtime[1] ))
  fi

  if [[ -s $file && $age -lt $OP_CACHE_TTL ]]; then
    print -r -- "$(<$file)"
    return 0
  fi

  if (( ! $+commands[op] )); then
    [[ -s $file ]] && print -r -- "$(<$file)"
    return
  fi

  local fail=$file.fail
  local -a fail_mtime

  if [[ -f $fail ]] && zstat -A fail_mtime +mtime -- $fail 2>/dev/null &&
     (( EPOCHSECONDS - fail_mtime[1] < OP_CACHE_FAIL_TTL )); then
    [[ -s $file ]] && print -r -- "$(<$file)"
    return
  fi

  local secret
  secret=$(op read "$uri" "$@" 2>/dev/null)

  mkdir -p $OP_CACHE_DIR
  chmod 700 $OP_CACHE_DIR

  if [[ -n $secret ]]; then
    ( umask 077; print -r -- "$secret" > $file )
    rm -f -- $fail
    print -r -- "$secret"
  else
    : > $fail
    print -u2 -- "op_cached_read: $name did not resolve ($uri)"
    print -u2 -- "  retrying in $(( OP_CACHE_FAIL_TTL / 60 ))m; force now with: op_cache_clear $name"
    [[ -s $file ]] && print -r -- "$(<$file)"
  fi
}

# op_cache_clear [name...] -- forget cached secrets so the next shell re-reads
# them from 1Password. No arguments clears everything.
op_cache_clear() {
  if (( $# )); then
    local name
    for name in "$@"; do rm -f -- $OP_CACHE_DIR/$name $OP_CACHE_DIR/$name.fail; done
  else
    rm -f -- $OP_CACHE_DIR/*(N)
  fi
}
