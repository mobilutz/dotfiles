# mobilutz does dotfiles

Your dotfiles are how you personalize your system. These are mine.

I was a little tired of having long alias files and everything strewn about
(which is extremely common on other dotfiles projects, too). That led to this
project being much more topic-centric. I realized I could split a lot of things
up into the main areas I used (Ruby, git, system libraries, and so on), so I
structured the project accordingly.

If you're interested in the philosophy behind why projects like these are
awesome, you might want to [read my post on the
subject](https://zachholman.com/2010/08/dotfiles-are-meant-to-be-forked/).

## topical

Everything's built around topic areas. If you're adding a new area to your
forked dotfiles — say, "Java" — you can simply add a `java` directory and put
files in there. Anything with an extension of `.zsh` will get automatically
included into your shell. Anything with an extension of `.symlink` will get
symlinked without extension into `$HOME` when you run `script/bootstrap`.

## what's inside

A lot of stuff. Seriously, a lot of stuff. Check them out in the file browser
above and see what components may mesh up with you.
[Fork it](https://github.com/mobilutz/dotfiles/fork), remove what you don't
use, and build on what you do use.

## components

There's a few special files in the hierarchy.

- **bin/**: Anything in `bin/` will get added to your `$PATH` and be made
  available everywhere.
- **topic/\*.zsh**: Any files ending in `.zsh` get loaded into your
  environment.
- **topic/path.zsh**: Any file named `path.zsh` is loaded first and is
  expected to setup `$PATH` or similar.
- **topic/completion.zsh**: Any file named `completion.zsh` is loaded
  last and is expected to setup autocomplete.
- **topic/install.sh**: Any file named `install.sh` is executed when you run `script/install`.
  To avoid being loaded automatically, its extension is `.sh`, not `.zsh`.
- **topic/\*.symlink**: Any file ending in `*.symlink` gets symlinked into
  your `$HOME`. This is so you can keep all of those versioned in your dotfiles
  but still keep those autoloaded files in your home directory. These get
  symlinked in when you run `script/bootstrap`.

These dotfiles run on macOS and on Debian/Raspberry Pi OS. An extra `.darwin`
or `.linux` segment in front of the usual extension restricts a file to one
platform; `$DOTFILES_OS` holds `darwin` or `linux`.

- **topic/\*.darwin.zsh**, **topic/\*.linux.zsh**: loaded only on that OS.
  Works for `path.<os>.zsh` and `completion.<os>.zsh` too, which keep their
  first/last position in the load order.
- **topic/install.darwin.sh**, **topic/install.linux.sh**: run by
  `script/install` only on that OS.
- **topic/foo.darwin.symlink**, **topic/foo.linux.symlink**: symlinked only on
  that OS, and both land on `~/.foo` — the OS segment is stripped.

Prefer these over an `if [ "$(uname -s)" ]` guard inside a shared file: the
filename says who it is for and `ls`/`grep` can find it.

## install

Run this:

```sh
git clone https://github.com/mobilutz/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
script/bootstrap
```

This will symlink the appropriate files in `.dotfiles` to your home directory.
Everything is configured and tweaked within `~/.dotfiles`.

The main file you'll want to change right off the bat is `zsh/zshrc.symlink`,
which sets up a few paths that'll be different on your particular machine.

`dot` is a simple script that installs some dependencies, sets sane macOS
defaults, and so on. Tweak this script, and occasionally run `dot` from
time to time to keep your environment fresh and up-to-date. You can find
this script in `bin/`. On macOS it drives Homebrew and the `Brewfile`; on
Linux it drives apt and `linux/packages.txt`. `dot --pull-only` just pulls
the repo, for unattended fleet updates.

### unattended install

`script/bootstrap` normally asks for the git identity and what to do about
each conflicting dotfile. Set `DOTFILES_NONINTERACTIVE=1` and it answers both
from the environment instead - this is how a Raspberry Pi gets provisioned
over ssh:

```sh
git clone https://github.com/mobilutz/dotfiles.git ~/.dotfiles
DOTFILES_NONINTERACTIVE=1 \
GIT_AUTHORNAME="Your Name" \
GIT_AUTHOREMAIL="you@example.com" \
~/.dotfiles/script/bootstrap
```

`GIT_SIGNINGKEY` is optional; without it the generated `~/.gitconfig.local`
has no signing key and leaves commit signing off. Conflicting dotfiles are
overwritten rather than prompted for.

## private config

Machine-specific secrets and identity (`*.local.*` files) are gitignored here
and versioned in a separate private repo, kept in sync across my machines.

## bugs

I want this to work for everyone; that means when you clone it down it should
work for you even though you may not have `rbenv` installed, for example. That
said, I do use this as _my_ dotfiles, so there's a good chance I may break
something if I forget to make a check for a dependency.

If you're brand-new to the project and run into any blockers, please
[open an issue](https://github.com/mobilutz/dotfiles/issues) on this repository
and I'd love to get it fixed for you!

## thanks

I forked [Zack Holman](https://github.com/holman)' excellent
[dotfiles](https://github.com/holman/dotfiles) which are based on [Ryan Bates](https://github.com/ryanb)
[dotfiles](https://github.com/ryanb/dotfiles) and it was extended with content from
[Mathais Bynes](https://github.com/mathiasbynens/dotfiles)