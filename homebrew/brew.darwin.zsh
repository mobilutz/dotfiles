# Everything here needs Homebrew, so it only loads on macOS.
# Note: zsh-syntax-highlighting is deliberately NOT sourced here - it wraps the
# ZLE widgets that exist at source time, so it stays at the very end of
# zsh/zshrc.symlink.

# BREW_PREFIX=$(brew --prefix) is correct but forks on every shell start
export BREW_PREFIX=/opt/homebrew

# brew install z
[[ -r ${BREW_PREFIX}/etc/profile.d/z.sh ]] && . ${BREW_PREFIX}/etc/profile.d/z.sh

# heroku autocomplete setup
HEROKU_AC_ZSH_SETUP_PATH=$HOME/Library/Caches/heroku/autocomplete/zsh_setup
[[ -r $HEROKU_AC_ZSH_SETUP_PATH ]] && source $HEROKU_AC_ZSH_SETUP_PATH

# # Google Cloud SDK
# source "${BREW_PREFIX}/share/google-cloud-sdk/path.zsh.inc"
# source "${BREW_PREFIX}/share/google-cloud-sdk/completion.zsh.inc"
