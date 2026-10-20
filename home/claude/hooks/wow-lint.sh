#!/usr/bin/env bash
# Hook PostToolUse (Write|Edit) — contrôle qualité des fichiers d'addon WoW.
#
#   *.lua  -> luacheck (config du projet si elle existe, sinon celle livrée ici)
#             puis stylua --check
#   *.toc  -> le champ ## Interface doit couvrir la version du client installé
#   reste  -> sortie immédiate
#
# Code 2 = le message part sur stderr et revient à Claude pour correction.
# Un outil absent n'est jamais une erreur : le hook s'efface.

set -u

here=$(dirname "$0")
# shellcheck source=./wow-common.sh
. "$here/wow-common.sh"

command -v jq >/dev/null 2>&1 || exit 0

payload=$(cat)
file=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -n "$file" ] || exit 0
[ -f "$file" ] || exit 0

problems=""
note() { problems="${problems}$1"$'\n'; }

# --- Fichiers Lua ---------------------------------------------------------

lint_lua() {
	# luacheck remonte l'arborescence tout seul pour trouver un .luacheckrc ;
	# on ne force notre config de repli que s'il n'y en a aucune au-dessus du
	# fichier, sinon le projet perdrait la main sur ses propres règles.
	local dir config=""
	dir=$(cd "$(dirname "$file")" && pwd)
	while [ "$dir" != "/" ]; do
		if [ -f "$dir/.luacheckrc" ]; then
			config="$dir/.luacheckrc"
			break
		fi
		dir=$(dirname "$dir")
	done
	[ -n "$config" ] || config="$here/luacheckrc-wow"

	if command -v luacheck >/dev/null 2>&1; then
		local out
		if ! out=$(luacheck --config "$config" --no-color --codes --ranges "$file" 2>&1); then
			note "luacheck :"
			note "$out"
		fi
	fi

	if command -v stylua >/dev/null 2>&1; then
		local sconf="" d
		d=$(cd "$(dirname "$file")" && pwd)
		while [ "$d" != "/" ]; do
			if [ -f "$d/stylua.toml" ] || [ -f "$d/.stylua.toml" ]; then
				sconf="$d"
				break
			fi
			d=$(dirname "$d")
		done
		[ -n "$sconf" ] || sconf="$here"

		if ! stylua --config-path "$sconf/stylua.toml" --check "$file" >/dev/null 2>&1; then
			note "stylua : le formatage diffère. Corriger avec : stylua --config-path $sconf/stylua.toml '$file'"
		fi
	fi
}

# --- Fichiers TOC ---------------------------------------------------------

lint_toc() {
	local retail version interface declared
	retail=$(wow_find_retail)
	[ -n "$retail" ] || return 0
	version=$(wow_client_version "$retail") || return 0
	[ -n "$version" ] || return 0
	interface=$(wow_interface_number "$version")

	declared=$(grep -i '^## *Interface *:' "$file" | head -1 | sed 's/^[^:]*: *//' | tr -d ' \r')
	if [ -z "$declared" ]; then
		note "TOC : aucun champ '## Interface:'. L'addon ne se chargera pas. Attendu : ## Interface: $interface"
		return 0
	fi

	# Le champ accepte plusieurs numéros séparés par des virgules (multi-édition) :
	# il suffit que celui du client installé figure dans la liste.
	case ",$declared," in
	*",$interface,"*) : ;;
	*)
		note "TOC : '## Interface: $declared' ne couvre pas le client installé ($version → $interface). L'addon sera marqué désactivé/incompatible."
		;;
	esac
}

case "$file" in
*.lua) lint_lua ;;
*.toc) lint_toc ;;
*) exit 0 ;;
esac

if [ -n "$problems" ]; then
	printf '%s' "$problems" >&2
	exit 2
fi
exit 0
