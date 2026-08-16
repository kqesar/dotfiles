#!/usr/bin/env sh
# Runs at the start of every interactive shell — bash, zsh, fish, anything.
#
# This is the hot path. Two hard rules:
#
#   1. It NEVER touches the network. It only reads a small cache file written
#      by an earlier background refresh. Cost is one process spawn and two
#      file reads, on the order of a millisecond.
#   2. It NEVER prints anything the background job produced *while* it runs.
#      The refresh is detached and its result is displayed at the *next* shell
#      start, so output can never race in over an already-drawn prompt.
#
# It is executed, not sourced. Nothing here needs to modify the calling
# shell's environment, which is precisely why one file can serve every shell
# instead of one dialect-specific copy per shell.

DOTFILES_DIR=${DOTFILES_DIR:-"$HOME/dotfiles"}
_cache=${XDG_CACHE_HOME:-"$HOME/.cache"}/dotfiles
_status="$_cache/status"
_last="$_cache/last-check"
_ttl=${DOTFILES_TTL:-14400}

[ -d "$DOTFILES_DIR/.git" ] || exit 0

# --- 1. show what the previous refresh found ------------------------------

if [ -s "$_status" ]; then
	if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
		_r=$(printf '\033[0m') _g=$(printf '\033[32m')
		_y=$(printf '\033[33m') _d=$(printf '\033[2m')
	else
		_r='' _g='' _y='' _d=''
	fi
	while IFS='|' read -r _kind _text || [ -n "$_kind" ]; do
		[ -n "$_text" ] || continue
		case $_kind in
		up) printf '%s dotfiles%s %s\n' "$_g" "$_r" "$_text" ;;
		warn) printf '%s dotfiles%s %s\n' "$_y" "$_r" "$_text" ;;
		*) printf '%s dotfiles %s%s\n' "$_d" "$_text" "$_r" ;;
		esac
	done <"$_status"
fi

# --- 2. decide whether a refresh is due -----------------------------------

_now=$(date +%s 2>/dev/null) || exit 0
_then=0
[ -r "$_last" ] && read -r _then <"$_last" 2>/dev/null
case $_then in
'' | *[!0-9]*) _then=0 ;;
esac

[ $((_now - _then)) -ge "$_ttl" ] || exit 0

# Stamp the time *before* forking. Opening ten tabs at once then fires exactly
# one refresh: the other nine read the fresh stamp and skip. The lock in
# `dots __refresh` is the correctness guarantee; this is just cheaper.
mkdir -p "$_cache" 2>/dev/null || exit 0
printf '%s\n' "$_now" >"$_last" 2>/dev/null || exit 0

# --- 3. fork it, fully detached -------------------------------------------
# stdin/stdout/stderr are all closed off: the job must never be able to write
# over the user's terminal, nor read from it. setsid also detaches it from the
# session, so closing the terminal does not kill a fetch mid-flight.

if command -v setsid >/dev/null 2>&1; then
	setsid sh "$DOTFILES_DIR/bin/dots" __refresh >/dev/null 2>&1 </dev/null &
else
	sh "$DOTFILES_DIR/bin/dots" __refresh >/dev/null 2>&1 </dev/null &
fi

exit 0
