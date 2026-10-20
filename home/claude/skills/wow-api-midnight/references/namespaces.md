# Namespaces `C_*` — carte d'orientation

**155 namespaces** ont été relevés dans le code installé sous `Interface/AddOns/` sur 12.1.0.
Le classement ci-dessous est un comptage d'occurrences réelles : il dit ce qui sert vraiment,
pas ce qui existe.

Un namespace absent de cette page n'est pas pour autant inexistant — vérifier avec
`/api <nom>` en jeu ou par un `grep` du corpus.

## Comment trouver le bon namespace

1. **Deviner le domaine, pas le nom.** L'API est découpée par sujet métier : sorts →
   `C_Spell`, objets → `C_Item`, sacs → `C_Container`, quêtes → `C_QuestLog`.
2. **Vérifier l'existence du namespace** avant celle de la fonction :
   ```sh
   grep -rhoE "\bC_Housing[A-Za-z]*\.[A-Za-z_]+" --include="*.lua" "$WOW_RETAIL_DIR/Interface/AddOns" | sort -u
   ```
3. **`/api C_Spell`** en jeu liste les fonctions du namespace avec leurs signatures et leurs
   annotations de secret. C'est la source générée par le client — elle ne ment pas.

## Les incontournables

| Namespace | Poids | À quoi ça sert |
| :-- | --: | :-- |
| `C_Item` | 1058 | Toute l'information objet : `GetItemInfo`, `GetItemInfoInstant`, `GetItemCount`, `GetDetailedItemLevelInfo`, `RequestLoadItemDataByID`. |
| `C_Timer` | 928 | `After` (693), `NewTicker` (121), `NewTimer` (112). **La seule façon correcte de temporiser** — voir la note ci-dessous. |
| `C_QuestLog` | 785 | Journal de quêtes. |
| `C_Map` | 632 | Cartes, coordonnées, `GetBestMapForUnit`. |
| `C_Spell` | 496 | Sorts. `GetSpellName` (130) devance `GetSpellInfo` (70) : quand seul le nom est voulu, ne pas construire la table entière. |
| `C_AddOns` | 466 | Métadonnées et chargement d'addons. |
| `C_UnitAuras` | 184 | Auras. Le domaine le plus contraint par les secrets. |
| `C_ChatInfo` | 182 | Messages inter-addons, préfixes, émotes. En 12.0 : `PerformEmote`, `CancelEmote`, `InChatMessagingLockdown`. |
| `C_CVar` | 143 | CVars. |
| `C_Container` | 89 | Sacs. |
| `C_SpellBook` | 91 | Grimoire — distinct de `C_Spell`, source d'erreur fréquente. |

### `C_Timer` — pourquoi c'est l'un des plus utilisés

```lua
C_Timer.After(0.5, function() ... end)          -- une fois, dans 0.5 s
local t = C_Timer.NewTicker(1, function() ... end)  -- toutes les secondes
t:Cancel()                                       -- toujours prévoir l'arrêt
```

C'est la bonne alternative à un `OnUpdate` qui s'exécute à chaque frame. Sur une machine
modeste, la différence entre un ticker à 1 Hz et un `OnUpdate` à 120 Hz est réelle.
`C_Timer.After(0, ...)` sert à reporter au prochain frame — le pattern de coalescence des
événements en rafale.

## Nouveaux namespaces de Midnight

| Namespace | Poids | Rôle |
| :-- | --: | :-- |
| `C_EncounterTimeline` | 153 | **La remplaçante du suivi de boss par CLEU.** 34 fonctions relevées : `AddScriptEvent`, `CancelScriptEvent`, `GetEventTimeRemaining`, `GetEventTimer`, `GetSortedEventList`, `GetTrackInfo`, `SetEventIconTextures`, `IsFeatureAvailable`… Point de départ obligatoire pour toute alerte de rencontre. [corpus] |
| `C_Secrets` | — | Savoir à l'avance si une donnée sera secrète. Détail dans `secret-values.md`. [corpus] |
| `C_RestrictedActions` | — | `IsAddOnRestrictionActive`, `GetAddOnRestrictionState`, `CheckAllowProtectedFunctions`. [corpus] |
| `C_StringUtil` | — | Formatage de valeurs secrètes : `CreateSecondsFormatter`, `CreateNumericRuleFormatter`, `RoundToNearestString`, `TruncateWhenZero`, `WrapString`, `WrapText`, `StripHyperlinks`, `EscapeLuaFormatString`. [corpus] |
| `C_CurveUtil` | — | `CreateCurve`, `CreateColorCurve`, `EvaluateColorValueFromBoolean`. Décrire « plage de valeurs → couleur » et laisser le moteur évaluer sur une valeur secrète. [corpus] |
| `C_DurationUtil` | — | `CreateDuration` : objet durée à passer à `Cooldown:SetCooldownFromDurationObject` ou `StatusBar:SetTimerDuration`. [corpus] |
| `C_DamageMeter` | — | `IsDamageMeterAvailable`, `GetAvailableCombatSessions`, `ResetAllCombatSessions`. Le meter est une fonction du client ; l'addon s'y branche. [corpus] |
| `C_AuraContainerUtil` | — | `ProcessCustomAuraButtonDurationTextOptions`. Accompagne le modèle `AuraContainer`. [corpus] |
| `C_CombatLog` | 0 | Filtres et rétention du journal de combat. **Aucun usage dans le corpus local** — signatures **[à vérifier]** via `/api C_CombatLog`. |
| `C_SettingsUtil` | — | `OpenSettingsPanel` (14). Nouveauté 12.0 utilisée par Ace3 pour ouvrir le panneau de réglages. [corpus] |
| `C_EventScheduler` | 88 | Planification d'événements côté client. [corpus] |
| `C_EncodingUtil` | 87 | Encodage/compression natifs — remplace avantageusement une lib Lua de sérialisation. [corpus] |

