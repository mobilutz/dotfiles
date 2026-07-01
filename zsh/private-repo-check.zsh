_private_repo_precmd() {
  [[ -t 1 ]] || return
  [[ "$PWD" == "$HOME/.dotfiles"* ]] || return
  local priv_dir="$HOME/.dotfiles-private"
  [[ -d "$priv_dir/.git" ]] || return

  local priv_status
  priv_status=$(git -C "$priv_dir" status --porcelain 2>/dev/null)
  [[ -n "$priv_status" ]] || return

  local count
  count=$(echo "$priv_status" | wc -l | tr -d ' ')
  print -P "%F{yellow}⚠ private dotfiles: $count uncommitted change(s) — run 'priv status'%f"
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _private_repo_precmd
