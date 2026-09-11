# VS Code is the editor on the Mac; the Pis only have vim.
#
# EDITOR stays a bare command name - `bin/dot -e` and `bin/e` exec "$EDITOR"
# as a single word, so a flag in there would break them. The two Ruby
# variables are handed to a shell, so they can ask VS Code to block.
if (( $+commands[code] ))
then
  export EDITOR='code'
  export BUNDLER_EDITOR='code --wait'
  export GEM_OPEN_EDITOR='code --wait'
else
  export EDITOR='vim'
  export BUNDLER_EDITOR='vim'
  export GEM_OPEN_EDITOR='vim'
fi
