# Architecture d'un addon

## Le modèle d'exécution, en une page

Un addon WoW n'est pas une application : c'est **un ensemble de fichiers Lua injectés dans un
processus déjà en cours**, partagé avec le client et avec tous les autres addons.

Parallèle PHP : imaginez que tous les plugins d'un CMS soient `include`és dans le même espace
de noms global, sans namespace, sans autoloader, et que le moindre `$config = ...` non
préfixé écrase celui du voisin. C'est exactement la situation — d'où l'obsession du zéro
globale.

Trois conséquences :

1. **Un seul environnement global partagé.** `_G` est commun. Tout ce qu'on y écrit est
   visible et écrasable par les autres addons.
2. **Pas de `require`.** L'ordre de chargement est déclaré dans le TOC, point.
3. **Le processus ne redémarre pas.** Un `/reload` recharge tout, mais entre deux rechargements
   l'état vit. Une fuite mémoire dure toute la session de jeu.

## Structure de dossiers

```
MonAddon/
├── MonAddon.toc          # manifeste : métadonnées + ordre de chargement
├── Locales.lua           # chaînes traduites — chargé en premier
├── Core.lua              # état, base de données, logique métier
├── Events.lua            # abonnements et répartition
├── Config.lua            # panneau d'options (Settings API)
├── UI.lua                # frames, si l'addon en a
├── .luacheckrc
├── stylua.toml
├── README.md
└── docs/
    └── ARCHITECTURE.md   # le pourquoi, en anglais
```

Un addon simple tient en trois fichiers. Découper dès qu'un fichier dépasse ~400 lignes ou
qu'il mélange deux responsabilités.

**Une règle de découpage vaut plus que les autres : `Core.lua` ne contient aucune frame et
aucun enregistrement auprès du client.** Pas de `CreateFrame`, pas de `RegisterEvent`, pas de
`SlashCmdList`, pas de `Settings.Register*`. Tous les points d'entrée vivent dans `Events.lua`.

Ce n'est pas de la propreté gratuite : c'est ce qui rend la logique **chargeable et testable
hors du jeu**, avec `lua5.1` et une poignée de simulacres (voir `tooling.md`). Un
`SlashCmdList.MONADDON = ...` au chargement de `Core.lua` suffit à rendre le fichier
inutilisable en dehors du client.

**Ordre imposé** : `Locales.lua` avant tout code qui affiche du texte ; `Core.lua` avant
`Events.lua` et `Config.lua`, qui en dépendent.

## Le fichier TOC

C'est le manifeste **et** l'autoloader. Un fichier `.lua` absent du TOC **n'est jamais
chargé** — pas d'erreur, pas d'avertissement, juste du code mort. C'est la source de confusion
numéro un dans les addons hérités.

```toc
## Interface: 120100
## Title: Mon Addon
## Title-frFR: Mon Addon
## Notes: Short English description shown in the tooltip
## Notes-frFR: Description française affichée dans l'infobulle
## Version: 1.0.0
## Author: Kaphéïne
## SavedVariables: MonAddonDB
## SavedVariablesPerCharacter: MonAddonCharDB
## IconTexture: Interface\Icons\INV_Misc_Book_09
## Category: Interface
## Category-frFR: Interface

Locales.lua
Core.lua
Events.lua
Config.lua
```

### Directives

| Directive | Rôle |
| :-- | :-- |
| `## Interface:` | **Obligatoire.** Numéro `MMmmpp` du client. Accepte plusieurs valeurs séparées par des virgules pour le multi-édition : `## Interface: 120100, 120007`. |
| `## Title:` | Nom affiché. Suffixable par locale (`## Title-frFR:`). |
| `## Notes:` | Infobulle dans la liste des addons. Suffixable par locale. |
| `## Version:` | Lisible via `C_AddOns.GetAddOnMetadata(name, "Version")` — l'unique source de vérité pour la version, à ne jamais dupliquer dans le code. |
| `## Author:` | |
| `## SavedVariables:` | Tables persistées **par compte**. |
| `## SavedVariablesPerCharacter:` | Tables persistées **par personnage**. |
| `## Dependencies:` / `## RequiredDeps:` | Addons obligatoires. L'addon ne charge pas sans eux. |
| `## OptionalDeps:` | Addons chargés **avant** celui-ci s'ils sont présents. Le bon outil pour s'intégrer à un autre addon sans en dépendre. |
| `## LoadOnDemand: 1` | Ne charge pas au démarrage ; `C_AddOns.LoadAddOn(name)` le charge. |
| `## DefaultState: disabled` | Désactivé par défaut. |
| `## Category:` | Regroupement dans la liste des addons. Suffixable par locale. |
| `## Group:` | Sous-regroupement sous un addon principal. |
| `## IconTexture:` / `## IconAtlas:` | Icône dans la liste. |
| `## AddonCompartmentFunc:` | Nom **global** de la fonction appelée depuis le compartiment d'addons de la minicarte. |
| `## X-...:` | Métadonnées libres, lisibles via `GetAddOnMetadata`. |

### Directives conditionnelles de fichier

Un fichier peut être conditionné à l'édition du jeu **[corpus, BugSack]** :

```toc
retail.lua [AllowLoadGameType mainline]
classic.lua [AllowLoadGameType classic]
```

12.1 ajoute `[Bootstrap]`, qui marque les fichiers de démarrage d'un addon à la demande. [wiki]

### Multi-édition par nom de fichier

