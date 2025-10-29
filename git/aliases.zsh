# Use `hub` as our git wrapper:
#   https://hub.github.com/
# hub_path=$(which hub)
# if (( $+commands[hub] ))
# then
#   alias git=$hub_path
# fi

# The rest of my fun git aliases
alias gl='git pull --prune'
alias glog="git log --graph --pretty=format:'%Cred%h%Creset %an: %s - %Creset %C(yellow)%d%Creset %Cgreen(%cr)%Creset' --abbrev-commit --date=relative"
alias gp='git push origin HEAD'

# Remove `+` and `-` from start of diff lines; just rely upon color.
alias gd='git diff --color | sed "s/^\([^-+ ]*\)[-+ ]/\\1/" | less -r'

alias gac='git add -A && git commit -m'
alias gb='git branch'
alias gc='git commit'
alias gca='git commit -a'
alias gcb='git copy-branch-name'
# alias gcm='git commit --all --message'
alias gcm='git commit -m'
alias gco='git checkout'
alias gcom='git checkout master'
alias ge='git-edit-new'
alias gst='git status -sb' # upgrade your git if -sb breaks for you. it's fun.
alias gll='git status -sb'

alias addnw=!sh -c 'git diff -U0 -w --no-color "$@" | git apply --cached --ignore-whitespace --unidiff-zero -'

check_ci_skip() {
  # Check if we are in a Git repository
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "\033[1;33mNot inside a Git repository. Cannot check commit message.\033[0m"
    return 2
  fi

  local msg
  msg=$(git log -1 --pretty=%B 2>/dev/null)
  if [[ -z "$msg" ]]; then
    echo "\033[1;33mNo commits found in this repository.\033[0m"
    return 2
  fi

  # Patterns to check
  local patterns="\[ci skip\]|\[skip ci\]|\[ci-skip\]|\[skip-ci\]"

  if echo "$msg" | grep -Eiq "$patterns"; then
    echo "\033[1;31mCI SKIP DETECTED in commit message!\033[0m"
    return 0
  else
    echo "\033[1;32mNo CI skip found.\033[0m"
    return 1
  fi
}
