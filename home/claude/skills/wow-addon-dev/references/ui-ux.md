# Interface et expérience utilisateur

## Le vocabulaire

| Terme | Ce que c'est |
| :-- | :-- |
| **Frame** | Le conteneur de base. Reçoit les événements, les scripts, les enfants. |
| **Region** | Ce qui se dessine mais ne reçoit rien : `Texture`, `FontString`. |
| **Template** | Un modèle de frame prédéfini (par Blizzard ou par l'addon), instancié par `CreateFrame(type, name, parent, "TemplateName")`. L'équivalent d'une classe abstraite. |
| **Mixin** | Une table de méthodes appliquée à une frame par `Mixin(frame, MonMixin)`. Le mécanisme de composition de l'UI moderne. |
| **Ancre** | Une frame se positionne **relativement** à une autre (`SetPoint`), jamais en coordonnées absolues. |
| **Protégée** | Une frame que seul le code de Blizzard peut manipuler en combat. Y toucher depuis un addon lève une erreur de taint. |

## Les deux règles de survie

### `InCombatLockdown()`

Certaines actions sont interdites en combat : créer ou déplacer une frame protégée, modifier
une liaison de touche, changer un attribut sécurisé. Le pattern obligatoire :

```lua
local pending = false

local function ApplyLayout()
    if InCombatLockdown() then
        pending = true              -- on reporte
        return
    end
    -- ... travail réel
end

-- PLAYER_REGEN_ENABLED = sortie de combat : on rattrape le report
function handlers.PLAYER_REGEN_ENABLED()
    if pending then
        pending = false
        ApplyLayout()
    end
end
```

### Les ancres secrètes

Une frame qui affiche une donnée de combat peut voir **toutes** ses données de position et de
dimension devenir secrètes, et cet état se propage à ses enfants. Conséquence directe :

> Ne jamais fonder une mise en page sur `GetWidth()`, `GetHeight()` ou `GetPoint()` d'une frame
> qui affiche du combat.

Fixer les dimensions depuis la configuration de l'addon, ou utiliser `Frame:ResizeToBoundsRect()`
(12.1) qui adapte au contenu sans jamais lire les dimensions. Détail dans
`wow-api-midnight/references/secret-values.md`.

**Corollaire d'architecture** : l'état de l'addon vit dans une table Lua, jamais dans les
widgets. Les widgets sont une projection de l'état, pas sa source.

## Le panneau d'options — Settings API

Depuis 10.0, `InterfaceOptions_AddCategory` est mort. Deux formes coexistent :

| Forme | Quand |
| :-- | :-- |
| **Layout vertical** — `Settings.RegisterVerticalLayoutCategory` | **Le défaut.** Blizzard génère les contrôles, gère la persistance, l'apparence native et la **recherche dans les réglages**. |
| **Canvas** — `Settings.RegisterCanvasLayoutCategory` | Uniquement quand l'interface ne se réduit pas à une liste de contrôles (aperçu graphique, éditeur de position). |

Construire quinze cases à cocher à la main sur `InterfaceOptionsCheckButtonTemplate` est le
pattern hérité à ne plus reproduire : plus de code, apparence non native, options invisibles à
la recherche.

### Le pattern de référence — [corpus, BugSack/config.lua]

```lua
local ADDON_NAME, ns = ...
local L = ns.L

local category, layout = Settings.RegisterVerticalLayoutCategory(ADDON_NAME)

-- Réglage adossé à une clé de la base de données : Blizzard lit et écrit tout seul.
local setting = Settings.RegisterAddOnSetting(
    category,
    "MONADDON_AUTO_POPUP",   -- identifiant unique et global du réglage
    "autoPopup",             -- clé dans la table
    ns.db,                   -- la table qui porte la valeur
    Settings.VarType.Boolean,
    L["Ouverture automatique"],
    Settings.Default.False
)
Settings.CreateCheckbox(category, setting, L["Ouvre la fenêtre dès qu'un événement survient."])

Settings.RegisterAddOnCategory(category)   -- toujours en dernier
```

**Attention à la signature** : `Settings.RegisterAddOnSetting` a changé en 11.0.2 — les
paramètres `variableKey` et `variableTbl` ont été insérés **au milieu** de la liste. Une
signature mémorisée d'une version antérieure produit un décalage silencieux.

### Réglage calculé — `RegisterProxySetting`

Quand la valeur ne vit pas dans une table mais derrière un accesseur (une bibliothèque, un
CVar) — [corpus] :

```lua
local setting = Settings.RegisterProxySetting(
    category,
    "MONADDON_MINIMAP_ICON",
    Settings.VarType.Boolean,
    L["Icône de minicarte"],
    Settings.Default.True,
    function() return not ns.db.minimap.hide end,          -- getter
    function(value) ns.db.minimap.hide = not value end     -- setter
)
Settings.CreateCheckbox(category, setting, L["Affiche l'icône près de la minicarte."])
```

### Autres contrôles

`Settings.CreateSlider(category, setting, options, tooltip)`,
`Settings.CreateDropdown(category, setting, getOptionsFunction, tooltip)`.
Le générateur d'options d'une liste déroulante est une **fonction**, rappelée à chaque
ouverture — ce qui permet des listes dynamiques.

Options d'un curseur — [corpus] :

```lua
local options = Settings.CreateSliderOptions(minValue, maxValue, step)
options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
    return FormatPercentage(value, true)
end)
Settings.CreateSlider(category, setting, options, tooltip)
```

### Éléments qui ne sont pas des réglages

Le layout accepte des initialiseurs libres — [corpus] :

```lua
-- Titre de section
layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(L["Comportement"]))

-- Bouton d'action (label, texte du bouton, fonction, infobulle, indexer pour la recherche)
layout:AddInitializer(CreateSettingsButtonInitializer(label, buttonText, onClick, tooltip, true))
```

Autres initialiseurs relevés dans le corpus : `CreateSettingsExpandableSectionInitializer`,
`CreateSettingsCheckboxDropdownInitializer`, et `Settings.CreateElementInitializer(template, data)`
pour un contrôle entièrement personnalisé (demande un template XML).

**Il n'existe pas d'initialiseur de texte libre rafraîchissable.** Pour afficher un état qui
change, soit un bouton qui l'écrit dans le chat, soit une catégorie canvas séparée.

### Options dépendantes : le grisage demande DEUX appels

Le piège le plus coûteux de cette API.

```lua
local initializer = Settings.CreateCheckbox(category, setting, tooltip)

local function parentEnabled()
    return parentSetting:GetValue() and true or false
end

-- 1. La HIÉRARCHIE : indentation, regroupement visuel.
initializer:SetParentInitializer(parentInitializer, parentEnabled)

-- 2. L'ÉTAT INACTIF : c'est CELUI-CI qui grise réellement le contrôle.
initializer:AddModifyPredicate(parentEnabled)
```

`SetParentInitializer` seul donne une indentation correcte **et des cases qui restent
cliquables** alors que leur section est éteinte. Le nom induit en erreur : il décrit la
relation, il n'applique pas d'état.

Et ce n'est pas fini : **les prédicats ne sont évalués qu'au dessin de la liste.** Sans
redessin, le grisage n'apparaît qu'après avoir quitté puis rouvert le panneau. Le callback de
la case parente doit donc demander un rafraîchissement :

```lua
local function RefreshSettingsDisplay()
    if SettingsInbound and SettingsInbound.RepairDisplay then
        SettingsInbound.RepairDisplay()
    elseif SettingsPanel and SettingsPanel.RepairDisplay then
        SettingsPanel:RepairDisplay()
    end
end

parentSetting:SetValueChangedCallback(function()
    ApplyChange()
    RefreshSettingsDisplay()
end)
```

Les deux points d'entrée coexistent selon la version du client, d'où le repli. Ces méthodes
sont semi-internes : vérifier leur présence (`if initializer.AddModifyPredicate then`) évite
de casser le panneau entier si une version les déplace — c'est ce que fait LibEQOL. [corpus]

Variantes utiles : `initializer:AddShownPredicate(fn)` **masque** au lieu de griser. Griser est
le défaut recommandé — le joueur voit que l'option existe et comprend pourquoi elle est
inactive.

### Sous-catégories

```lua
local root, rootLayout = Settings.RegisterVerticalLayoutCategory(ADDON_NAME)
Settings.RegisterAddOnCategory(root)

local sub, subLayout = Settings.RegisterVerticalLayoutSubcategory(root, L["Raids"])
Settings.RegisterAddOnCategory(sub)
```

La barre latérale des réglages devient la table des matières, et chaque page tient à l'écran.
À partir d'une quinzaine d'options, c'est nettement plus lisible qu'une page unique.

**Contrepartie à connaître avant de découper** : une dépendance parent/enfant ne fonctionne
qu'à l'intérieur d'une même page. Un interrupteur principal placé dans la catégorie racine ne
grisera **pas** le contenu des sous-pages. C'est aussi le comportement des réglages de
Blizzard, donc acceptable — mais c'est un arbitrage, pas un détail : découper, c'est renoncer
au grisage transversal.

### Ouvrir le panneau

```lua
Settings.OpenToCategory(category:GetID())
-- ou C_SettingsUtil.OpenSettingsPanel(...)  [corpus, 12.0]
```

## Listes défilantes — ScrollBox / ScrollUtil

`UIPanelScrollFrameTemplate` et `FauxScrollFrame` sont hérités. Le système actuel recycle les
boutons : une liste de 5 000 entrées ne crée qu'une douzaine de frames.

Templates réellement utilisés dans le corpus : `WowScrollBoxList` (17), `MinimalScrollBar` (24),
`WowTrimScrollBar` (9), `WowScrollBox` (5).

```lua
-- Vue linéaire : hauteur d'élément fixe, la plus simple.
local view = CreateScrollBoxListLinearView()

-- Comment on remplit un bouton à partir d'une donnée. Appelé au recyclage,
-- donc doit TOUT réinitialiser : le bouton a peut-être servi à une autre entrée.
view:SetElementInitializer("MonAddonRowTemplate", function(button, elementData)
    button.Label:SetText(elementData.name)
    button:SetScript("OnClick", function() ns.Select(elementData.id) end)
end)

view:SetPadding(2, 2, 2, 2, 0)   -- haut, bas, gauche, droite, espacement

ScrollUtil.InitScrollBoxListWithScrollBar(frame.ScrollBox, frame.ScrollBar, view)

-- Les données passent par un DataProvider, pas par la vue.
local provider = CreateDataProvider(mesEntrees)
frame.ScrollBox:SetDataProvider(provider)
```

Le piège du recyclage : un initialiseur qui ne réinitialise qu'une partie des champs laisse
apparaître des restes de l'entrée précédente. **Tout réécrire à chaque appel**, y compris ce
qui « ne change jamais ».

## Mixins

```lua
MonAddonBarMixin = {}      -- doit être global pour être utilisable en XML

function MonAddonBarMixin:OnLoad()
    self.value = 0
end

function MonAddonBarMixin:SetValue(v)
    self.value = v
    self.Fill:SetWidth(self:GetWidth() * v)
end

-- En Lua :
local bar = Mixin(CreateFrame("Frame", nil, parent), MonAddonBarMixin)
bar:OnLoad()

-- ou d'un coup :
local bar = CreateAndInitFromMixin(MonAddonBarMixin, parent)
```

12.1 ajoute `<Mixins source="local">` en XML et les KeyValues `type="local"`, qui permettent
d'atteindre la table privée de l'addon sans passer par une globale. [wiki]

`CallbackRegistryMixin` transforme une frame en émetteur d'événements typés — le bon outil
quand un composant d'UI doit prévenir plusieurs abonnés sans les connaître.

## Textures, atlas et SVG

```lua
tex:SetTexture("Interface\\AddOns\\MonAddon\\Media\\fond")   -- fichier de l'addon
tex:SetAtlas("UI-Frame-Bar-Fill-Blue")                       -- atlas Blizzard
```

Préférer un **atlas** quand il existe : la taille et les coordonnées sont fournies, et l'aspect
reste cohérent avec le reste du client. `/framestack` révèle les atlas utilisés par une frame
survolée.

12.1 accepte les **SVG** sur les textures classiques (`file="Chemin/Vers/Texture.svg"`) et
introduit le type `VectorGraphics` : rendu à la résolution native, sans crénelage sur un écran
haute densité. [wiki]

## UX — ce sur quoi challenger systématiquement

### Encombrement

Un addon qui affiche en permanence une information utile 5 % du temps vole de l'espace 95 % du
temps. Par défaut : **masquer quand ce n'est pas pertinent**. Hors combat, hors instance, à
zéro ressource — l'élément disparaît.

### Réglages par défaut

L'immense majorité des utilisateurs ne configure jamais rien. Le défaut n'est pas une valeur
neutre : c'est **le** comportement de l'addon. Y consacrer une vraie réflexion, pas la première
valeur venue.

### Découvrabilité

- Le panneau d'options apparaît dans la liste native (`Settings.RegisterAddOnCategory`) et
  chaque contrôle a une infobulle utile — pas la paraphrase de son libellé.
- Une commande slash sans argument affiche l'aide.
- Un addon qui change quelque chose de visible doit être identifiable : un préfixe coloré
  dans le chat suffit.

### Localisation frFR

Le client est en français. Deux conséquences concrètes :

1. **Les chaînes françaises sont ~20 % plus longues que l'anglais.** Une frame dimensionnée sur
   le texte anglais tronque en français. Prévoir la marge, ou laisser la frame s'adapter.
2. **Toute chaîne affichée passe par la table de locales**, avec repli enUS. Une chaîne en dur
   dans le code est un bug de traduction en attente.

```lua
-- Locales.lua
local ADDON_NAME, ns = ...

-- Repli : les clés anglaises servent de valeur par défaut.
local L = setmetatable({}, { __index = function(t, k) return k end })
ns.L = L

if GetLocale() == "frFR" then
    L["Auto popup"] = "Ouverture automatique"
    L["Minimap icon"] = "Icône de minicarte"
end
```

Le métatable rend le repli automatique : une clé non traduite s'affiche telle quelle plutôt que
`nil`. C'est la convention de l'écosystème.

### Accessibilité

- Ne pas coder l'information **uniquement** par la couleur : une icône ou un texte double
  l'information (daltonisme).
- Respecter l'échelle d'UI du joueur : dimensionner en unités de frame, pas en pixels
  d'écran.
- Contraste suffisant sur les fonds sombres du jeu — un gris moyen sur fond gris est illisible
  en raid.
- Ne jamais recouvrir les frames de Blizzard (barres d'action, minicarte) par défaut. Si
  l'addon se place à l'écran, il doit être déplaçable et sa position sauvegardée.

## Compartiment d'addons

Le bouton groupé à côté de la minicarte. **Zéro dépendance** — c'est l'alternative native à
`LibDBIcon`, déclarée dans le TOC : [corpus]

```toc
## AddonCompartmentFunc: MonAddon_OnCompartmentClick
## AddonCompartmentFuncOnEnter: MonAddon_OnCompartmentEnter
## AddonCompartmentFuncOnLeave: MonAddon_OnCompartmentLeave
```

Le client cherche ces noms dans `_G` : ce sont, avec les commandes slash, les seules globales
légitimes d'un addon.

```lua
function MonAddon_OnCompartmentClick(_, button)
    if button == "RightButton" then
        ns.OpenOptions()
    else
        ns.Toggle()
    end
end

function MonAddon_OnCompartmentEnter(self, button)
    -- Selon la version, le premier argument est le nom de l'addon ou la frame.
    local owner = type(self) ~= "string" and self or button
    GameTooltip:SetOwner(owner or UIParent, "ANCHOR_LEFT")
    GameTooltip:SetText(ADDON_NAME)
    GameTooltip:AddLine(ns.StatusLine(), 1, 1, 1)
    GameTooltip:Show()
end

function MonAddon_OnCompartmentLeave()
    GameTooltip:Hide()
end
```

L'icône affichée vient de `## IconTexture:` et **ne peut pas changer dynamiquement**. Pour
refléter un état, passer par l'infobulle (`OnEnter` est rappelé à chaque survol) ou par une
frame à l'écran.

## Infobulles

```lua
GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
GameTooltip:SetText(L["Titre"])
GameTooltip:AddLine(L["Détail sur une seconde ligne."], 1, 1, 1, true)  -- true = retour à la ligne
GameTooltip:Show()
-- ... et OnLeave :
GameTooltip:Hide()
```

Toujours appairer `Show` et `Hide` sur `OnEnter`/`OnLeave`. Une infobulle orpheline reste à
l'écran jusqu'au `/reload` — un classique du débogage perdu.