## Ajouts 12.1

Relevés dans les notes de patch **[wiki]**, à confirmer par `/api` avant usage :

- `C_HousingBlueprint` (18+ fonctions), `C_HousingLayout` (suivi d'étages, gestion des pièces),
  `C_HousingDecor` (placement, budget). Le logement est le gros morceau fonctionnel de 12.1.
- `C_Roleset` : `ApplyRolesetFilters`, `GetActiveAllowedRolesets`, `GetActiveBlockedRolesets`,
  plus `Frame:IsRolesetFiltered()`.
- `C_Discord` (18+ fonctions) : liaison de compte et de guilde.
- `C_CVar.AreCVarsLoaded()`.
- `C_Sound.PlaySoundWithOptions()`.

Le corpus confirme déjà l'existence de `C_Housing`, `C_HousingBasicMode`,
`C_HousingCustomizeMode`, `C_HousingCatalog`, `C_HousingNeighborhood`, `C_HouseEditor`. [corpus]

## Liste complète des namespaces relevés

Utile pour vérifier qu'un nom existe avant de l'écrire. **155 entrées**, extraites du code
installé sur 12.1.0 :

```
C_AccountStore C_ActionBar C_AddOns C_AlliedRaces C_APIs C_AreaPoiInfo C_ArtifactUI
C_AssistedCombat C_AuctionHouse C_AuraContainerUtil C_AutoComplete C_AzeriteEmpoweredItem
C_AzeriteEssence C_AzeriteItem C_Bank C_BattleNet C_Calendar C_CampaignInfo C_ChallengeMode
C_ChatBubbles C_ChatInfo C_ClassColor C_ClassTalents C_ClickBindings C_Club C_ColorUtil
C_CombatAudioAlert C_Container C_ContentTracking C_CooldownViewer C_CovenantCallings
C_Covenants C_CovenantSanctumUI C_CraftingOrders C_CreatureInfo C_CurrencyInfo C_Cursor
C_CurveUtil C_CVar C_DamageMeter C_DateAndTime C_DeathInfo C_DelvesUI C_DurationUtil
C_DyeColor C_EditMode C_EncodingUtil C_EncounterEvents C_EncounterJournal C_EncounterTimeline
C_EncounterWarnings C_Engraving C_EquipmentSet C_EventScheduler C_EventToastManager
C_EventUtils C_FriendList C_GamePad C_GameRules C_Garrison C_GossipInfo C_GuildInfo
C_Heirloom C_HouseEditor C_Housing C_HousingBasicMode C_HousingCatalog C_HousingCustomizeMode
C_HousingDecor C_HousingNeighborhood C_InstanceEncounter C_IslandsQueue C_Item
C_ItemInteraction C_ItemUpgrade C_KeyBindings C_LevelLink C_LFGInfo C_LFGList C_Log
C_LootHistory C_MajorFactions C_Map C_MapExplorationInfo C_MerchantFrame C_Minimap
C_ModifiedInstance C_MountJournal C_MythicPlus C_NamePlate C_NamePlateManager C_Navigation
C_PaperDollInfo C_PartyInfo C_PetBattles C_PetJournal C_Ping C_PlayerChoice C_PlayerInfo
C_PlayerInteractionManager C_PlayerMentorship C_ProfSpecs C_PvP C_QuestInfoSystem C_QuestLine
C_QuestLog C_QuestOffer C_QuestSession C_RaidLocks C_RemixArtifactUI C_Reputation
C_ResearchInfo C_RestrictedActions C_Scenario C_ScenarioInfo C_ScriptedAnimations C_SeasonInfo
C_Seasons C_Secrets C_SettingsUtil C_SocialUI C_Soulbinds C_Sound C_SpecializationInfo
C_Spell C_SpellActivationOverlay C_SpellBook C_StringUtil C_SummonInfo C_SuperTrack
C_TalkingHead C_TaskQuest C_TaxiMap C_Texture C_Timer C_Tooltip C_TooltipInfo C_ToyBox
C_TradeSkillUI C_Traits C_Transmog C_TransmogCollection C_TransmogOutfitInfo C_TransmogSets
C_TTSSettings C_UI C_UIFileAsset C_UIWidgetManager C_UnitAuras C_VignetteInfo C_VoiceChat
C_WeeklyRewards C_WowTokenPublic C_XMLUtil C_ZoneAbility
```

Cette liste alimente aussi le `.luacheckrc` de repli (`hooks/luacheckrc-wow`) : une faute de
frappe sur un namespace est signalée par le linter, contrairement aux autres globales de
l'API.
