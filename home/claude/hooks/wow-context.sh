#!/usr/bin/env bash
# Hook SessionStart — injecte la version réelle du client WoW installé.
#
# Raison d'être : le savoir du modèle sur l'API d'addon est périmé par
# construction, et un numéro d'interface faux empêche l'addon de se charger.
# .build.info est la seule source locale qui ne mente pas, et elle est gratuite
# (une lecture de fichier, aucun accès réseau).
#
# Sortie : une ligne, ou rien du tout si le jeu n'est pas installé.

set -u

# shellcheck source=./wow-common.sh
. "$(dirname "$0")/wow-common.sh"

retail=$(wow_find_retail)
[ -n "$retail" ] || exit 0

version=$(wow_client_version "$retail") || exit 0
[ -n "$version" ] || exit 0

interface=$(wow_interface_number "$version")

printf 'WoW retail installé : %s → `## Interface: %s` (source .build.info, lu à chaque session — ne pas déduire ce numéro de mémoire).\n' \
	"$version" "$interface"
