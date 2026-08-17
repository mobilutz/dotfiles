# Generell Claude Information

## Bash Commands

Never chain commands with `&&`. Always use separate Bash tool calls — one command per call. Chaining with `&&` breaks permissions.

## Git

Always run git as `git -C <relative-path> <subcommand>`. Never `cd` into a
repository first, and use **relative** paths, not absolute ones:

- yes: `git -C project log --oneline -3`
- no: `git -C /Users/person/project log --oneline -3`
- no: `cd /Users/person/project` followed by `git log --oneline -3`

Since commands must not be chained (see above), splitting `cd X` and `git ...`
into two separate calls is not a workaround — use `git -C`.

## Scratch files

NEVER write scratch files (curl output, header dumps, cookie jars, log copies, etc.) to `/tmp`. Always use the project's own `tmp/` directory instead.

## coding

- favour readable source code over code comments
- write source code comments only in english, NEVER use emoticons in comments

## Shell Tools

- I have GNU tools installed (find, grep sed, ack, ..)
- use these tools in other

## Planing

- put plans in <project-dir>/.claude/plans
