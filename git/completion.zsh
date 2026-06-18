# git completions are handled by oh-my-zsh's git plugin

# Our patched _git wrapper (git/_git, adds global -C completion) lives in this
# topic dir, away from git-completion.bash. The zsh wrapper finds the bash
# script next to itself by default, so point it at the Homebrew copy explicitly.
zstyle ':completion:*:*:git:*' script "${BREW_PREFIX:-/opt/homebrew}/share/zsh/site-functions/git-completion.bash"
