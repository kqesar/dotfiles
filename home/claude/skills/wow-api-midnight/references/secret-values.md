# Valeurs secrètes (Secret Values) — patch 12.0.0+

Le mécanisme central de Midnight. Tout code d'addon qui affiche de l'information de combat
passe par là.

## Le modèle mental

Avant Midnight, la sécurité des addons reposait sur le **taint** : un code d'addon ne pouvait
pas *agir* à la place du joueur (lancer un sort, cliquer un bouton protégé), mais il pouvait
*tout lire* et tout calculer. C'est ce qui a rendu possibles les addons qui prennent les
décisions à la place du joueur.

Midnight ajoute une seconde barrière, orthogonale : le code tainté peut toujours *recevoir*
la donnée, mais plus la *regarder*.

> Une valeur secrète est une boîte noire contenant une valeur Lua ordinaire (nombre, chaîne,
> booléen). Le code tainté peut la stocker, la passer à une API, l'afficher — mais pas voir
> ce qu'il y a dedans.

Analogie pour qui vient du web : c'est un *opaque handle*. On peut le transporter et le
rendre à l'API qui l'a émis, on ne peut pas le désérialiser.

**Point crucial : hors taint, les valeurs secrètes sont des valeurs ordinaires.** Le code de
Blizzard ne subit aucune restriction. Les restrictions ne s'appliquent qu'au chemin
d'exécution tainté — c'est-à-dire à tout code d'addon.

## Ce que le code d'addon PEUT faire — [wiki]

- stocker une valeur secrète dans une variable locale, un upvalue, une **valeur** de table ;
- la passer en argument à une fonction Lua ;
- la passer à une fonction C explicitement marquée comme acceptant les secrets d'un appelant
  tainté (`SecretArguments = "AllowedWhenTainted"` dans la doc générée) ;
- **concaténer** des secrets de type chaîne ou nombre (`..`) ;
- l'injecter dans `string.format` / `strjoin` / `strconcat` ;
- faire un test booléen sur un secret **non booléen** (`nil` → faux, tout le reste → vrai) ;
- appeler `type(secret)` — le type réel est retourné ;
- appeler `issecretvalue(secret)`.

## Ce que le code d'addon NE PEUT PAS faire — [wiki]

Chaque ligne ci-dessous lève une erreur Lua depuis du code tainté :

- **arithmétique** sur un secret (`+ - * / %`, unaire `-`) ;
- **comparaison** (`== ~= < <= > >=`) — y compris avec une valeur non secrète ;
- **test booléen d'un secret booléen** (celui-là précisément, contrairement aux autres types) ;
- opérateur de **longueur** `#` ;
- utilisation comme **clé de table** ;
- **indexation** d'un secret (`secret.champ`, `secret[k]`) ou affectation indexée ;
- **appel** d'un secret comme fonction ;
- `tonumber()` sur une chaîne secrète ;
- indexation, itération, mesure ou affectation sur une **table interdite** (*forbidden table*).

Le piège numéro un : ces erreurs n'apparaissent **pas** hors combat, puisque la valeur n'y
est pas secrète. Un addon peut sembler parfait au test et exploser en donjon mythique+.

## Les fonctions d'introspection

| Fonction | Retour | Usage |
| :-- | :-- | :-- |
| `issecretvalue(v)` | booléen | La valeur est-elle secrète ? **La plus utilisée** — 45 occurrences dans le corpus local. [corpus] |
| `issecrettable(t)` | booléen | La table est-elle secrète ? [wiki] |
| `canaccessvalue(v)` | booléen | L'appelant peut-il opérer sur cette valeur ? Plus large que `issecretvalue` : tient compte du contexte d'exécution. [corpus] |
| `canaccesstable(t)` | booléen | Idem pour une table (l'accès ne lèvera pas d'erreur). [wiki] |
| `scrubsecretvalues(...)` | liste | Retourne la liste d'entrée avec chaque secret remplacé par `nil`. Idéal avant un log ou une sérialisation. [corpus] |
| `secretwrap(...)` | — | Fonction sœur listée par le wiki. [à vérifier] |

## Pattern 1 — la garde `issecretvalue`

Le pattern majoritaire du corpus : calculer si on peut, déléguer au client sinon.

