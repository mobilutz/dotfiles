#!/usr/bin/env bash
# Claude Code status line - inspired by Powerlevel10k prompt layout

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# Shorten home directory to ~
home="$HOME"
short_cwd="${cwd/#$home/\~}"

# Git branch (skip optional lock to avoid blocking)
git_branch=""
if git_out=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null); then
  git_branch=" $git_out"
fi

# Context usage indicator
ctx_info=""
if [ -n "$used_pct" ]; then
  ctx_int=$(printf '%.0f' "$used_pct")
  ctx_info=" | ctx:${ctx_int}%"
fi

printf '\033[34m%s\033[0m\033[36m%s\033[0m\033[90m | %s%s\033[0m' \
  "$short_cwd" "$git_branch" "$model" "$ctx_info"
