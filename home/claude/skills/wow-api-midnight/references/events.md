# Événements — Midnight (12.x)

Le classement de fréquence vient d'un comptage des `RegisterEvent` dans le code installé sous
`Interface/AddOns/` sur 12.1.0. Il indique ce que les addons matures utilisent réellement.

## Les trois façons de s'abonner

### 1. La frame porteuse d'événements — le socle

```lua
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, ...)
    -- répartition manuelle
end)
```

Universel et sans dépendance. Défaut : un `if event == ... elseif` central qui grossit.
Pattern usuel pour l'éviter — une table de gestionnaires :

```lua
local handlers = {}

function handlers.PLAYER_LOGIN() ... end
function handlers.PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi) ... end

frame:SetScript("OnEvent", function(_, event, ...)
    handlers[event](...)   -- l'absence de gestionnaire est un bug : on veut l'erreur
end)
for event in pairs(handlers) do frame:RegisterEvent(event) end
```

L'itération sur `handlers` garantit qu'on n'oublie jamais un `RegisterEvent` — la déclaration
du gestionnaire *est* l'abonnement.

### 2. `RegisterEventCallback` — un rappel par événement (12.0)

```lua
frame:RegisterEventCallback("PLAYER_REGEN_DISABLED", OnCombatStart)
frame:RegisterUnitEventCallback("UNIT_HEALTH", OnHealth, "player")
```

Ajouté en 12.0. [wiki] Supprime le répartiteur central. À préférer pour du code neuf quand on
n'a pas besoin d'itérer sur l'ensemble des abonnements.

### 3. `EventRegistry` — le bus interne de Blizzard — [corpus, 82 usages]

```lua
EventRegistry:RegisterCallback("MonAddon.EtatChange", function(_, valeur) ... end, self)
EventRegistry:TriggerEvent("MonAddon.EtatChange", valeur)
```

Deux emplois distincts :

- **s'accrocher à un événement d'UI Blizzard** qui n'est pas un événement de jeu (ouverture
  d'un panneau, changement d'onglet…) ;
- **faire communiquer les modules d'un même addon** sans les coupler. C'est l'équivalent d'un
  event dispatcher applicatif : le module qui émet ne connaît pas ses abonnés.

Variantes : `RegisterFrameEventAndCallback` **[corpus 15]** (abonne à un événement de jeu *et*
enregistre le rappel en une fois), `RegisterFrameEventAndCallbackWithHandle` (retourne un
handle pour se désabonner proprement).

**Nommer ses événements avec un préfixe d'addon.** `EventRegistry` est partagé par tout le
client : un `"Update"` nu est une collision qui attend son heure.

## Cycle de vie — l'ordre exact

C'est le piège numéro un des SavedVariables.

| Événement | Moment | Ce qui est disponible |
| :-- | :-- | :-- |
| `ADDON_LOADED` (arg1 = nom) | Fichiers de l'addon chargés | **Les SavedVariables de CET addon** — et rien du monde |
| `PLAYER_LOGIN` | Tous les addons chargés, UI prête | API d'unité fiable, autres addons présents |
| `PLAYER_ENTERING_WORLD` (`isInitialLogin`, `isReloadingUi`) | Monde chargé — **et à chaque changement de zone instanciée** | Tout |

Règles :

- **Initialiser la base de données dans `ADDON_LOADED`**, en filtrant sur son propre nom. Les
  SavedVariables sont `nil` avant.
- **Construire l'UI et lire l'état du joueur dans `PLAYER_LOGIN`.** Interroger `UnitLevel`
  dans `ADDON_LOADED` peut renvoyer `0`.
- **`PLAYER_ENTERING_WORLD` se répète.** Il refire à chaque entrée en donjon, en raid, en
  champ de bataille. Tout code de setup unique doit se garder, ou utiliser les deux arguments.
- Se désabonner de `ADDON_LOADED` une fois traité : il refire pour chaque addon à la demande.

```lua
function handlers.ADDON_LOADED(name)
    if name ~= ADDON_NAME then return end
    frame:UnregisterEvent("ADDON_LOADED")
    InitialiserBaseDeDonnees()
end
```

`PLAYER_LOGOUT` **[corpus 45]** est le dernier moment pour écrire dans les SavedVariables.
Aucune API réseau n'y répond — uniquement de la sérialisation locale.

## Événements courants par domaine

Le nombre entre parenthèses est la fréquence dans le corpus.

### Combat et état du joueur

| Événement | Note |
| :-- | :-- |
| `PLAYER_REGEN_DISABLED` (79) | **Entrée** en combat. Nom contre-intuitif : la régénération s'arrête. |
| `PLAYER_REGEN_ENABLED` (133) | **Sortie** de combat. Le moment où les actions protégées redeviennent possibles — y différer tout ce qui a été bloqué par `InCombatLockdown()`. |
| `UNIT_HEALTH` (128) | Points de vie. Secret en contexte restreint. |
| `UNIT_POWER_FREQUENT` (30) / `UNIT_POWER_UPDATE` (17) | `FREQUENT` est nettement plus bavard : ne l'utiliser que pour une barre de ressource, et toujours en `RegisterUnitEvent` pour filtrer sur l'unité. |
| `UNIT_AURA` (29) | **Charge utile entièrement secrète** en contexte d'aura restreint (12.1). Sert de signal « quelque chose a changé », pas de source de données. |
| `UNIT_SPELLCAST_SUCCEEDED` (174) | L'événement le plus enregistré du corpus. Le socle du suivi de sorts depuis la fermeture du CLEU. |
| `UNIT_SPELLCAST_START` (18) / `_STOP` (12) / `_INTERRUPTED` (9) / `_CHANNEL_START` (14) / `_CHANNEL_STOP` (15) | Barres de cast. |
| `PLAYER_TARGET_CHANGED` (24), `UPDATE_MOUSEOVER_UNIT` (20), `UNIT_TARGET` (33) | Ciblage. |
| `MODIFIER_STATE_CHANGED` (23) | Maj/Ctrl/Alt. |
| `GLOBAL_MOUSE_DOWN` (16) / `GLOBAL_MOUSE_UP` (14) | Clic n'importe où — pour fermer un menu contextuel. |

