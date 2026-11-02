# BREW_PREFIX=$(brew --prefix)
export PATH="/opt/homebrew/bin:$PATH"

# Unprefixed GNU tools (sed, ls, find, grep) ahead of the BSD ones.
# Explicit list on purpose: libtool also ships a gnubin and would shadow Apple's libtool.
for gnu_formula in coreutils gnu-sed findutils grep; do
  gnu_libexec="/opt/homebrew/opt/$gnu_formula/libexec"
  [[ -d "$gnu_libexec/gnubin" ]] || continue
  export PATH="$gnu_libexec/gnubin:$PATH"
  export MANPATH="$gnu_libexec/gnuman:$MANPATH"
done
unset gnu_formula gnu_libexec
