# Pipe my public key to the clipboard.
#
# Prefers ed25519 over rsa, and picks whichever clipboard tool this machine
# has: pbcopy on macOS, xclip or wl-copy under X11/Wayland. With none of them
# (a headless Pi over ssh) it just prints the key.
pubkey () {
  local key
  for key in ~/.ssh/id_ed25519.pub ~/.ssh/id_rsa.pub
  do
    [[ -r $key ]] && break
  done

  if [[ ! -r $key ]]
  then
    echo "=> No public key in ~/.ssh." >&2
    return 1
  fi

  if (( $+commands[pbcopy] ))
  then
    pbcopy < $key
  elif (( $+commands[xclip] ))
  then
    xclip -selection clipboard < $key
  elif (( $+commands[wl-copy] ))
  then
    wl-copy < $key
  else
    cat $key
    return
  fi

  echo "=> $key copied to the clipboard."
}