### Groupe, instances, rencontres

| Événement | Note |
| :-- | :-- |
| `GROUP_ROSTER_UPDATE` (31) | Composition du groupe. Bavard : throttler le traitement. |
| `ENCOUNTER_START` (13) / `ENCOUNTER_END` (12) | Début/fin de rencontre de boss. `ENCOUNTER_END` porte le succès et la difficulté. |
| `INSTANCE_ENCOUNTER_ENGAGE_UNIT` (61) | Unités `boss1`..`bossN` engagées. |
| `BOSS_KILL` (49) | |
| `CHALLENGE_MODE_START` (10) / `CHALLENGE_MODE_COMPLETED` (12) | Clé mythique. |
| `ZONE_CHANGED_NEW_AREA` (33), `ZONE_CHANGED` (15), `ZONE_CHANGED_INDOORS` (25) | Changement de zone. Combiner avec `GetInstanceInfo()` plutôt que de se fier au seul nom de zone. |

### Nouveaux — spécifiques à Midnight

| Événement | Note |
| :-- | :-- |
| `ADDON_RESTRICTION_STATE_CHANGED` (20) | **Un `Enum.AddOnRestrictionType` a changé d'état.** C'est le signal qui dit « les données viennent de devenir secrètes / de redevenir lisibles ». Y basculer entre mode complet et mode dégradé plutôt que de tester à chaque frame. |
| `ENCOUNTER_TIMELINE_EVENT_ADDED` (37) / `_REMOVED` (20) / `_STATE_CHANGED` (20) | La timeline de rencontre, remplaçante officielle du suivi par CLEU. À croiser avec les 34 fonctions de `C_EncounterTimeline`. |
| `ENCOUNTER_WARNING` (9) | Avertissement de rencontre émis par le client. |
| `COMBAT_LOG_MESSAGE` | `message, colorR, colorG, colorB, order`. Message préformaté sous enrobage `|K` : **affichable, non analysable**. [wiki] |
| `PARTY_KILL` | Rétabli en 12.0.1, avec les GUID de l'attaquant et de la cible. [wiki] |
| `UNIT_DIED`, `PLAYER_TARGET_DIED` | Parmi les 76 événements ajoutés en 12.0.0 pour compenser la fermeture du CLEU. [wiki] |
| `DAMAGE_METER_CURRENT_SESSION_UPDATED` | À croiser avec `C_DamageMeter`. [wiki] |

### Interface, sac, chat

`ADDON_LOADED` (80), `PLAYER_ENTERING_WORLD` (127), `PLAYER_LOGIN` (117), `PLAYER_LOGOUT` (45),
`BAG_UPDATE` (17), `BAG_UPDATE_DELAYED` (12) — préférer systématiquement la version `DELAYED`,
qui coalesce une rafale de mises à jour en une seule ; `CHAT_MSG_ADDON` (26),
`CVAR_UPDATE` (24), `PLAYER_SPECIALIZATION_CHANGED` (33), `PLAYER_EQUIPMENT_CHANGED` (15),
`NAME_PLATE_UNIT_ADDED` (18) / `_REMOVED` (12).

## Événements qui lèvent une erreur

`COMBAT_LOG_EVENT` et `COMBAT_LOG_EVENT_UNFILTERED` **provoquent une erreur Lua** à
l'enregistrement sur retail depuis 12.0.0.

Preuve directe dans le corpus, commentaire de RaiderIO (`RaiderIO/core.lua:14719`) :

```lua
-- "COMBAT_LOG_EVENT_UNFILTERED", -- TODO: This didn't error on beta, but started to upon 12.0 release
```

Les occurrences restantes du corpus sont soit des modules de contenu ancien devenus inertes
(BigWigs Battle for Azeroth, Legion), soit des chemins Classic
(`BigWigs_Core/BossPrototype_Classic.lua`) — **le système de secrets et ces restrictions sont
entièrement désactivés sur Classic**. Ne pas en conclure que c'est encore permis sur retail.

## Bonnes pratiques

- **`RegisterUnitEvent` plutôt que `RegisterEvent`** dès qu'un événement porte une unité :
  `frame:RegisterUnitEvent("UNIT_HEALTH", "player", "target")`. Le filtrage est fait par le
  moteur, pas par un `if unit ~= "player" then return end` appelé des milliers de fois.
- **Se désabonner de ce qu'on n'écoute plus.** Un abonnement oublié à `UNIT_HEALTH` sur un
  raid de 30 joueurs est un coût permanent — d'autant plus sensible sur un poste modeste.
- **Throttler les événements en rafale.** `GROUP_ROSTER_UPDATE`, `BAG_UPDATE`, `UNIT_AURA`
  arrivent par paquets. Pattern usuel : marquer un drapeau *sale* et traiter une seule fois au
  `C_Timer.After(0, ...)` suivant.
- **`/etrace` en jeu** liste les événements réellement émis, avec leur charge utile. C'est la
  façon la plus rapide de découvrir le bon événement — et la seule qui ne se trompe pas.
