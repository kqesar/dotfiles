# AddonTemplate

Addon World of Warcraft **retail** (Midnight, 12.x), usage personnel.

## Ce qu'il fait

<!-- Une ou deux phrases. Le problème résolu, pas la liste des fonctions. -->

## Conventions de ce dépôt

Les standards globaux s'appliquent (`~/.claude/rules/wow-addons.md`, skills `wow-addon-dev`
et `wow-api-midnight`). Rappels propres à ce projet :

- **API Blizzard native**, sans bibliothèque externe. Toute lib ajoutée doit être justifiée
  et discutée d'abord.
- **Commentaires en français**, identifiants et documentation en anglais.
- **Aucune API écrite de mémoire** : vérifier dans `Interface/AddOns/` (corpus local), puis
  sur `warcraft.wiki.gg`, puis via `/api` en jeu.
- Tout fichier `.lua` doit être listé dans le TOC. Un fichier orphelin est du code mort.
- `luacheck .` et `stylua --check .` doivent passer avant de considérer une tâche finie.

## Structure

| Fichier | Rôle |
| :-- | :-- |
| `AddonTemplate.toc` | Manifeste et ordre de chargement. Porte le numéro de version. |
| `Locales.lua` | Chaînes traduites. Chargé en premier. |
| `Core.lua` | Base de données, valeurs par défaut, migrations, logique métier, commandes slash. |
| `Config.lua` | Panneau d'options (Settings API, layout vertical). |
| `Events.lua` | Abonnements et répartition des événements. |

## Boucle de développement

```sh
# Lien symbolique vers le dossier AddOns (une seule fois)
ln -s "$PWD" "$WOW_RETAIL_DIR/Interface/AddOns/AddonTemplate"
```

Éditer ici → `/reload` en jeu → tester → BugSack en cas d'erreur.

**Un changement de TOC nécessite un redémarrage complet du client**, pas un `/reload`.

## Points d'attention

- **Tester en contexte restreint** (combat, clé mythique+), pas seulement à vide : les valeurs
  secrètes ne se manifestent qu'en combat.
- `## Interface:` doit correspondre au client installé — le hook le vérifie à chaque édition.
- Les SavedVariables valent `nil` avant `ADDON_LOADED`.
