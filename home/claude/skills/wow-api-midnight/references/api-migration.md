# Migration des API — ce que le modèle écrit spontanément à tort

Table de correspondance ancien → actuel. Elle est **ciblée** : elle ne recense pas tout, elle
recense ce qu'un modèle entraîné avant Midnight produit naturellement et qui est aujourd'hui
faux.

Les remplaçantes marquées **[corpus]** sont confirmées dans du code installé qui tourne sur
12.1.0 — le nombre entre parenthèses est le nombre d'occurrences trouvées, un bon indicateur
de « c'est bien la forme canonique ».

## Règle générale

> Une globale courte, ancienne et non préfixée est presque toujours supprimée ou dépréciée.
> Chercher son namespace `C_*`.

Blizzard déplace l'API vers des namespaces depuis Legion, et 12.0.0 a supprimé d'un coup
**138 globales** qui n'étaient jusque-là que dépréciées. Le repli « la globale existe encore
en alias » n'est plus fiable.

## Sorts

| Périmé | Actuel | Note |
| :-- | :-- | :-- |
| `GetSpellInfo(id)` | `C_Spell.GetSpellInfo(id)` **[corpus 70]** | Retourne désormais une **table**, plus une liste de valeurs. Le déballage `local name, _, icon = GetSpellInfo(id)` est faux. |
| — | `C_Spell.GetSpellName(id)` **[corpus 130]** | La forme la plus utilisée : quand seul le nom est voulu, éviter de construire la table entière. |
| `GetSpellTexture(id)` | `C_Spell.GetSpellTexture(id)` **[corpus 64]** | |
| `GetSpellCooldown(id)` | `C_Spell.GetSpellCooldown(id)` **[corpus 35]** | Table. Voir aussi `C_Spell.GetSpellCooldownDuration` **[corpus 15]**, qui rend un objet durée exploitable avec `Cooldown:SetCooldownFromDurationObject`. |
| `GetSpellCharges(id)` | `C_Spell.GetSpellCharges(id)` **[corpus 19]** | |
| `IsUsableSpell(id)` | `C_Spell.IsSpellUsable(id)` **[corpus 14]** | |
| `GetSpellLink(id)` | `C_Spell.GetSpellLink(id)` **[corpus 9]** | |
| `IsSpellKnown(id)` | `C_SpellBook.IsSpellKnown(id)` **[corpus 13]** | Attention : `C_SpellBook`, pas `C_Spell`. |
| `IsSpellKnownOrOverridesKnown` | `C_SpellBook.IsSpellKnownOrInSpellBook(id)` **[corpus 7]** | |
| `FindSpellOverrideByID` | `C_SpellBook.FindSpellOverrideByID(id)` **[corpus 4]** | |

## Objets

| Périmé | Actuel | Note |
| :-- | :-- | :-- |
| `GetItemInfo(item)` | `C_Item.GetItemInfo(item)` **[corpus 177]** | |
| `GetItemInfoInstant(item)` | `C_Item.GetItemInfoInstant(item)` **[corpus 162]** | Synchrone, sans requête serveur. À préférer quand l'ID/type suffit. |
| `GetItemCount(item)` | `C_Item.GetItemCount(item)` **[corpus 117]** | |
| `GetDetailedItemLevelInfo` | `C_Item.GetDetailedItemLevelInfo(item)` **[corpus 26]** | |
| `GetItemQualityColor` | `C_Item.GetItemQualityColor(q)` **[corpus 16]** | |
| `GetContainerNumSlots(bag)` | `C_Container.GetContainerNumSlots(bag)` **[corpus 23]** | |
| `GetContainerItemInfo(b, s)` | `C_Container.GetContainerItemInfo(b, s)` **[corpus 14]** | Retourne une **table** depuis 10.0, plus une liste. |
| `GetContainerItemLink(b, s)` | `C_Container.GetContainerItemLink(b, s)` **[corpus 12]** | |
| `UseContainerItem(b, s)` | `C_Container.UseContainerItem(b, s)` **[corpus 3]** | |

## Auras — le domaine le plus remanié

