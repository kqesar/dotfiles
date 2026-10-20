# Recettes vérifiées

Réponses à des besoins courants, avec l'API réellement en vigueur sur 12.1.0. Chaque recette a
été soit relevée dans du code installé qui tourne, soit écrite puis vérifiée.

L'intérêt de ce fichier : ce sont exactement les questions où une reconstitution de mémoire
produit une réponse plausible et fausse.

## Savoir dans quel contenu se trouve le joueur

`GetInstanceInfo()` retourne `name, instanceType, difficultyID, difficultyName, maxPlayers,
dynamicDifficulty, isDynamic, instanceMapID, instanceGroupSize, LfgDungeonID`.

Valeurs d'`instanceType` observées dans le corpus : `"none"`, `"party"`, `"raid"`, `"scenario"`,
`"pvp"`, `"arena"`. [corpus]

Attention : `GetInstanceInfo()` **n'est pas fiable immédiatement** après un changement de zone.
Différer d'une seconde, ou rejouer la décision sur un événement plus tardif.

## Détecter une Delve

Les Delves se présentent comme des **scénarios** : `instanceType == "scenario"` ne suffit donc
pas à les distinguer.

La détection est notoirement capricieuse. Plumber — gros addon à jour — a essayé puis
**abandonné** deux approches, avec ses raisons en commentaire dans `Plumber/API.lua` :

- `C_DelvesUI.HasActiveDelve(mapID)` : *« ne change pas immédiatement après
  PLAYER_MAP_CHANGED »* ;
- `UnitPosition("player")` + mapID : *« échoue à la reconnexion dans une delve »*.

Le chemin retenu, en cascade :

```lua
function ns.IsInDelve()
    local _, instanceType = GetInstanceInfo()
    if instanceType ~= "scenario" then
        return false
    end

    if C_PartyInfo.IsDelveInProgress and C_PartyInfo.IsDelveInProgress() then
        return true
    end
    -- Repli retenu par Plumber : survit à la reconnexion.
    if C_PartyInfo.IsPartyWalkIn and C_PartyInfo.IsPartyWalkIn() then
        return true
    end

    return false
end
```

Et **prévoir une seconde chance** : `ACTIVE_DELVE_DATA_UPDATE` permet de rejouer la décision
quand les données arrivent enfin. [corpus]

Réserve : `IsPartyWalkIn` couvre le contenu « walk-in » en général, pas uniquement les Delves.
Le filtre `instanceType == "scenario"` en amont limite les faux positifs, sans les exclure —
à vérifier dans les autres contenus instanciés de 12.x avant de s'y fier aveuglément.

## Savoir combien de boss compte un raid, et combien sont tombés

Le **verrouillage** est la seule source qui connaisse le nombre total de rencontres.

```lua
local name, id, reset, difficultyID, locked, extended, instanceIDMostSig,
      isRaid, maxPlayers, difficultyName, maxBosses, defeatedBosses = GetSavedInstanceInfo(index)
```

Positions utiles : **11 = `maxBosses`**, **12 = `defeatedBosses`**. [corpus]
`GetNumSavedInstances()` donne la borne de la boucle.

Deux pièges :

1. **L'appariement.** `GetSavedInstanceInfo` expose un identifiant de journal, pas
   l'`instanceMapID` que rend `GetInstanceInfo`. Les comparer directement ne marche pas —
   apparier sur le **nom + la difficulté**.
2. **La fraîcheur.** Les données ne sont renseignées qu'après une requête au serveur. Le
   déroulé correct :

```lua
-- Sur un kill réussi
function handlers.ENCOUNTER_END(_, _, _, _, success)
    if success == 1 then
        RequestRaidInfo()
    end
end

-- La réponse arrive ici
function handlers.UPDATE_INSTANCE_INFO()
    local defeated, total = ns.GetLockoutProgress()
    if defeated and total and total > 0 and defeated >= total then
        -- raid nettoyé
    end
end
```

Lire la progression juste après `ENCOUNTER_END` renvoie l'état d'**avant** le kill.

Limite : sans verrouillage (Raid Finder, difficultés sans lockout), aucune ligne ne
correspondra — la fonction doit rendre `nil` et l'appelant ne rien conclure.

## Réagir à l'activation des restrictions

```lua
function handlers.ADDON_RESTRICTION_STATE_CHANGED()
    ns.restricted = C_Secrets.HasSecretRestrictions()
end
```

C'est le signal « les données viennent de devenir secrètes / de redevenir lisibles ».
Y basculer entre mode complet et mode dégradé coûte bien moins cher que de tester à chaque
rafraîchissement. Événement relevé 20 fois dans le corpus. [corpus]

## Vérifier une valeur d'unité qui peut être secrète

```lua
local maxHealth = UnitHealthMax(unit)
if issecretvalue(maxHealth) or type(maxHealth) ~= "number" then
    return false        -- on renonce plutôt que de lever une erreur
end
return maxHealth > threshold
```

**`type()` ne protège de rien** : il retourne le vrai type d'une valeur secrète. Une garde
`type(x) == "number"` laisse donc passer un secret, et la comparaison qui suit lève une erreur
Lua. Seul `issecretvalue()` détecte le cas. Détail complet dans `secret-values.md`.

## Basculer l'enregistrement du journal de combat

```lua
if not LoggingCombat() then
    LoggingCombat(true)
end
```

Toujours valide sur 12.x — RaiderIO s'en sert via `LibCombatLogging`. [corpus]

À ne pas confondre avec les restrictions de Midnight : le **fichier** `WoWCombatLog.txt` est
écrit par le client, pas par un addon, et n'est donc pas concerné par la fermeture du CLEU.
Un addon qui se contente d'actionner cet interrupteur reste parfaitement viable.

Ne pas mémoriser l'état dans une variable : `LoggingCombat()` fait autorité, et une copie ne
crée qu'une occasion de désynchronisation.
