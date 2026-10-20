#!/usr/bin/env bash
# Fonctions partagées par les hooks WoW.
#
# Le dépôt dotfiles est public et partagé entre machines : aucun chemin absolu
# propre à un poste n'est codé en dur ici. WOW_RETAIL_DIR surcharge la détection,
# et l'absence de jeu n'est jamais une erreur — juste un no-op silencieux.

# Emplacements probables du dossier _retail_, du plus explicite au plus courant.
wow_find_retail() {
	if [ -n "${WOW_RETAIL_DIR:-}" ]; then
		[ -d "$WOW_RETAIL_DIR" ] && printf '%s\n' "$WOW_RETAIL_DIR"
		return
	fi

	local candidate
	for candidate in \
		"$HOME/Games/battlenet/drive_c/Program Files (x86)/World of Warcraft/_retail_" \
		"$HOME/Games/battle-net/drive_c/Program Files (x86)/World of Warcraft/_retail_" \
		"$HOME/.wine/drive_c/Program Files (x86)/World of Warcraft/_retail_" \
		"/mnt/games/World of Warcraft/_retail_"; do
		if [ -d "$candidate" ]; then
			printf '%s\n' "$candidate"
			return
		fi
	done
}

# Version du client depuis .build.info (fichier pipe-délimité, en-tête nommée).
# On cible la ligne du produit "wow" active, colonne "Version" — repérée par son
# nom et non par un index, l'ordre des colonnes n'étant garanti par rien.
wow_client_version() {
	local retail="$1"
	local info="$retail/../.build.info"
	[ -f "$info" ] || return 1

	awk -F'|' '
		NR == 1 {
			for (i = 1; i <= NF; i++) {
				name = $i
				sub(/!.*/, "", name)
				col[name] = i
			}
			next
		}
		col["Product"] && $col["Product"] == "wow" && $col["Version"] != "" {
			print $col["Version"]
			exit
		}
	' "$info"
}

# 12.1.0.69404 -> 120100 (format MMmmpp du champ ## Interface d'un TOC).
wow_interface_number() {
	printf '%s' "$1" | awk -F'.' '{ printf "%d%02d%02d", $1, $2, $3 }'
}