| Périmé | Actuel | Note |
| :-- | :-- | :-- |
| `UnitAura(unit, i, filter)` | `C_UnitAuras.GetAuraDataByIndex(unit, i, filter)` **[corpus 32]** | Déprécié en 10.2.5, et **secret par index** dans les contextes restreints (`C_Secrets.ShouldUnitAuraIndexBeSecret`). |
| `UnitBuff` / `UnitDebuff` | `C_UnitAuras.GetBuffDataByIndex` **[corpus 7]** / `GetDebuffDataByIndex` **[corpus 3]** | |
| `UnitAuraBySlot` / `UnitAuraSlots` | `C_UnitAuras.GetAuraDataBySlot` | |
| boucle sur les index | `C_UnitAuras.GetUnitAuras(unit, filter [, maxCount [, sortRule [, sortDirection]]])` | La forme moderne : tri fait par le moteur. Voir plus bas. |
| suivi manuel des auras | `C_UnitAuras.GetPlayerAuraBySpellID(id)` **[corpus 54]**, `GetUnitAuraBySpellID` **[corpus 7]**, `GetAuraDataByAuraInstanceID` **[corpus 6]** | Interroger par identité plutôt qu'énumérer : **un sort non secret reste lisible même en contexte restreint.** C'est le contournement légitime. |

### `C_UnitAuras.GetUnitAuras` — [wiki]

```lua
auras = C_UnitAuras.GetUnitAuras(unit, filter [, maxCount [, sortRule [, sortDirection]]])
```

`filter` est une chaîne de filtres séparés par `|` (`"HARMFUL|PLAYER"`).

`Enum.UnitAuraSortRule` : `Unsorted` (0), `Default` (1), `BigDefensive` (2), `Expiration` (3),
`ExpirationOnly` (4), `Name` (5), `NameOnly` (6). `Enum.UnitAuraSortDirection` par défaut `Normal`.

Champs de `AuraData` marqués **`NeverSecret`** — toujours lisibles, même en combat :
`auraInstanceID`, `isFromPlayerOrPlayerPet`, `isHarmful`, `isHelpful`, `isNameplateOnly`,
`isRaid`. Bâtir la logique sur ces champs-là quand c'est possible.

### Boutons d'aura : ne plus les construire à la main

12.1 introduit `AuraContainer` / `AuraGroup`, qui gère lui-même la création, l'ancrage et le
redimensionnement des boutons. Le conteneur peut être créé en combat, et les boutons
deviennent *forbidden* quand les auras sont secrètes — d'où l'impossibilité de les bricoler.

Méthodes ajoutées en 12.1 — [wiki] : `AddAuraGroup()`, `AddAuraSlot()`, `AddItemEnchantment()`,
`SetCancelAuraButtons()`, `GetAuraGroupFrame()`, `SetAuraGroupFilterString()`. Le rappel
`initializeFrame` est le seul point de configuration avant application des restrictions.

**`SecureAuraHeaderTemplate` est supprimé** sur retail en 12.1. Tout code de barre de buffs
personnalisée qui s'appuie dessus est à réécrire sur `AuraContainer`.

## Addons et métadonnées

| Périmé | Actuel | Note |
| :-- | :-- | :-- |
| `IsAddOnLoaded(name)` | `C_AddOns.IsAddOnLoaded(name)` **[corpus 179]** | |
| `GetAddOnMetadata(name, field)` | `C_AddOns.GetAddOnMetadata(name, field)` **[corpus 129]** | |
| `LoadAddOn(name)` | `C_AddOns.LoadAddOn(name)` **[corpus 39]** | |
| `GetAddOnInfo(name)` | `C_AddOns.GetAddOnInfo(name)` **[corpus 34]** | |
| `GetAddOnEnableState(...)` | `C_AddOns.GetAddOnEnableState(name, character)` **[corpus 31]** | **L'ordre des arguments a changé** en 11.0 : le nom d'abord. |
| `UIParentLoadAddOn(name)` | `LoadAddOnWithErrorHandling(name)` | **Supprimé en 12.1.** [wiki] |

Le repli `(C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata` n'a plus d'intérêt sur
retail : la globale n'existe plus, la branche de repli est du code mort.

## CVars et réglages

| Périmé | Actuel | Note |
| :-- | :-- | :-- |
| `SetCVar` / `GetCVar` | `C_CVar.SetCVar` **[corpus 69]** / `C_CVar.GetCVar` **[corpus 22]** | |
| `GetCVarBool` | `C_CVar.GetCVarBool` **[corpus 21]** | |
| — | `C_CVar.AreCVarsLoaded()` | Ajouté en 12.1. [wiki] |
| `InterfaceOptions_AddCategory(panel)` | `Settings.RegisterCanvasLayoutCategory` + `Settings.RegisterAddOnCategory` | Refonte en 10.0, changements cassants en 11.0.2. |
| `InterfaceOptionsFrame_OpenToCategory` | `Settings.OpenToCategory(categoryID)` ou `C_SettingsUtil.OpenSettingsPanel` **[corpus 14]** | |

