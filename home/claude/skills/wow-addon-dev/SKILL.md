---
name: wow-addon-dev
description: Standards de développement d'addons World of Warcraft — architecture, style Lua, UI/UX, outillage et squelette de projet, au niveau attendu d'un développeur d'addon senior. À utiliser dès qu'une tâche touche un fichier .lua ou .toc d'addon WoW, le dossier Interface/AddOns, ou toute demande de créer, modifier, auditer ou faire évoluer un addon WoW. Impose l'API Blizzard native par défaut, les commentaires en français, la vérification des API contre le client installé, et une posture de force de proposition sur les features et l'UX. Se combine avec le skill wow-api-midnight pour les signatures d'API. PORTÉE STRICTE — ne pas charger sur un projet Lua sans rapport avec WoW.
---

# Développement d'addons WoW

Ce skill dit **comment écrire**. Le skill `wow-api-midnight` dit **quoi appeler**. Les deux
se chargent ensemble sur une tâche d'addon.

## Les cinq règles fermes

1. **Aucune API écrite de mémoire.** Vérifier dans le corpus local, puis sur
   `warcraft.wiki.gg`, puis avec `/api` en jeu. Si la vérification échoue, le dire.
   Protocole complet dans `wow-api-midnight`.
2. **`## Interface:` = version du client installé**, lue par le hook `SessionStart` depuis
   `.build.info`. Un numéro périmé fait apparaître l'addon comme désactivé.
3. **Commentaires en français.** Exception assumée aux standards back/front. Identifiants,
   documentation Markdown et messages de commit restent en anglais.
4. **API Blizzard native par défaut.** Une bibliothèque externe s'ajoute quand le besoin est
   démontré, jamais par réflexe. Voir « Bibliothèques » plus bas.
5. **Zéro globale accidentelle.** Tout vit dans la table privée de l'addon. Une globale non
   déclarée est un conflit avec un autre addon qui attend son heure.

## Références

| Fichier | Quand le lire |
| :-- | :-- |
| `references/architecture.md` | Structurer un addon, écrire un TOC, gérer les SavedVariables et le cycle de vie. |
| `references/lua-style.md` | Écrire du Lua correct et économe. Le Lua de WoW n'est pas le Lua standard. |
| `references/ui-ux.md` | Construire une interface, un panneau d'options, une liste défilante. |
| `references/tooling.md` | Boucle de développement, débogage en jeu, luacheck, stylua, git. |
| `references/local-corpus.md` | **Où trouver un exemple réel** de n'importe quel pattern, dans les addons installés. |

`assets/template/` contient un squelette d'addon complet, conforme à tout ce qui précède.
Le copier plutôt que de repartir d'une page blanche.

## Démarrer un nouvel addon

```sh
# 1. Le code vit dans un dépôt git, jamais dans l'arborescence du jeu.
mkdir -p ~/wd/wow-addons && cd ~/wd/wow-addons
cp -r ~/.claude/skills/wow-addon-dev/assets/template MonAddon && cd MonAddon
git init

# 2. Renommer le TOC et les identifiants (le README du template liste les points à toucher).
# 3. Lier dans le jeu : Wine suit les liens symboliques Linux sans problème.
ln -s ~/wd/wow-addons/MonAddon "$WOW_RETAIL_DIR/Interface/AddOns/MonAddon"
```

Le lien symbolique est le cœur de la boucle de dev : on édite dans le dépôt, `/reload` en jeu
recharge, aucune copie manuelle, aucun risque de perdre le travail à la désinstallation du jeu.

## Bibliothèques : le défaut est « aucune »

L'API Blizzard couvre aujourd'hui ce qui justifiait autrefois Ace3 : la **Settings API** génère
les panneaux d'options, `EventRegistry` fait le bus d'événements, `C_Timer` fait les timers,
`C_EncodingUtil` fait la sérialisation, `ScrollUtil` fait les listes.

Ajouter une bibliothèque quand — et seulement quand :

| Besoin | Bibliothèque | Pourquoi elle reste justifiée |
| :-- | :-- | :-- |
| Profils de configuration multiples (par personnage, par spécialisation) | `AceDB-3.0` | Blizzard n'offre pas d'équivalent. |
| Icône de minimap | `LibDBIcon-1.0` + `LibDataBroker-1.1` | Le standard de fait ; l'écrire à la main est du travail perdu. |
| Polices et sons partagés entre addons | `LibSharedMedia-3.0` | Permet à l'utilisateur de réutiliser ses médias. |

Chaque ajout se paie en fichiers embarqués et en surface de casse au prochain patch.
Le proposer avec son coût, laisser l'utilisateur trancher (`rules/workflow.md`).

## Checklist avant de dire qu'un addon est fini

- [ ] `## Interface:` correspond au client installé.
- [ ] Chaque fichier `.lua` est listé dans le TOC — **et aucun fichier orphelin ne traîne**
      (un fichier non listé ne se charge pas : c'est du code mort qui ment au lecteur).
- [ ] `luacheck` passe sans avertissement, `stylua --check` est propre.
- [ ] Aucune globale créée hors des SavedVariables déclarées.
- [ ] Les SavedVariables sont initialisées dans `ADDON_LOADED`, avec migration versionnée.
- [ ] Le code testé **en contexte restreint** (combat, clé mythique+), pas seulement à vide.
- [ ] Aucun `OnUpdate` non throttlé.
- [ ] Les chaînes affichées passent par la table de locales, avec repli enUS.
- [ ] Un `/slashcommand` existe et affiche l'aide sans argument.
- [ ] `docs/` à jour si la logique est non triviale (`rules/documentation.md`).
- [ ] Rechargé en jeu, BugSack vide.

## Force de proposition

Ne jamais s'arrêter à la demande littérale. À chaque livraison, ajouter une courte section :

- **Features** — ce que le contexte rend évident et qui manque.
- **UX/UI** — lisibilité, encombrement, réglages par défaut, découvrabilité, comportement en
  combat. Un addon dont on doit lire le code pour comprendre les options est raté.
- **Périmètre** — faut-il enrichir cet addon ou en créer un autre ? Un addon par intention se
  désactive, se débogue et se partage plus facilement qu'un couteau suisse.

Argumenter (coût, perf, risque de casse au prochain patch), recommander, laisser trancher.

## Posture didactique

L'utilisateur lit le Lua mais découvre les conventions de l'écosystème. Expliquer le
*pourquoi* d'un pattern, nommer les concepts (taint, valeur secrète, SavedVariables, frame,
template, mixin) pour qu'ils soient cherchables ensuite, et s'appuyer sur ce qu'il connaît :
les parallèles avec le PHP monolithique et le CRUD sont souvent le chemin le plus court.

Doser selon l'enjeu — pas de cours magistral sur un changement de couleur.
