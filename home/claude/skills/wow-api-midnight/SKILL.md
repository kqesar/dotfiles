---
name: wow-api-midnight
description: Référence hors-ligne de l'API d'addon World of Warcraft retail sur Midnight (patch 12.x) — valeurs secrètes, API supprimées et leurs remplaçantes, événements, namespaces C_*. À utiliser À LA PLACE d'une recherche web ou d'une reconstitution de mémoire dès qu'une tâche touche du Lua d'addon WoW, un fichier .toc, le dossier Interface/AddOns, une fonction UnitXxx/C_Xxx, un événement WoW, ou tout code qui appelle déjà l'API WoW. Le savoir pré-Midnight du modèle est périmé par construction : 138 globales ont été supprimées en 12.0.0 et le journal de combat est fermé aux addons. PORTÉE STRICTE — ne pas charger sur un projet Lua sans rapport avec WoW.
---

# API WoW — Midnight (12.x)

Snapshot pris le **2026-08-21** sur le patch **12.1.0 « Curse of Ula'tek »** (live depuis le
11 août 2026), client installé **12.1.0.69404**, `## Interface: 120100`.

## Pourquoi cette référence existe

Le patch 12.0.0 (20 janvier 2026) a lancé le projet *Addon Disarmament*. Ce n'est pas une
mise à jour d'API parmi d'autres : c'est un changement de modèle de sécurité qui invalide
la majorité de ce qu'un modèle de langage « sait » du développement d'addons.

Trois conséquences structurantes :

1. **Les valeurs secrètes.** Une grande partie des données de combat est retournée dans une
   boîte noire sur laquelle le code d'addon ne peut ni comparer, ni calculer, ni indexer.
2. **Le journal de combat est fermé.** `COMBAT_LOG_EVENT_UNFILTERED` **lève une erreur** à
   l'enregistrement. Le parsing du CLEU, socle historique des meters et des trackers, n'existe
   plus côté addon.
3. **138 globales supprimées** en 12.0.0, d'autres en 12.0.x et 12.1.

Conséquence pratique : du code écrit « de mémoire » dans le style Dragonflight ne se charge
pas, ou échoue silencieusement en combat. Cette référence est donc à consulter **avant**
d'écrire, pas après le premier bug.

## Protocole de vérification

Ordre de préséance, du plus fiable au moins fiable :

| Rang | Source | Pourquoi |
| :-- | :-- | :-- |
| 1 | **Le corpus local** — `Interface/AddOns/` | Du code qui tourne réellement sur le patch installé. Un `grep` y est une preuve, pas une hypothèse. |
| 2 | `/api`, `/dump`, `/etrace` en jeu | La documentation générée par le client lui-même. |
| 3 | `warcraft.wiki.gg` — `API_<Nom>`, `Patch_<version>/API_changes` | À jour et précis, mais parfois en retard sur un hotfix. |
| 4 | Mémoire du modèle | **Non recevable seule.** Sert à formuler une hypothèse à vérifier, jamais à conclure. |

Commande type pour le rang 1 :

```sh
cd "$WOW_RETAIL_DIR/Interface/AddOns"
grep -rn "C_UnitAuras\.GetUnitAuras" --include="*.lua" . | head
```

Si la vérification échoue, **le dire**. Ne jamais combler par une signature plausible : une
API inventée coûte plus cher qu'un « je n'ai pas pu confirmer ».

### Marquage des faits dans cette référence

- **[corpus]** — confirmé dans du code installé qui tourne sur 12.1.0. Fiabilité maximale.
- **[wiki]** — issu de `warcraft.wiki.gg`. Fiable, à revérifier si un détail de signature est critique.
- **[à vérifier]** — plausible mais non confirmé ici. Vérifier avant usage.

## Fraîcheur

Le hook `SessionStart` affiche la version du client à chaque session. **Si elle est
supérieure à 12.1.0**, ce snapshot a vieilli :

1. lire `warcraft.wiki.gg/wiki/Patch_<nouvelle version>/API_changes` ;
2. rejouer les `grep` du corpus local, qui aura été mis à jour par le client ;
3. corriger les fichiers de `references/` **dans le même lot de travail** et signaler la
   correction (obligation de `rules/workflow.md` : une doc contredite par la réalité se
   corrige immédiatement).

## Index des références

| Fichier | Contenu |
| :-- | :-- |
| `references/secret-values.md` | Le mécanisme central de 12.x : ce qui est permis, ce qui lève une erreur, les patterns qui marchent. **À lire avant tout code qui touche au combat.** |
| `references/api-migration.md` | Table ancien → nouveau. Les pièges où le modèle se trompe spontanément. |
| `references/events.md` | Événements par domaine, ceux qui lèvent une erreur, les mécanismes d'abonnement modernes. |
| `references/namespaces.md` | Carte des 155 namespaces `C_*` réellement présents, et le détail des nouveaux (12.0/12.1). |
| `references/recipes.md` | Recettes vérifiées pour des besoins courants — détecter une Delve, lire la progression d'un verrouillage de raid, garder une valeur potentiellement secrète. **À consulter avant de reconstituer une réponse de mémoire.** |

## Les cinq réflexes qui évitent 90 % des erreurs

1. **`## Interface:` = version du client**, lue depuis `.build.info`, jamais devinée.
2. **Aucun parsing de journal de combat.** Si le besoin ressemble à « détecter que X a lancé
   Y sur Z », partir de `references/events.md`, pas du CLEU.
3. **Toute valeur venant du combat est suspecte.** Avant un calcul dessus :
   `issecretvalue()`, ou une API qui fait le calcul côté client (`UnitPowerPercent` avec une
   courbe, `C_UnitAuras.GetAuraDurationRemainingPercent`).
4. **`C_*` d'abord.** Une globale courte et ancienne (`GetSpellInfo`, `UnitAura`,
   `IsAddOnLoaded`) est presque toujours supprimée ou dépréciée. Chercher son namespace.
5. **Tester en conditions restreintes.** Hors combat, tout marche — c'est le piège. Utiliser
   les CVars de forçage (`references/secret-values.md`) ou tester en donjon mythique+.