```lua
-- Extrait de SenseiClassResourceBar/Bars/Abstract/PowerBar.lua (12.1) [corpus]
if type(resource) == "number" and (issecretvalue(max) or issecretvalue(current)) then
    -- Une des deux valeurs est opaque : on laisse le client faire la division.
    -- UnitPowerPercent évalue une courbe côté moteur et rend une chaîne formatable.
    percentStr = string.format(pFormat, UnitPowerPercent("player", resource, true, CurveConstants.ScaleTo100))
elseif not issecretvalue(max) and not issecretvalue(current) and max ~= 0 then
    -- Chemin non restreint : arithmétique normale autorisée.
    percentStr = string.format(pFormat, (current / max) * 100)
else
    percentStr = ""
end
```

Trois enseignements :

1. **On teste avant de diviser**, jamais après.
2. **Le chemin secret n'est pas le chemin dégradé** : il produit le même affichage, via une
   API qui fait le calcul dans le moteur.
3. **Le troisième cas existe.** Ne pas oublier la branche « ni l'un ni l'autre ».

## Pattern 2 — mémoriser la dernière valeur lisible

Quand aucune API ne fait le calcul, garder la dernière valeur non secrète connue.

```lua
-- Extrait de SenseiClassResourceBar/Bars/Abstract/Bar.lua (12.1) [corpus]
local regenRate = GetPowerRegenForPowerType(resource) or 0.2
if not issecretvalue(regenRate) then
    self._cachedRegenRate = regenRate     -- lisible : on la retient
else
    regenRate = self._cachedRegenRate or 0.2  -- opaque : on réutilise la dernière connue
end
```

Légitime pour une valeur qui bouge peu (taux de régénération, maximum de ressource).
À éviter pour une valeur volatile : afficher une donnée périmée est pire que ne rien afficher.

## Pattern 3 — le repli de compatibilité

Un addon qui doit tourner aussi sur Classic, où le système est **entièrement désactivé** :

```lua
-- Extrait de BigWigs_Core/Core.lua [corpus]
local issecretvalue = issecretvalue or function() return false end -- XXX 12.0 compat
```

À ne mettre que si l'addon cible réellement plusieurs éditions. Sur du retail pur, c'est du
bruit — `issecretvalue` existe toujours.

## Pattern 4 — assainir avant de sortir de l'addon

Un secret qui part dans un log, une chaîne sauvegardée ou un message inter-addons est au
mieux inutile, au pire une erreur :

```lua
-- Ne jamais logger un secret brut : le remplacer par nil.
local function Log(...)
    print("|cff33ff99MonAddon|r :", scrubsecretvalues(...))
end
```

BigWigs applique la même prudence sur son canal de communication :

```lua
-- Extrait de BigWigs_Core/Core.lua [corpus]
if issecretvalue and issecretvalue(guid) then return end -- XXX 12.0 compat
```

## Aspects secrets (Secret Aspects)

Passer un secret à une API d'objet **contamine cet objet** sur l'aspect concerné : les
lectures liées deviennent secrètes à leur tour.

```lua
fontString:SetText(UnitName("target"))  -- si le nom est secret...
local t = fontString:GetText()          -- ...alors t est secret aussi (aspect Text)
```

Aspects documentés — [wiki] :

| Aspect | Bit | APIs concernées |
| :-- | :-- | :-- |
| `Text` | `0x8` | `SetText` / `GetText` |
| `Shown` | `0x20` | `SetShown` / `IsShown` / `IsVisible` |
| `Scale` | `0x40` | échelle |
| `Alpha` | `0x80` | transparence et couleur |
| `FrameLevel` | `0x100` | ordre d'empilement |
| `BarValue` | `0x4000` | valeur d'une `StatusBar` |
| `Cooldown` | `0x8000` | données de temps de recharge |

Plus de vingt aspects existent. Le seul moyen documenté de nettoyer un objet est
`FrameScriptObject:SetToDefaults()`, qui le remet à son état par défaut — donc qui écrase
aussi la mise en forme. À prévoir dans la conception, pas à découvrir en debug.

**Conséquence de design** : ne pas mélanger, dans une même frame, l'affichage de données
secrètes et une logique qui a besoin de relire l'état de cette frame. Séparer la frame
d'affichage de l'état interne de l'addon — l'état vit dans une table Lua, pas dans les widgets.

