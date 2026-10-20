# Outillage et boucle de développement

## La boucle

```
éditer dans ~/wd/wow-addons/MonAddon
        ↓  (lien symbolique, rien à copier)
Interface/AddOns/MonAddon
        ↓  /reload en jeu
tester
        ↓  BugSack si ça casse
corriger
```

### Le lien symbolique

**Le code d'un addon ne vit jamais dans l'arborescence du jeu.** Il y est lié.

```sh
mkdir -p ~/wd/wow-addons
# le dépôt git, versionné, sauvegardé
cd ~/wd/wow-addons/MonAddon && git init

# le lien que le client suit — Wine gère les liens symboliques Linux nativement
ln -s ~/wd/wow-addons/MonAddon "$WOW_RETAIL_DIR/Interface/AddOns/MonAddon"
```

Trois raisons :

1. **Le jeu écrase son dossier.** Une réparation Battle.net ou une réinstallation emporte tout
   ce qui n'est pas lié ailleurs.
2. **Pas d'historique.** Un addon dans `Interface/AddOns/` sans dépôt git n'a ni diff, ni
   retour arrière, ni trace de ce qui marchait hier.
3. **Pas de copie manuelle.** L'oubli de recopier avant de tester fait perdre des heures à
   déboguer une version qui n'est pas celle qu'on lit.

Vérifier que le lien est vu par le client :

```sh
ls -l "$WOW_RETAIL_DIR/Interface/AddOns/" | grep '^l'
```

### Recharger

`/reload` recharge toute l'interface : les fichiers Lua sont relus, les SavedVariables écrites
puis relues. C'est l'équivalent d'un redémarrage applicatif, pas d'un rechargement à chaud —
il n'existe pas de HMR côté addon.

Ne pas relancer le jeu pour un changement de code. En revanche, **un changement de TOC
nécessite un redémarrage complet** : la liste des addons et leurs métadonnées ne sont lues
qu'au lancement.

## Débogage en jeu

| Commande | Usage |
| :-- | :-- |
| `/reload` | Recharger l'interface. |
| `/dump <expression>` | Évaluer et afficher une valeur Lua. `/dump C_Spell.GetSpellInfo(133)` — l'outil le plus utile de tous. |
| `/api <nom>` | Documentation générée par le client. `/api C_UnitAuras` liste le namespace, `/api UnitHealth` donne la signature **et les annotations de secret**. La source de vérité. |
| `/etrace` | Traceur d'événements : ce qui est réellement émis, avec la charge utile. Indispensable pour trouver le bon événement. |
| `/framestack` | Survoler une frame et voir sa hiérarchie, son nom, ses textures. Pour comprendre l'UI de Blizzard avant de s'y greffer. |
| `/console scriptErrors 1` | Afficher les erreurs Lua. Redondant si BugGrabber est installé. |
| `/console cvarlist <motif>` | Chercher un CVar. |

### BugGrabber et BugSack

Déjà installés. **Ce sont les outils de débogage, pas un confort.** Sans eux, une erreur Lua
dans un addon est silencieuse : le code s'arrête au milieu d'une fonction et rien ne le dit.

BugSack donne la pile d'appel complète, les locales au moment de l'erreur et le compte des
occurrences. Réflexe : à la moindre anomalie, ouvrir BugSack **avant** de relire le code.

## luacheck

```sh
sudo pacman -S luacheck        # extra/luacheck
```

Linter statique. Ce qu'il attrape et qui compte vraiment ici :

| Code | Détecte | Pourquoi c'est grave dans WoW |
| :-- | :-- | :-- |
| 111 / 112 | Écriture ou lecture d'une globale non déclarée | **La faute la plus coûteuse** : conflit silencieux avec un autre addon. |
| 113 | Globale inconnue | Une faute de frappe sur un namespace `C_*` (voir plus bas). |
| 211 | Variable locale inutilisée | Souvent un reste de refactoring, parfois un bug (mauvaise variable utilisée à côté). |
| 411 / 412 | Variable redéfinie qui masque la précédente | Source classique de bugs impossibles à lire. |
| 542 | Bloc vide | Un `if` oublié. |

