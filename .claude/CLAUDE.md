# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

A topic-centric dotfiles repository (based on holman/dotfiles). Each top-level directory is a "topic" (e.g., `git/`, `zsh/`, `docker/`) containing related configuration.

## Topic Convention

Files within each topic directory follow naming conventions that determine how they're used:

- `topic/*.zsh` — Auto-sourced into the shell environment
- `topic/path.zsh` — Sourced **first** (for PATH setup)
- `topic/completion.zsh` — Sourced **last** (for autocompletions)
- `topic/*.symlink` — Symlinked to `$HOME` as dotfiles (e.g., `git/gitconfig.symlink` → `~/.gitconfig`)
- `topic/install.sh` — Run by `script/install` during setup

Cross-platform: this repo targets macOS **and** Debian/Raspberry Pi OS.
`$DOTFILES_OS` is `darwin` or `linux`. An extra OS segment restricts a file to
one platform — `topic/*.darwin.zsh` / `topic/*.linux.zsh` (also works for
`path.<os>.zsh` and `completion.<os>.zsh`), `topic/install.<os>.sh`, and
`topic/foo.<os>.symlink` (which still lands on `~/.foo`). Prefer a new
OS-suffixed file over a `uname` guard inside a shared one.

## Key Scripts

- **`script/bootstrap`** — Full initial setup (prompts for git author, installs Oh My Zsh, creates symlinks, runs `dot`). `DOTFILES_NONINTERACTIVE=1` plus `GIT_AUTHORNAME`/`GIT_AUTHOREMAIL` (and optional `GIT_SIGNINGKEY`) runs it unattended
- **`bin/dot`** — Ongoing maintenance: pulls latest, then `brew bundle` (macOS) or apt + `linux/packages.txt` (Linux), executes all `install.sh` scripts. `--pull-only` pulls and stops
- **`script/install`** — Finds and runs every `*/install.sh` and `*/install.$DOTFILES_OS.sh` in the repo

## Shell Loading Order

Defined in `zsh/zshrc.symlink`:
1. Powerlevel10k instant prompt
2. Oh My Zsh framework init
3. `~/.localrc` (machine-specific secrets/env vars, not committed)
4. All `*/path.zsh` files
5. All other `*.zsh` files (aliases, config, env)
6. All `*/completion.zsh` files
7. Optional: z, zsh-syntax-highlighting, Heroku autocomplete, Mise, SDKMAN
8. `~/.zshrc.local` for final local overrides

## Important Paths & Variables

- `$DOTZSH` → `~/.dotfiles` (this repo)
- `$PROJECTS` → `~/code`
- `$BREW_PREFIX` → `/opt/homebrew` (macOS only, set by `homebrew/brew.darwin.zsh`)
- `$DOTFILES_OS` → `darwin` or `linux`
- `bin/` directory is added to `$PATH`
- Primary editor: VS Code (`code`)

## Making Changes

- **Adding a new topic**: Create a directory, add `.zsh` files for aliases/config, `.symlink` files for dotfiles, and optionally `install.sh` for setup. Add the `.darwin`/`.linux` segment when the topic is platform-specific
- **Adding packages**: Edit `Brewfile` for macOS (via `brew bundle`) and `linux/packages.txt` for Debian/Raspberry Pi OS (via `linux/install.linux.sh`)
- **Adding shell aliases**: Add to the relevant `topic/aliases.zsh` file
- **Adding functions**: Place in `functions/` directory (auto-loaded via `autoload -U`)
- **Machine-specific config**: Use `~/.localrc` or `~/.zshrc.local` (never committed)

## Git Configuration

`git/gitconfig.symlink` includes 100+ aliases and uses `~/.gitconfig.local` for per-machine user identity (name, email, signing key). GPG commit signing is enabled. Default branch is `main`.

This repo has two remotes: `origin` (github.com/mobilutz/dotfiles) is the real remote for all pull/push work; `upstream` (github.com/holman/dotfiles) is the fork source, read-only. `main` must track `origin/main` or `bin/dot`'s `git pull` fails with "no tracking information".

## Private Config Repo

Machine-specific secrets/identity are versioned in a SEPARATE private repo, synced across machines without going into the public repo.

- **location:** `~/.dotfiles/private/`, a normal nested repo, ignored by the public `.gitignore`. VS Code shows it as a second repository
- **rule:** every `*.local.*` file lives in `private/<topic>/...`. `script/link-private` (run by bootstrap and `dot`) symlinks each one back to the same path in the public tree, so consumers find it where they expect it. `.claude/plans` is linked as a whole directory
- **alias:** `priv` = `git -C $HOME/.dotfiles/private` (defined in `zsh/zshrc.local.symlink`)
- **adding a file:** create it in `private/<topic>/`, commit there, run `script/link-private`
- **sourcing:** the loader skips `private/`, but the links in the public tree are sourced via `**/*.zsh`, so a private helper library must not end in `.zsh` (e.g. `ocp/lib.local.zsh.inc`)
- **never name a public file `*.local.*`** — it would be ignored (that is why the launchd template is `com.user.dnsswitch.plist`)

**How to apply:** Before committing any file, confirm no plaintext secrets: store secrets as `op://` 1Password references. New-machine bootstrap: see `private/README.local.md`. The `.example` template files belong in the PUBLIC repo, not the private one.
