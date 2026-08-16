#!/usr/bin/env sh
# Shared helpers for `dots` and the shell hook.
#
# Strictly POSIX sh: this file is sourced by scripts that run under whatever
# /bin/sh the machine provides (dash on Debian, bash on Arch/CachyOS). No
# arrays, no [[ ]], no `local` outside of what dash accepts, no $'...'.

DOTFILES_DIR=${DOTFILES_DIR:-"$HOME/dotfiles"}
DOTFILES_CACHE=${XDG_CACHE_HOME:-"$HOME/.cache"}/dotfiles
DOTFILES_STATUS="$DOTFILES_CACHE/status"
DOTFILES_LAST_CHECK="$DOTFILES_CACHE/last-check"
DOTFILES_LOCK="$DOTFILES_CACHE/lock"
DOTFILES_MANIFEST="$DOTFILES_DIR/manifest"

# How long a check stays fresh, in seconds. Four hours: often enough that the
# other machine's changes land the same day, rare enough that opening a
# terminal almost never triggers network work.
DOTFILES_TTL=${DOTFILES_TTL:-14400}

# A background fetch must never outlive its usefulness, and a lock left behind
# by a killed process must not wedge the loop forever.
DOTFILES_FETCH_TIMEOUT=${DOTFILES_FETCH_TIMEOUT:-30}
DOTFILES_LOCK_MAX_AGE=${DOTFILES_LOCK_MAX_AGE:-300}

# --- output ---------------------------------------------------------------

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
	C_RESET=$(printf '\033[0m')
	C_DIM=$(printf '\033[2m')
	C_RED=$(printf '\033[31m')
	C_GREEN=$(printf '\033[32m')
	C_YELLOW=$(printf '\033[33m')
	C_BLUE=$(printf '\033[34m')
else
	C_RESET='' C_DIM='' C_RED='' C_GREEN='' C_YELLOW='' C_BLUE=''
fi

info() { printf '%s\n' "$*"; }
ok() { printf '%s✓%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn() { printf '%s!%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
err() { printf '%s✗%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; }
dim() { printf '%s%s%s\n' "$C_DIM" "$*" "$C_RESET"; }
die() {
	err "$*"
	exit 1
}

# --- manifest -------------------------------------------------------------

# Emit "<src> <dst>" per entry, comments and blanks stripped, so callers can
# consume it with a plain `while read -r src dst`. This is why the manifest
# forbids spaces in paths.
read_manifest() {
	[ -r "$DOTFILES_MANIFEST" ] || die "manifest not found: $DOTFILES_MANIFEST"
	# Globbing off: a stray * in the manifest must stay a literal, not expand
	# against the current directory.
	set -f
	while IFS= read -r line || [ -n "$line" ]; do
		case $line in
		'#'* | '') continue ;;
		esac
		# shellcheck disable=SC2086 # deliberate word splitting on the two columns
		set -- $line
		if [ $# -ne 2 ]; then
			warn "manifest: ignoring malformed line: $line"
			continue
		fi
		printf '%s %s\n' "$1" "$2"
	done <"$DOTFILES_MANIFEST"
	set +f
}

# Classify one target. Echoes one of: ok | missing | broken | foreign | absent-source
#   ok            target is a symlink pointing at the repo source
#   missing       nothing at the target path
#   broken        symlink, but pointing somewhere else (or dangling)
#   foreign       a real file/dir sits there instead of our symlink
#   absent-source the repo does not have the source at all
link_state() {
	_src="$DOTFILES_DIR/$1"
	_dst="$HOME/$2"

	[ -e "$_src" ] || {
		printf 'absent-source\n'
		return
	}
	if [ -L "$_dst" ]; then
		_cur=$(readlink "$_dst")
		if [ "$_cur" = "$_src" ]; then printf 'ok\n'; else printf 'broken\n'; fi
	elif [ -e "$_dst" ]; then
		printf 'foreign\n'
	else
		printf 'missing\n'
	fi
}

# --- git ------------------------------------------------------------------

# Run git inside the dotfiles repo, never inheriting the caller's repo context.
dgit() { git -C "$DOTFILES_DIR" "$@"; }

# Every git call that can reach the network goes through here.
#
# Two things it guarantees:
#
#   - It can never ask a human anything. The background refresh runs detached
#     with no terminal; a credential or SSH passphrase prompt there would hang
#     forever, invisibly, holding the lock until it went stale. That is not
#     hypothetical: an SSH key with a passphrase and no agent is a perfectly
#     ordinary setup.
#   - It cannot outlive its usefulness. A stalled TCP connection would
#     otherwise pin the lock for the rest of the session.
#
# Every element of the chain is a real executable — `timeout`, `env`, `git`.
# An earlier version wrapped a shell *function* in `timeout`, which cannot
# work: timeout execs its argument, and a function is not on disk. It failed
# on every call, and because a failed fetch is deliberately silent, it failed
# invisibly.
git_net() {
	_to=''
	if command -v timeout >/dev/null 2>&1; then
		_to="timeout $DOTFILES_FETCH_TIMEOUT"
	fi
	# shellcheck disable=SC2086 # $_to must split into argv, or be absent
	$_to env \
		GIT_TERMINAL_PROMPT=0 \
		GIT_ASKPASS=/bin/true \
		SSH_ASKPASS=/bin/true \
		GIT_SSH_COMMAND='ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new' \
		git -C "$DOTFILES_DIR" "$@"
}

worktree_is_clean() { [ -z "$(dgit status --porcelain 2>/dev/null)" ]; }

# Echo "<behind> <ahead>" relative to the tracked upstream, space separated,
# or return 1 when the branch has no upstream configured.
upstream_gap() {
	dgit rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1 || return 1
	dgit rev-list --left-right --count '@{u}...HEAD' 2>/dev/null | tr '\t' ' '
}