## Ancres secrètes (Secret Anchors)

Un objet qui reçoit un secret sans aspect explicite est marqué globalement : **toutes** ses
données de position et de dimension deviennent secrètes. Pire, cet état **se propage aux
enfants** par la chaîne d'ancrage (jamais aux parents).

- `ScriptRegion:IsAnchoringSecret()` teste l'état. [wiki]
- Effacer les points d'ancrage peut réinitialiser l'état. [wiki]

**Conséquence de design** : ne pas fonder une logique de mise en page sur `GetWidth()` /
`GetHeight()` / `GetPoint()` d'une frame qui affiche du combat. Fixer les dimensions depuis
la configuration de l'addon. En 12.1, `Frame:ResizeToBoundsRect()` couvre le cas
« s'adapter au contenu » sans jamais lire les dimensions. [wiki]

## Savoir à l'avance si une donnée sera secrète

### `C_Secrets` — [corpus]

Fonctions confirmées dans du code installé qui tourne sur 12.1.0 :

| Fonction | Usage |
| :-- | :-- |
| `C_Secrets.HasSecretRestrictions()` | Y a-t-il une restriction active, quelle qu'elle soit ? |
| `C_Secrets.ShouldAurasBeSecret()` | Les auras sont-elles secrètes en ce moment ? |
| `C_Secrets.ShouldCooldownsBeSecret()` | Idem pour les temps de recharge. |
| `C_Secrets.ShouldUnitIdentityBeSecret(unit)` | Classe, race, sexe, rôle de l'unité. |
| `C_Secrets.ShouldUnitComparisonBeSecret(u1, u2)` | Peut-on comparer deux unités ? |
| `C_Secrets.ShouldUnitHealthMaxBeSecret(unit)` | Points de vie maximum. |
| `C_Secrets.ShouldUnitAuraIndexBeSecret(unit)` | Accès aux auras par index. |
| `C_Secrets.CanCompareUnitTokens(u1, u2)` | Les deux tokens sont-ils comparables ? |
| `C_Secrets.GetSpellAuraSecrecy(spellID)` | Degré de secret d'une aura pour un sort donné. |

Le wiki mentionne aussi `ShouldUnitAuraBeSecret`, `ShouldUnitPowerBeSecret`,
`ShouldUnitSpellCastBeSecret`, `ShouldUnitCooldownBeSecret`,
`ShouldUnitAuraInstanceBeSecret`, `ShouldSpellCooldownBeSecret` — non observées dans le
corpus local. [à vérifier]

### `C_RestrictedActions` — [corpus]

```lua
if C_RestrictedActions.IsAddOnRestrictionActive(Enum.AddOnRestrictionType.ChallengeMode) then
    -- Mode dégradé : on n'essaie même pas de calculer.
end
```

| Fonction | Usage |
| :-- | :-- |
| `C_RestrictedActions.IsAddOnRestrictionActive(type)` | Une restriction donnée est-elle active ? **L'argument est obligatoire.** |
| `C_RestrictedActions.GetAddOnRestrictionState(type)` | État détaillé. |
| `C_RestrictedActions.CheckAllowProtectedFunctions()` | Les fonctions protégées sont-elles autorisées ? |

`Enum.AddOnRestrictionType` — [wiki] :

| Valeur | Champ | Signification |
| :-- | :-- | :-- |
| 0 | `Combat` | Le joueur affecte activement un combat. |
| 1 | `Encounter` | Rencontre d'instance en cours. |
| 2 | `ChallengeMode` | Clé mythique en cours et non terminée. |
| 3 | `PvPMatch` | Match PvP en cours et non terminé. |
| 4 | `Map` | Carte qui applique des restrictions. |
| 5 | `Chat` | Communications inter-addons restreintes (ajouté en 12.0.5). |

Un événement est émis au changement d'état d'un `AddOnRestrictionType` — voir
`references/events.md`.

## Les API qui calculent à votre place

Le remède aux restrictions n'est pas de contourner, c'est de déléguer le calcul au moteur.
Ces API acceptent des secrets et rendent un résultat directement affichable.

