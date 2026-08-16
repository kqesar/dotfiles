#!/usr/bin/env sh
# Bootstrap this machine.
#
#   git clone https://github.com/kqesar/dotfiles.git ~/dotfiles
#   ~/dotfiles/install.sh
#
# Idempotent: safe to re-run after every pull. It only ever adds things, and
# `dots link` backs up anything it has to replace.

set -eu

DOTFILES_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
export DOTFILES_DIR

# shellcheck source=lib/common.sh
. "$DOTFILES_DIR/lib/common.sh"

MARKER='>>> dotfiles >>>'

info "dotfiles → $DOTFILES_DIR"
printf '\n'

# --- 1. put `dots` on PATH ------------------------------------------------
# ~/.local/bin is already on PATH on any modern distro, so linking there means
# no shell needs its PATH edited — one less per-shell difference to maintain.

info "── dots on PATH ──"
mkdir -p "$HOME/.local/bin"
if [ -L "$HOME/.local/bin/dots" ] && [ "$(readlink "$HOME/.local/bin/dots")" = "$DOTFILES_DIR/bin/dots" ]; then
	dim "    already linked"
else
	rm -f "$HOME/.local/bin/dots"
	ln -s "$DOTFILES_DIR/bin/dots" "$HOME/.local/bin/dots"
	ok "~/.local/bin/dots"
fi
chmod +x "$DOTFILES_DIR/bin/dots" "$DOTFILES_DIR/shell/hook.sh" "$DOTFILES_DIR/install.sh"

case ":$PATH:" in
*":$HOME/.local/bin:"*) : ;;
*) warn "~/.local/bin is not on your PATH — add it, or call $DOTFILES_DIR/bin/dots directly" ;;
esac

# --- 2. the links themselves ----------------------------------------------
# Done BEFORE the hooks on purpose: ~/.bashrc and ~/.zshrc are themselves
# manifest entries, so linking first replaces them with the repo versions,
# which already carry the hook. Hooking first would append to a file that is
# about to be swapped out.

printf '\n'
info "── config links ──"
sh "$DOTFILES_DIR/bin/dots" link

# --- 3. shell hooks -------------------------------------------------------
# For any rc file the manifest does NOT manage, the hook is appended here.
# The linked ones already contain it, so the marker check makes this a no-op.

printf '\n'
info "── shell hooks ──"

install_posix_hook() {
	_rc=$1
	_label=$2
	if [ -f "$_rc" ] && grep -qF "$MARKER" "$_rc"; then
		dim "    $_label already hooked"
		return 0
	fi
	# Appended at the very end on purpose. ~/.bashrc returns early for
	# non-interactive shells near the top, so anything down here only ever
	# runs for a real interactive session.
	printf '\n' >>"$_rc"
	cat "$DOTFILES_DIR/shell/init.posix" >>"$_rc"
	ok "$_label → ${_rc#"$HOME"/}"
}

# Refuse to append into a symlinked rc: that would write the hook into the
# repo copy, which already has it, and duplicate it on every machine.
posix_rc_is_linked() { [ -L "$1" ]; }

for _shell in bash zsh; do
	_rc="$HOME/.${_shell}rc"
	if posix_rc_is_linked "$_rc"; then
		dim "    $_shell rc is managed by the manifest, hook already inside"
	elif command -v "$_shell" >/dev/null 2>&1 || [ -f "$_rc" ]; then
		[ -f "$_rc" ] || touch "$_rc"
		install_posix_hook "$_rc" "$_shell"
	else
		dim "    $_shell not installed, skipped"
	fi
done

_fish_conf="$HOME/.config/fish/conf.d/dotfiles.fish"
if command -v fish >/dev/null 2>&1 || [ -d "$HOME/.config/fish" ]; then
	mkdir -p "$(dirname "$_fish_conf")"
	if [ -L "$_fish_conf" ] && [ "$(readlink "$_fish_conf")" = "$DOTFILES_DIR/shell/dotfiles.fish" ]; then
		dim "    fish already hooked"
	else
		rm -f "$_fish_conf"
		ln -s "$DOTFILES_DIR/shell/dotfiles.fish" "$_fish_conf"
		ok "fish → ~/.config/fish/conf.d/dotfiles.fish"
	fi
else
	dim "    fish not installed, skipped"
fi

# --- 4. what this machine is still missing --------------------------------
# Reported, never installed. Silently pulling packages onto a machine is not
# this script's business.

printf '\n'
info "── optional tools ──"
for _t in tmux lvim fzf gh; do
	if command -v "$_t" >/dev/null 2>&1; then
		ok "$_t"
	else
		dim "    $_t not installed (its config is linked and inert until then)"
	fi
done

if [ ! -f "$HOME/.config/fish/functions/fisher.fish" ] && command -v fish >/dev/null 2>&1; then
	dim "    fisher not installed — fish plugins (nvm, bass) will not load"
fi

# --- 5. machine-local escape hatches --------------------------------------
# Anything specific to this machine goes here and is never versioned. It is
# what makes one shared rc file usable on two different machines without any
# templating.

printf '\n'
info "── machine-local overrides ──"
mkdir -p "$HOME/.config/dotfiles"
for _f in local.sh local.fish; do
	if [ ! -f "$HOME/.config/dotfiles/$_f" ]; then
		printf '# Machine-specific settings for %s. Never versioned.\n' "$(hostname)" \
			>"$HOME/.config/dotfiles/$_f"
		ok "created ~/.config/dotfiles/$_f"
	else
		dim "    ~/.config/dotfiles/$_f exists"
	fi
done

printf '\n'
ok "done — open a new shell, then run: dots doctor"
