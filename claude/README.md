# Claude Code config

Topic for [Claude Code](https://claude.ai/code) (Anthropic's CLI). Tracked files are symlinked into `~/.claude/` by `install.sh`.

## What's tracked

| File                          | Purpose                                                   |
| ----------------------------- | --------------------------------------------------------- |
| `CLAUDE.md`                   | Global memory shown to Claude in every session            |
| `settings.json`               | Permissions, theme, model, status line, enabled plugins   |
| `settings.local.json.example` | Template for machine-local secrets (MCP API keys, etc.)   |
| `statusline-command.sh`       | Custom status line (cwd · git branch · model · context %) |

## Install

The base `script/bootstrap` only symlinks `*.symlink` files into `$HOME`, which doesn't reach inside `~/.claude/`. So this topic ships its own `install.sh` (run automatically by `script/install`):

```sh
./install.sh
```

On first run it also seeds `~/.claude/settings.local.json` from the example. Open that file and add your secrets — it stays out of git.

## What's NOT tracked

Anything machine-local or session-state lives only under `~/.claude/` and is intentionally excluded:

- `projects/`, `sessions/`, `todos/`, `history.jsonl`, `file-history/`, `paste-cache/`, `shell-snapshots/`, `session-env/`, `ide/`, `debug/`, `backups/`, `cache/`, `telemetry/`, `statsig/` — runtime state
- `plans/` — planning notes, often contain client/project context
- `*-cache.json`, `remote-settings.json` — local caches
- `settings.local.json` — your secrets

## Secrets

Never commit MCP API keys or auth tokens. Put them in `~/.claude/settings.local.json` (Claude Code merges it on top of `settings.json`).
