# Corpus local — où trouver un exemple réel

Le dossier `Interface/AddOns/` du client installé contient **une centaine d'addons à jour pour
12.1**. C'est la meilleure documentation disponible : du code écrit par des développeurs
seniors, qui tourne sur le patch courant, et dont on peut vérifier qu'il ne lève pas d'erreur.

> **Consulter le corpus avant de proposer un pattern.** Un `grep` y est une preuve. Une
> reconstitution de mémoire est une hypothèse.

## Racine

```sh
export WOW_ADDONS="$HOME/Games/battlenet/drive_c/Program Files (x86)/World of Warcraft/_retail_/Interface/AddOns"
```

Le chemin contient des espaces : toujours le citer.

## Requêtes types

```sh
# Qui utilise cette API, et comment ?
grep -rn "Settings.RegisterAddOnSetting" --include="*.lua" "$WOW_ADDONS" | head

# Quelles fonctions existent dans ce namespace ?
grep -rhoE "\bC_UnitAuras\.[A-Za-z_]+" --include="*.lua" "$WOW_ADDONS" | sort | uniq -c | sort -rn

# Quel événement est le plus utilisé pour ce besoin ?
grep -rhoE 'RegisterEvent\("[A-Z_]+"' --include="*.lua" "$WOW_ADDONS" | sort | uniq -c | sort -rn | head -30

# Voir un usage complet, avec son contexte
grep -rn -B5 -A15 "ScrollUtil.InitScrollBoxListWithScrollBar" --include="*.lua" "$WOW_ADDONS" | head -40
```

Le comptage d'occurrences est un signal fort : la forme la plus fréquente est presque toujours
la forme canonique.

## Carte des addons de référence

Tailles mesurées le 2026-08-21.

### Architecture et qualité générale

| Addon | Taille | Ce qu'on y apprend |
| :-- | :-- | :-- |
| **BugSack** + **!BugGrabber** | 4 600 + 580 lignes | **Le meilleur point de départ.** Petit, écrit par un développeur de référence (funkydude, auteur de BigWigs), et exemplaire sur : la Settings API en layout vertical (`config.lua`), le contrôle de santé au démarrage (`core.lua`), le TOC multi-édition avec directives localisées et `[AllowLoadGameType]`, l'intégration LibDataBroker. |
| **BigWigs_Core** | 11 400 lignes | Architecture modulaire à grande échelle : prototypes de boss, plugins, gestion du taint et des valeurs secrètes (`Core.lua:146`, `PluginPrototype.lua:86`). La référence en matière de performance sous contrainte. |
| **MinimapButtonButton** | 2 300 lignes | Addon récent, petit, `## Interface: 120100` seul. Bon exemple d'un addon retail moderne sans dette. |
| **TeleportMenu** | 4 700 lignes | Taille raisonnable, patterns modernes, code lisible. |

### Interface

| Addon | Ce qu'on y regarde |
| :-- | :-- |
| **Auctionator** | 343 fichiers, très découpé en mixins. Le meilleur exemple de ScrollBox/ScrollUtil et de composants réutilisables (`Source/Components/`). |
| **KeystoneLoot** | `libs/menu/Menu.lua` : implémentation complète d'un menu avec ScrollBox. |
| **Plumber** | 107 000 lignes d'UI moderne. Riche, mais gros — y chercher un pattern précis, pas le lire. |
| **RaiderIO** | `core.lua` : usage intensif de ScrollUtil, `CreateScrollBoxListLinearView`, `SetElementInitializer`. Contient aussi le commentaire qui documente la mort du CLEU (ligne 14719). |
| **Leatrix_Plus** | 30 000 lignes, `## Interface: 120100`. Un très grand nombre d'options natives : comment structurer une configuration volumineuse. |

### Valeurs secrètes et contraintes Midnight

| Addon | Ce qu'on y regarde |
| :-- | :-- |
| **SenseiClassResourceBar** | **La meilleure référence sur les valeurs secrètes.** `Bars/Abstract/PowerBar.lua` et `Bars/Abstract/Bar.lua` montrent la garde `issecretvalue`, le repli sur `UnitPowerPercent` avec courbe, et la mise en cache de la dernière valeur lisible. |
| **BigWigs_Core** | Repli de compatibilité `issecretvalue or function() return false end`, filtrage des GUID secrets avant envoi réseau. |
| **RCLootCouncil** | `Classes/Services/CommsRestrictions.lua` : gestion du verrou de communication inter-addons (`Enum.AddOnRestrictionType.Chat`). |
| **MPlusTimer** | `EventHandler.lua`, `Display.lua` : suivi de clé mythique sous restrictions. |
| **CooldownManagerCentered** | Cooldowns sous contrainte de secret. |

### Données et intégrations

| Addon | Ce qu'on y regarde |
| :-- | :-- |
| **HandyNotes** | Une API de plugin propre : comment un addon expose des points d'extension à d'autres addons. |
| **TomTom** | Cartes, points de passage, intégration à la minicarte. |
| **RareScanner** | 108 000 lignes, gros volumes de données statiques : comment les organiser sans plomber la mémoire. |
| **Clique** | Liaisons de clic sur les frames d'unité — le domaine le plus exposé au taint et aux frames protégées. |

## Lire un `## Interface` comme un indicateur de fraîcheur

```sh
grep -hi "^## Interface" "$WOW_ADDONS"/*/*.toc | sort | uniq -c | sort -rn
```

Un addon qui déclare `120100` est à jour pour le patch courant : son code est une référence
fiable. Un addon bloqué sur `120000` ou `120007` n'a pas été retouché depuis, et peut contenir
des patterns déjà périmés — le corpus n'est pas homogène, la date de dernière mise à jour fait
partie de la lecture.

Correspondance des numéros observés : `120000` = 12.0.0, `120005` = 12.0.5, `120007` = 12.0.7,
`120100` = 12.1.0. Les valeurs plus basses (`11509`, `20506`, `50504`, `40402`, `38002`) sont
les éditions Classic déclarées par les addons multi-édition.

## Précaution

Le corpus prouve qu'une API **existe et fonctionne**. Il ne prouve pas qu'elle est la
**meilleure** approche : un addon ancien peut porter du code hérité qui marche encore par
compatibilité. Croiser un usage isolé avec `warcraft.wiki.gg` avant d'en faire une
recommandation ; un usage massif et récent se passe de confirmation.
