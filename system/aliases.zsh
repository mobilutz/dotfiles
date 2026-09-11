# The ls family, resolved against whichever ls this machine has.
#
# Homebrew installs GNU coreutils as `gls` to keep BSD ls in place; on Debian
# the system ls already is GNU. The old version only had the `gls` branch, so
# on Linux none of these were defined at all.
if (( $+commands[gls] ))
then
  alias ls="gls -F --color"
  alias l="gls -lAh --color"
  alias ll="gls -l --color"
  alias la='gls -A --color'
elif command ls --version 2>/dev/null | grep -q coreutils
then
  alias ls="command ls -F --color"
  alias l="command ls -lAh --color"
  alias ll="command ls -l --color"
  alias la='command ls -A --color'
else
  # BSD ls, i.e. macOS without coreutils
  alias ls="command ls -FG"
  alias l="command ls -lAh"
  alias ll="command ls -l"
  alias la="command ls -A"
fi
