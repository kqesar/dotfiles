#!/usr/bin/env bash
# Runs one hook from the optional private companion repo (README: "Private
# companion repo"). Claude Code reads user hooks from ~/.claude/settings.json
# only, and that file is public, so it names this script and an entry name;
# the companion links its hooks to ~/.claude/hooks-private/, one <entry>.sh
# per entry. No companion, or no script by that name: a silent no-op.
#
# exec hands over stdin (the hook's JSON payload), stdout, stderr and the exit
# code (2 sends stderr back to Claude), as if settings.json named the script.
script="$HOME/.claude/hooks-private/${1:-}.sh"
[ -n "${1:-}" ] && [ -f "$script" ] || exit 0
exec bash "$script"