Configuration : le projet fournit son `.luacheckrc` (le squelette d'addon en contient un) ;
à défaut, le hook utilise `~/.claude/hooks/luacheckrc-wow`.

**Le parti pris de cette configuration** : l'API Blizzard compte plusieurs milliers de globales,
impossibles à énumérer sans noyer le signal. Les globales PascalCase inconnues sont donc
tolérées — **sauf les namespaces `C_*`**, qui sont listés exhaustivement (155 entrées extraites
du corpus). Conséquence pratique : `C_Speell.GetSpellName(id)` est signalé,
`GetSpellNaem(id)` ne l'est pas. Vérifier les noms de fonction reste manuel, via `/api`.

## stylua

```sh
sudo pacman -S stylua          # extra/stylua
```

Formateur déterministe — l'équivalent de Prettier. Fin des débats d'indentation, diffs
minimaux.

```sh
stylua .                  # formater
stylua --check .          # vérifier sans modifier (ce que fait le hook)
```

Configuration par défaut : **tabulations, 120 colonnes**. C'est la convention du code Blizzard
et de BigWigs, donc du corpus de référence. Un projet peut poser son propre `stylua.toml`.

## Les hooks Claude Code

Deux hooks sont actifs, dans `~/.claude/hooks/` :

| Hook | Déclenchement | Effet |
| :-- | :-- | :-- |
| `wow-context.sh` | `SessionStart` | Injecte une ligne : version du client lue dans `.build.info` et numéro d'interface correspondant. Aucun accès réseau. |
| `wow-lint.sh` | `PostToolUse` sur `Write`/`Edit` | Sur `.lua` : luacheck + stylua. Sur `.toc` : vérifie que `## Interface:` couvre le client installé. Renvoie l'erreur pour correction immédiate. |

Le chemin du jeu est détecté automatiquement, surchargeable par `WOW_RETAIL_DIR`. Sans jeu
installé, les deux hooks ne font rien.

## Git

Conventions habituelles (`rules/git.md`) : titre court en anglais, description courte
expliquant le *pourquoi*, branches courtes.

`.gitignore` d'un addon :

```
*.zip
.luacheckcache
.DS_Store
```

**La version vit dans le TOC**, pas dans le code. `C_AddOns.GetAddOnMetadata(name, "Version")`
la relit. Un numéro de version dupliqué dans un fichier Lua finit toujours par diverger.

## Mettre à jour le numéro d'interface

À chaque patch mineur du jeu :

```sh
bash ~/.claude/hooks/wow-context.sh     # donne le numéro attendu
```

Puis corriger `## Interface:` dans le TOC. Le hook de lint le signale de toute façon à la
première édition du fichier.

Un numéro périmé ne casse pas l'addon : le client le marque « incompatible » et le désactive,
sauf si l'utilisateur a coché « Charger les addons obsolètes ». Le symptôme typique est
« mon addon a disparu après le patch ».

## Ce qui n'est pas mis en place

**Pas de chaîne de packaging** (BigWigs packager, CurseForge, Wago) : les addons sont pour un
usage personnel. Si la publication devient un objectif, c'est une décision à prendre —
elle amène le multi-TOC, la gestion des tags, la localisation externalisée et des jetons d'API
en secrets GitHub (`rules/deployment.md`).

**Pas de chaîne de tests standard.** L'écosystème n'en a pas : le code dépend d'un client en
cours d'exécution. En revanche, la logique métier d'un addon **peut** être testée hors du jeu
— voir la section suivante.

## Tester la logique métier sans lancer le jeu

Dès qu'un addon prend des décisions qui croisent plusieurs conditions (type d'instance,
difficulté, options, état d'avancement), les vérifier en jeu suppose de reproduire chaque
situation — donc d'entrer en raid pour tester une branche. C'est le moment de sortir la
logique dans des fonctions interrogeables et de la piloter depuis `lua5.1`.

Le montage tient en trois temps :

```lua
-- tests/logic_spec.lua  —  lua5.1 tests/logic_spec.lua

-- 1. Simulacres des API WoW dont le code a besoin, pilotés par une table
--    d'état qu'on modifie entre les scénarios.
local world = { instanceType = "none", difficultyID = 0 }
_G.GetInstanceInfo = function()
    return "Aucune", world.instanceType, world.difficultyID
end
_G.C_AddOns = { GetAddOnMetadata = function() return "test" end }

-- 2. Chargement des fichiers dans l'ordre du TOC, en reproduisant les deux
--    arguments implicites que le client passe à chaque fichier d'addon.
local ns = {}
local function LoadFile(path)
    assert(loadfile(path))("MonAddon", ns)
end
LoadFile("Locales.lua")
LoadFile("Core.lua")

-- 3. Scénarios et assertions.
world.instanceType, world.difficultyID = "raid", 15
assert(ns.ShouldLogNow() == true)
```

Points qui font la différence entre un banc d'essai utile et un gadget :

- **Ne charger que les fichiers sans dépendance à l'UI.** `Core.lua` et `Locales.lua` passent ;
  tout ce qui appelle `CreateFrame` au chargement demanderait des simulacres disproportionnés.
  Neutraliser les rappels d'UI après chargement (`ns.UpdateIndicator = function() end`).
- **Remettre l'état à neuf entre les scénarios** — base de données et monde simulé — sinon les
  cas se contaminent.
- **Un scénario par régression corrigée.** C'est là que le banc paie : le bug ne peut plus
  revenir sans être signalé.
- **`tests/` ne doit PAS figurer dans le TOC.** Le fichier ne se charge jamais en jeu.
- Sortir avec `os.exit(failed == 0 and 0 or 1)` pour être utilisable dans un enchaînement.

Ce que ça ne teste pas : l'UI, les événements, le comportement réel des valeurs secrètes. Ça
teste les décisions — c'est-à-dire la partie où les bugs coûtent cher et sont les plus pénibles
à reproduire.

Un squelette prêt à l'emploi est fourni dans `assets/template/tests/`.
