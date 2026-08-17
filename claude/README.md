# Claude Code config

Topic for [Claude Code](https://claude.ai/code) (Anthropic's CLI). Tracked files are symlinked into `~/.claude/` by `install.sh` — except `settings.json`, which is generated (see below).

## What's tracked

| File                          | Purpose                                                   |
| ----------------------------- | --------------------------------------------------------- |
| `CLAUDE.md`                   | Global memory shown to Claude in every session            |
| `settings.json`               | Public settings: permissions, theme, model, status line   |
| `settings.local.json.example` | Template for the local overlay (see below)                |
| `statusline-command.sh`       | Custom status line (cwd · git branch · model · context %) |

## Install

The base `script/bootstrap` only symlinks `*.symlink` files into `$HOME`, which doesn't reach inside `~/.claude/`. So this topic ships its own `install.sh` (run automatically by `script/install`):

```sh
./install.sh
```

## Local settings overlay

`~/.claude/settings.json` is **generated, not symlinked**. `install.sh` deep-merges:

1. `claude/settings.json` from this public repo
2. `~/.dotfiles-private/claude/settings.local.json`, if present

Same `*.local.*` convention as the rest of the repo, except the overlay itself lives in `~/.dotfiles-private/` so it is versioned across machines without ever touching this public repo. Copy `settings.local.json.example` there to start one.

Objects merge key-by-key, arrays are replaced wholesale by the overlay. Use it for anything that identifies a client or employer — private plugin marketplaces, the plugins installed from them, work-only permission rules.

Two consequences:

- After editing `claude/settings.json` here, re-run `./install.sh` (or `dot`) to apply it.
- Edits made by `/config` or `/plugin` land in the generated file and are overwritten on the next run — the installer backs up any hand-edited copy to `settings.json.backup.<epoch>` first. Move changes you want to keep into this repo or the overlay.

## What's NOT tracked

Anything machine-local or session-state lives only under `~/.claude/` and is intentionally excluded:

- `projects/`, `sessions/`, `todos/`, `history.jsonl`, `file-history/`, `paste-cache/`, `shell-snapshots/`, `session-env/`, `ide/`, `debug/`, `backups/`, `cache/`, `telemetry/`, `statsig/` — runtime state
- `plans/` — planning notes, often contain client/project context
- `*-cache.json`, `remote-settings.json` — local caches
- `settings.json` — generated from this repo plus the overlay

## Secrets

Never commit MCP API keys or auth tokens.

Careful with the name: Claude Code does **not** read a `settings.local.json` sitting next to `~/.claude/settings.json` — its `local` tier is per-project (`<project>/.claude/settings.local.json`). Verified by setting `language` in each file: at `~/.claude/settings.json` the CLI answered in Japanese, from `~/.claude/settings.local.json` it had no effect. That is why the overlay is merged at install time instead of being dropped into `~/.claude/`. MCP servers added through the CLI live in `~/.claude.json`.

An older version of this topic seeded `~/.claude/settings.local.json` with MCP keys. That file was inert; delete it if it is still around.
