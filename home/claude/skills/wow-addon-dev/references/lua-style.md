# Style Lua pour WoW

## Le Lua de WoW n'est pas le Lua standard

Le client embarque **Lua 5.1**, amputé et augmenté.

**Absent** — l'utiliser produit une erreur immédiate :

`require`, `module`, `package`, `io`, `dofile`, `loadfile`, `os` complet (seuls `os.time`,
`os.date`, `os.clock`, `os.difftime` survivent), l'accès disque en général.

**Ajouté** — extensions Blizzard, confirmées par usage dans le corpus :

| Catégorie | Fonctions |
| :-- | :-- |
| Chaînes | `strsplit` (119), `strjoin` (4), `strconcat`, `strtrim` (79), `strfind` (89), `strmatch` (45), `strsub` (55), `strlower` (88), `strupper` (6), `strrep`, `strbyte`, `strlen` (14), `format` (534) |
| Tables | `wipe` (141), `tContains` (24), `tInvert` (12), `tFilter` (6), `tCompare` (3), `tDeleteItem`, `tIndexOf` |
| Maths | `min` (42), `max` (56), `abs` (6), `ceil` (8), `floor` (163), `sqrt` (13), `mod` (5), `random` (3), `bit.*` |
| Sécurité | `securecall`, `issecure`, `issecurevariable` (6), `hooksecurefunc` (205), `forceinsecure` |
| Secrets | `issecretvalue` (45), `issecrettable`, `canaccessvalue` (28), `canaccesstable`, `scrubsecretvalues` (2) |
| Diagnostic | `geterrorhandler` (48), `seterrorhandler`, `debugstack` (6), `debugprofilestart` / `debugprofilestop` (12) |

Ces alias globaux (`format` pour `string.format`, `floor` pour `math.floor`) sont plus rapides
que la version qualifiée : une indexation de table en moins par appel. C'est la convention de
l'écosystème, à suivre.

## Zéro globale

La règle la plus importante, parce que l'espace global est partagé par tous les addons.

```lua
-- NON : crée une globale, écrase peut-être celle d'un autre addon
function UpdateBar() end
config = {}

-- OUI
local function UpdateBar() end
local config = {}
ns.config = {}          -- si le partage entre fichiers est nécessaire
```

`luacheck` attrape ça (code 111 « setting non-standard global »). C'est la première raison
d'avoir le linter dans la boucle.

## Locals et upvalues

Une variable locale est un accès direct au registre. Une globale est une indexation de table
dans `_G`. Sur du code appelé à chaque frame ou par événement en rafale, la différence compte.

```lua
-- En tête de fichier : on capture ce qu'on utilise en boucle.
local UnitHealth, UnitHealthMax = UnitHealth, UnitHealthMax
local format, floor = string.format, math.floor
local GetTime = GetTime
```

**À faire** pour les fonctions appelées dans une boucle chaude ou un `OnUpdate`.
**Inutile** pour une fonction appelée une fois au chargement — ce serait du bruit.

Effet de bord à connaître : capturer une fonction en upvalue **fige la version capturée**. Si
un autre addon la remplace via `hooksecurefunc` après le chargement, la version capturée
ignore le hook. Ne pas capturer les fonctions dont on veut voir les hooks.

## Le coût des tables

Le ramasse-miettes de Lua tourne dans le même thread que le rendu. Une allocation par frame,
c'est un micro-freeze périodique.

```lua
-- NON : une table neuve à chaque appel, appelé 120 fois par seconde
local function GetPosition()
    return { x = 1, y = 2 }
end

-- OUI : table réutilisée
local position = {}
local function GetPosition()
    position.x, position.y = 1, 2
    return position
end
```

`wipe(t)` vide une table sans la réallouer — à préférer systématiquement à `t = {}` quand la
table est recréée régulièrement.

Même logique pour les fermetures : `frame:SetScript("OnUpdate", function() ... end)` dans une
boucle crée une fonction par itération. Définir le gestionnaire une fois, à l'extérieur.

## `OnUpdate` : le principal gouffre à performance

`OnUpdate` s'exécute **à chaque frame rendue** — 60, 120, 240 fois par seconde selon l'écran.
Un addon avec un `OnUpdate` non throttlé multiplié par vingt addons, et l'utilisateur perd des
images par seconde sans comprendre pourquoi.

### Toujours préférer un timer

```lua
-- Rafraîchissement à 1 Hz : un ticker, pas un OnUpdate.
local ticker = C_Timer.NewTicker(1, UpdateDisplay)
-- ... et toujours prévoir l'arrêt
ticker:Cancel()
```

### Si `OnUpdate` est réellement nécessaire — le throttle

Une barre de progression fluide en est un cas légitime. Alors :

```lua
local THROTTLE = 0.1   -- 10 rafraîchissements par seconde suffisent à l'œil
local elapsedSinceUpdate = 0

frame:SetScript("OnUpdate", function(self, elapsed)
    elapsedSinceUpdate = elapsedSinceUpdate + elapsed
    if elapsedSinceUpdate < THROTTLE then
        return
    end
    elapsedSinceUpdate = 0
    -- travail réel ici
end)
```

**Et déconnecter le script quand il n'y a rien à faire** — un `OnUpdate` qui ne fait que
retourner coûte quand même un appel de fonction par frame :

