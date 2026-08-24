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

## Key Scripts

- **`script/bootstrap`** — Full initial setup (prompts for git author, installs Oh My Zsh, creates symlinks, runs `dot`)
- **`bin/dot`** — Ongoing maintenance: pulls latest, runs `brew bundle`, executes all `install.sh` scripts
- **`script/install`** — Finds and runs every `*/install.sh` in the repo

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
- `$BREW_PREFIX` → `/opt/homebrew`
- `bin/` directory is added to `$PATH`
- Primary editor: VS Code (`code`)

## Making Changes

- **Adding a new topic**: Create a directory, add `.zsh` files for aliases/config, `.symlink` files for dotfiles, and optionally `install.sh` for setup
- **Adding packages**: Edit `Brewfile` (Homebrew manages all packages via `brew bundle`)
- **Adding shell aliases**: Add to the relevant `topic/aliases.zsh` file
- **Adding functions**: Place in `functions/` directory (auto-loaded via `autoload -U`)
- **Machine-specific config**: Use `~/.localrc` or `~/.zshrc.local` (never committed)

## Git Configuration

`git/gitconfig.symlink` includes 100+ aliases and uses `~/.gitconfig.local` for per-machine user identity (name, email, signing key). GPG commit signing is enabled. Default branch is `main`.

This repo has two remotes: `origin` (github.com/mobilutz/dotfiles) is the real remote for all pull/push work; `upstream` (github.com/holman/dotfiles) is the fork source, read-only. `main` must track `origin/main` or `bin/dot`'s `git pull` fails with "no tracking information".

## Private Config Repo

Machine-specific secrets/identity are versioned in a SEPARATE private repo at `~/.dotfiles-private/` (regular git repo), synced across machines without going into the public repo.

- **location:** `~/.dotfiles-private/` (regular repo, not bare)
- **alias:** `priv` = `git -C $HOME/.dotfiles-private` (defined in `zsh/zshrc.local.symlink`)

**How to apply:** Before committing any file, confirm no plaintext secrets: store secrets as `op://` 1Password references. New-machine bootstrap: `git clone <remote> ~/.dotfiles-private`. The `.example` template files belong in the PUBLIC repo, not the private one.
