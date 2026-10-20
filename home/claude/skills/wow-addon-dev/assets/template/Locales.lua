local _, ns = ...

-- Table de traduction. Le métatable fait le repli tout seul : une clé absente
-- se retourne elle-même. Une chaîne non traduite s'affiche donc en anglais au
-- lieu de produire un `nil` qui casserait l'affichage.
--
-- Convention de l'écosystème : la clé EST la chaîne anglaise. Pas de clé
-- abstraite type "settings.autoOpen.label" — la relecture du code y perdrait
-- plus qu'elle n'y gagnerait.
local L = setmetatable({}, {
	__index = function(_, key)
		return key
	end,
})

ns.L = L

local locale = GetLocale()

if locale == "frFR" then
	L["Addon Template"] = "Modèle d'addon"
	L["Enabled"] = "Activé"
	L["Enable the addon. When unchecked, nothing is displayed and no event is processed."] =
		"Active l'addon. Décoché, rien n'est affiché et aucun événement n'est traité."
	L["Show welcome message"] = "Message de bienvenue"
	L["Print a line in the chat frame when the addon loads."] =
		"Affiche une ligne dans la fenêtre de discussion au chargement de l'addon."
	L["Threshold"] = "Seuil"
	L["Below this fraction, the display switches to its alert state."] =
		"En dessous de cette fraction, l'affichage passe en état d'alerte."
	L["loaded"] = "chargé"
	L["Commands:"] = "Commandes :"
	L["open the options panel"] = "ouvrir le panneau d'options"
	L["toggle the addon on or off"] = "activer ou désactiver l'addon"
	L["print the current status"] = "afficher l'état courant"
	L["enabled"] = "activé"
	L["disabled"] = "désactivé"
	L["Unknown command: %s"] = "Commande inconnue : %s"
end

-- Ajouter ici les autres locales le cas échéant :
--   elseif locale == "deDE" then ...
--
-- Les chaînes françaises sont environ 20 % plus longues que l'anglais : toute
-- frame dimensionnée sur le texte anglais tronquera. Prévoir la marge.