```lua
frame:SetScript("OnUpdate", nil)   -- au repos
```

12.1 ajoute `Frame:SetOnUpdateMode(mode)` pour contrôler quand `OnUpdate` s'exécute. [wiki]

## Coalescer les rafales d'événements

`GROUP_ROSTER_UPDATE`, `BAG_UPDATE`, `UNIT_AURA` arrivent par paquets de plusieurs dizaines.
Traiter chaque occurrence est du gaspillage pur.

```lua
local updatePending = false

local function ProcessUpdate()
    updatePending = false
    -- travail réel, une seule fois
end

local function OnBurstEvent()
    if updatePending then return end
    updatePending = true
    C_Timer.After(0, ProcessUpdate)   -- au prochain frame, après la rafale
end
```

`C_Timer.After(0, ...)` reporte au frame suivant : toutes les occurrences de la rafale
retombent sur un seul traitement. C'est le pattern de coalescence standard de l'écosystème.

## Chaînes

```lua
-- NON : une chaîne intermédiaire par concaténation, dans une boucle
local s = ""
for i = 1, n do s = s .. items[i] .. ", " end

-- OUI
local parts = {}
for i = 1, n do parts[i] = items[i] end
local s = table.concat(parts, ", ")
```

Pour du formatage, `format("%s : %d", nom, valeur)` est plus lisible et plus rapide qu'une
chaîne de `..`. Rappel : `string.format` **accepte les valeurs secrètes**, ce qui en fait le
seul moyen d'afficher une donnée de combat opaque.

## Pièges classiques

### `#` sur une table trouée

```lua
local t = { 1, nil, 3 }
print(#t)   -- 1 ou 3, indéfini
```

Le comportement de `#` sur une séquence trouée n'est pas spécifié. Maintenir un compteur
explicite, ou ne jamais mettre de `nil` au milieu — utiliser `table.remove` qui décale.

### `pairs` vs `ipairs`

`ipairs` s'arrête au premier `nil`. `pairs` parcourt tout mais **dans un ordre non
déterministe** : ne jamais s'en servir pour produire un affichage ordonné sans trier ensuite.

### `a and b or c` s'effondre quand `b` peut valoir `false`

L'idiome ternaire de Lua a un trou, et il est silencieux :

```lua
-- Le "ternaire" habituel
local value = condition and ifTrue or ifFalse

-- Mais si ifTrue vaut false ou nil, l'expression retourne TOUJOURS ifFalse :
local default = defaults[section] and defaults[section][key] or defaults[key]
--                                    ^ vaut false pour une option désactivée
--                                      par défaut → on récupère defaults[key],
--                                      c'est-à-dire nil.
```

C'est le piège classique dès qu'on manipule des booléens — donc en permanence dans un panneau
d'options, où la moitié des réglages sont à `false` par défaut. Le symptôme n'est pas une
erreur mais une valeur `nil` là où on attendait `false`, souvent découverte bien plus tard.

Dès que la valeur « vraie » peut être `false` ou `nil`, écrire un `if` explicite :

```lua
local function DefaultFor(section, key)
    local defaults = ACL.defaultSettings
    if section then
        defaults = defaults[section]
    end
    return defaults[key]
end
```

### `table.wipe` vs réassignation

`t = {}` laisse l'ancienne table au ramasse-miettes. `wipe(t)` réutilise l'allocation.

### Comparer un secret

`if health > maxHealth * 0.35 then` lève une erreur si `health` est secret. Voir
`wow-api-midnight/references/secret-values.md`.

### `pcall` masque les vraies erreurs

Entourer du code de `pcall` pour « éviter les erreurs » cache les bugs au lieu de les corriger.
BugGrabber/BugSack existent pour les voir. `pcall` se réserve aux appels dont l'échec est
attendu et rattrapable (désérialisation d'une entrée utilisateur, par exemple).

## Nommage

| Élément | Convention | Exemple |
| :-- | :-- | :-- |
| Variables et fonctions locales | `camelCase` / `PascalCase` pour les fonctions | `local currentHealth`, `local function UpdateBar()` |
| Champs de la table d'addon | `PascalCase` pour les fonctions, `camelCase` pour les données | `ns.UpdateBar()`, `ns.db` |
| Constantes de fichier | `SCREAMING_SNAKE_CASE` | `local MAX_BARS = 10` |
| Frames nommées | Préfixées par le nom de l'addon | `MonAddonOptionsPanel` |
| Globales imposées | Préfixées par le nom de l'addon | `SLASH_MONADDON1` |

**Identifiants en anglais, commentaires en français.** Le code se lit comme celui de
l'écosystème ; les explications sont dans la langue de l'utilisateur.

## Commentaires

Ce qui mérite un commentaire :

- un invariant non évident (« cette table doit rester triée par expiration ») ;
- un contournement (« `SetToDefaults` efface aussi la mise en forme, d'où la reconstruction ») ;
- une contrainte du moteur (« `PLAYER_ENTERING_WORLD` refire à chaque instance ») ;
- une valeur magique et sa provenance.

Ce qui n'en mérite pas : la paraphrase du code. `-- incrémente le compteur` au-dessus de
`count = count + 1` est du bruit.