Panneau d'options : préférer le **layout vertical** au canvas manuel — voir
`wow-addon-dev/references/ui-ux.md`.

## Journal de combat — fermé aux addons

C'est la rupture la plus lourde de Midnight.

| Périmé | État |
| :-- | :-- |
| `COMBAT_LOG_EVENT` | **Lève une erreur à l'enregistrement.** |
| `COMBAT_LOG_EVENT_UNFILTERED` | **Lève une erreur à l'enregistrement.** |
| `CombatLogGetCurrentEventInfo()` | Restreinte, plus exploitable pour du parsing d'addon. |
| `CombatLogAddFilter`, `CombatLogClearEntries` | Supprimées en 12.0.0. |

Remplacements :

- **`COMBAT_LOG_MESSAGE`** — [wiki] : `message, colorR, colorG, colorB, order`.
  `message` est **un message préformaté protégé par un enrobage `|K`** : affichable, non
  analysable. `order` est un `Enum.CombatLogMessageOrder` (`Newest` = 0, `Oldest` = 1).
  Autrement dit : on peut refaire la *fenêtre* de journal de combat, pas un parseur.
- **`C_CombatLog`** — namespace de configuration des filtres et de rétention des entrées.
  Fonctions associées : `COMBAT_LOG_EVENT_INTERNAL_UNFILTERED`,
  `COMBAT_LOG_APPLY_FILTER_SETTINGS`. *Aucun addon du corpus local ne l'utilise* — signature
  exacte **[à vérifier]** via `/api C_CombatLog`.
- **`C_DamageMeter`** — [corpus] : `IsDamageMeterAvailable()`, `GetAvailableCombatSessions()`,
  `ResetAllCombatSessions()`. Le meter est désormais une fonctionnalité du client ; un addon
  s'y branche au lieu de compter lui-même.
- **`C_EncounterTimeline`** — [corpus, 34 fonctions] : le remplacement officiel du suivi de
  rencontre par CLEU. `AddScriptEvent`, `GetEventTimeRemaining`, `GetSortedEventList`,
  `SetEventIconTextures`… C'est là qu'il faut chercher pour tout ce qui ressemble à une
  alerte de boss.

> Si un besoin s'exprime par « détecter que X lance Y sur Z », partir de
> `references/events.md` et de `C_EncounterTimeline`, jamais du journal de combat.
>
> Note : le **fichier** `WoWCombatLog.txt` produit par `/combatlog` est écrit par le client
> lui-même. Il n'est pas concerné par ces restrictions — un addon qui se contente
> d'activer/désactiver l'enregistrement reste parfaitement valide.

## Globales Lua supprimées

| Périmé | Actuel |
| :-- | :-- |
| `getglobal(name)` | `_G[name]` — **supprimé en 12.1** [wiki] |
| `setglobal(name, v)` | `_G[name] = v` — **supprimé en 12.1** [wiki] |
| `CanAccessObject(obj)` | `FrameScriptObject:CanBeAccessedInContext()` — remplacé en 12.1 [wiki] |

## Ajouts utiles à connaître

12.0 — [wiki] :

- `Frame:RegisterEventCallback(event, callback)` et `Frame:RegisterUnitEventCallback(...)` :
  un rappel par événement, sans le grand `if event == ... elseif` central.
- `Region:SetAlphaFromBoolean(bool)` : accepte un booléen secret.
- `Cooldown:SetCooldownFromDurationObject(duration)`.
- `FrameScriptObject:HasSecretValues()`.

12.1 — [wiki] :

- `Frame:ResizeToBoundsRect()` : redimensionner au contenu sans lire les dimensions
  (indispensable avec les ancres secrètes).
- `Frame:SetOnUpdateMode(mode)` : contrôler quand `OnUpdate` s'exécute.
- `VectorGraphics` : nouveau type d'objet, textures SVG rendues à la résolution native. Les
  textures classiques acceptent aussi `file="Chemin/Vers/Texture.svg"`.
- `C_Sound.PlaySoundWithOptions(...)` : volume surchargeable.
- `Texture:SetRadialProgressBarPercent/Reverse/Feather(...)` : jauges radiales natives.
- `C_Roleset.*` et `Frame:IsRolesetFiltered()` ; `C_HousingBlueprint`, `C_HousingLayout`,
  `C_HousingDecor` ; `C_Discord.*`.
- TOC : directive `[Bootstrap]` pour les fichiers de démarrage des addons à la demande ;
  `<Mixins source="local">` et KeyValues `type="local"` en XML, pour accéder à la table
  privée de l'addon sans passer par une globale.