| Besoin | API | Source |
| :-- | :-- | :-- |
| Pourcentage de ressource | `UnitPowerPercent(unit [, powerType [, unmodified [, curve]]])` — avec une courbe, retourne le résultat de son évaluation (nombre ou couleur RGBA) | [corpus] + [wiki] |
| Formater une durée secrète | `C_StringUtil.CreateSecondsFormatter(...)` | [corpus] |
| Formater un nombre secret | `C_StringUtil.CreateNumericRuleFormatter(...)`, `C_StringUtil.RoundToNearestString(...)` | [corpus] |
| Masquer un zéro | `C_StringUtil.TruncateWhenZero(...)` | [corpus] |
| Colorer selon une valeur | `C_CurveUtil.CreateColorCurve(...)`, `C_CurveUtil.EvaluateColorValueFromBoolean(...)` | [corpus] |
| Objet durée | `C_DurationUtil.CreateDuration(...)` | [corpus] |
| Alimenter un cooldown | `Cooldown:SetCooldownFromDurationObject(duration)` | [wiki] |
| Alpha depuis un booléen secret | `Region:SetAlphaFromBoolean(bool)` | [wiki] |
| Barre depuis une durée | `StatusBar:SetTimerDuration(duration [, direction])` — le paramètre de direction (12.0.1) permet de remplir depuis le temps restant | [wiki] |

Le principe : **la courbe et le formateur sont l'interface**. On décrit à l'avance
« telle plage de valeurs → telle couleur / tel texte », le moteur applique la règle sur la
valeur secrète, et l'addon reçoit un résultat affichable sans jamais voir l'entrée.

## Tester le mode restreint

Hors combat, tout marche. Il faut donc forcer l'état restreint pour tester :

- CVars de forçage : `secretAurasForced`, `secretCooldownsForced` et leurs équivalents. [wiki]
  Les lister en jeu avec `/console cvarlist secret`.
- À défaut : une clé mythique+ ou un match PvP, où les restrictions sont les plus larges.
- `/etrace` pour observer les événements réellement reçus en contexte restreint.

Une frappe sur un mannequin d'entraînement **ne suffit pas** : `Encounter`, `ChallengeMode`
et `PvPMatch` n'y sont pas actifs.

## Ce qui a été assoupli

Blizzard a relâché plusieurs contraintes après le retour de la communauté. Ne pas concevoir
sur la base des règles de la 12.0.0 initiale :

- 12.0.1 — `CreateUnitHealPredictionCalculator` et `UnitGetDetailedHealPrediction` rendent la
  prédiction de soins et les absorptions calculables ; `PARTY_KILL` réapparaît avec les GUID
  de l'attaquant et de la cible ; `strsplit` / `strjoin` / `strconcat` sont restaurés dans
  l'environnement restreint. [wiki]
- 12.0.1 — liste blanche de sorts pour les auras et cooldowns (vol, GCD, ressources de
  certaines spécialisations, résurrections de combat). [wiki]
- 12.1 — `UnitName` ne retourne plus de secret pendant un match PvP actif. [wiki]
- 12.1 — `AuraButton` expose l'état *pandemic*, les bordures `stealable` et `showAlways`. [wiki]

Corollaire : **revérifier avant de déclarer une chose impossible.** La surface bouge à chaque
patch mineur, toujours dans le sens de l'assouplissement.

## Prédicats de la documentation générée

Dans la doc générée par le client (`/api`), chaque fonction porte des annotations qui disent
son comportement vis-à-vis des secrets — [wiki] :

| Annotation | Signification |
| :-- | :-- |
| `SecretReturns = true` | Retourne toujours des secrets. |
| `SecretWhenInCombat`, `SecretWhenUnitIdentityRestricted`, `SecretWhenUnitPowerRestricted`, `SecretWhenCurveSecret` | Secret uniquement dans ce contexte. |
| `SecretArguments = "AllowedWhenTainted"` | Accepte un secret depuis du code d'addon. |
| `SecretArguments = "AllowedWhenUntainted"` | N'accepte un secret que hors taint — donc pas depuis un addon. |
| `SecretArguments = "NotAllowed"` | N'accepte jamais de secret. |
| `NeverSecret` (sur un champ de structure) | Ce champ reste toujours lisible. |

Lire ces annotations dans `/api` avant de bâtir une logique dessus est plus rapide que de le
découvrir par une erreur en raid.
