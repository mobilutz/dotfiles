# Native macOS dialogs for the plugin scripts. Callers set TITLE before sourcing.
alert() {   # alert "message" ["details"]
  osascript - "$1" "${2:-}" <<'EOF' >/dev/null 2>&1
on run argv
  activate
  display alert (item 1 of argv) message (item 2 of argv) as critical
end run
EOF
}
die() { alert "$1" "$2"; exit 1 }

notify() {
  osascript -e "display notification \"$1\" with title \"$TITLE\"" >/dev/null 2>&1
}

choose() {  # choose "prompt" item1 item2 …  → prints choice, non-zero on cancel
  local r
  r=$(osascript - "$TITLE" "$@" <<'EOF' 2>/dev/null
on run argv
  activate
  set t to item 1 of argv
  set p to item 2 of argv
  set l to items 3 thru -1 of argv
  set r to choose from list l with title t with prompt p OK button name "Next"
  if r is false then error number -128
  return item 1 of r
end run
EOF
) || return 1
  print -r -- "$r"
}

ask() {     # ask "prompt" "default" [hidden]  → prints answer, non-zero on cancel
  local r
  r=$(osascript - "$TITLE" "$1" "$2" "${3:-}" <<'EOF' 2>/dev/null
on run argv
  activate
  set {t, p, d, h} to argv
  if h is "hidden" then
    display dialog p default answer d with title t with hidden answer
  else
    display dialog p default answer d with title t
  end if
  return text returned of result
end run
EOF
) || return 1
  print -r -- "$r"
}

confirm() { # confirm "message" "details" "button"  → zero if the button was pressed
  osascript - "$1" "$2" "$3" <<'EOF' >/dev/null 2>&1
on run argv
  activate
  display alert (item 1 of argv) message (item 2 of argv) as warning ¬
    buttons {"Cancel", item 3 of argv} default button "Cancel" cancel button "Cancel"
end run
EOF
}