Le client cherche d'abord un TOC suffixé, puis retombe sur le nom nu :
`MonAddon_Standard.toc` (Midnight), `_Mists`, `_Cata`, `_Wrath`, `_TBC`, `_Vanilla`,
`_Classic` (toutes éditions Classic), `MonAddon.toc` (repli). [wiki]

Pour un addon retail uniquement, un seul `MonAddon.toc` suffit.

## La table privée de l'addon

C'est le mécanisme d'encapsulation. Chaque fichier de l'addon reçoit deux arguments implicites :

```lua
local ADDON_NAME, ns = ...
```

- `ADDON_NAME` — le nom du dossier, donc de l'addon ;
- `ns` — **une table vide partagée par tous les fichiers de cet addon, et par eux seuls**.

C'est l'équivalent d'un namespace : le seul moyen propre de partager de l'état entre fichiers
sans toucher à `_G`.

```lua
-- Core.lua
local ADDON_NAME, ns = ...

ns.db = nil                    -- rempli à ADDON_LOADED
ns.L = ns.L or {}              -- locales

function ns.Print(msg)
    print(("|cff33ff99%s|r : %s"):format(ADDON_NAME, msg))
end
```

```lua
-- Events.lua
local ADDON_NAME, ns = ...

ns.Print("chargé")             -- disponible, sans aucune globale
```

**Ne jamais faire** `MonAddon = {}` en global. Les rares exceptions légitimes : le nom déclaré
dans `## AddonCompartmentFunc:` (le client le cherche dans `_G`) et une API publique
délibérément exposée à d'autres addons — auquel cas c'est `_G[ADDON_NAME] = ns`, documenté.

## Cycle de vie et SavedVariables

L'ordre exact des événements de démarrage est détaillé dans
`wow-api-midnight/references/events.md`. Le point critique ici :

> **Les SavedVariables valent `nil` jusqu'à `ADDON_LOADED`.** Toute initialisation faite à la
> lecture du fichier écrit dans le vide.

### Le pattern d'initialisation

```lua
local ADDON_NAME, ns = ...

-- Valeurs par défaut : source de vérité unique du schéma de configuration.
local DEFAULTS = {
    version = 1,
    enabled = true,
    seuil = 0.35,
}

-- Complète récursivement la base avec les valeurs par défaut manquantes.
-- Indispensable : une base sauvegardée par une version antérieure de l'addon
-- n'a pas les clés ajoutées depuis.
local function ApplyDefaults(db, defaults)
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            db[key] = db[key] or {}
            ApplyDefaults(db[key], value)
        elseif db[key] == nil then
            db[key] = value
        end
    end
end

-- Migrations de schéma, jouées dans l'ordre. Chaque étape fait passer la base
-- d'une version à la suivante et ne s'exécute qu'une fois.
local MIGRATIONS = {
    -- [1] = function(db) db.nouveauChamp = db.ancienChamp; db.ancienChamp = nil end,
}

local function Migrate(db)
    while MIGRATIONS[db.version] do
        MIGRATIONS[db.version](db)
        db.version = db.version + 1
    end
end

function ns.InitDatabase()
    MonAddonDB = MonAddonDB or {}
    ns.db = MonAddonDB
    ApplyDefaults(ns.db, DEFAULTS)
    Migrate(ns.db)
end
```

Trois raisons de faire ça dès le premier jour :

1. **Les valeurs par défaut manquantes**. Sans `ApplyDefaults`, ajouter une option dans la
   version 1.1 provoque un `nil` chez tous les utilisateurs de la 1.0.
2. **Les migrations**. Renommer une clé sans migration perd la configuration de l'utilisateur.
   Un `version` dans la base coûte une ligne et évite ça définitivement.
3. **C'est le même problème qu'une migration SQL** — à ceci près qu'il n'y a ni outil, ni
   rollback : la base est un fichier Lua réécrit à la déconnexion.

### Où écrire

`SavedVariables` est sérialisé à la déconnexion et au `/reload`. Rien n'est écrit avant.
`PLAYER_LOGOUT` est le dernier moment pour y déposer quelque chose.

Ne pas y stocker : des frames, des fonctions, des références circulaires (non sérialisables),
ni de gros volumes de données — le fichier est relu intégralement à chaque connexion.

## Découpage en modules

Pour un addon qui grossit, le pattern usuel sans dépendance externe :

```lua
-- Core.lua
ns.modules = {}

function ns.RegisterModule(name, module)
    ns.modules[name] = module
    return module
end

function ns.EnableModules()
    for name, module in pairs(ns.modules) do
        if module.OnEnable and ns.db.modules[name] ~= false then
            module:OnEnable()
        end
    end
end
```

Chaque module est une table avec `OnEnable` / `OnDisable`, activable indépendamment. C'est le
modèle de BigWigs, à une échelle bien plus grande — voir `references/local-corpus.md`.

Ne pas introduire cette structure sur un addon de 200 lignes : ce serait de la complexité
gratuite (`rules/backend-standards`, KISS).

## Commandes slash

```lua
SLASH_MONADDON1 = "/monaddon"
SLASH_MONADDON2 = "/ma"
SlashCmdList.MONADDON = function(input)
    local cmd, rest = input:match("^(%S*)%s*(.-)$")
    ...
end
```

`SLASH_<CLE><n>` et `SlashCmdList.<CLE>` sont des globales imposées par le client — l'une des
rares exceptions au zéro globale. **Choisir une clé préfixée par le nom de l'addon** :
`SLASH_MONADDON1`, jamais `SLASH_CONFIG1`.

Sans argument, une commande slash doit afficher son aide. Un addon dont on doit lire le code
pour connaître ses commandes est raté.
