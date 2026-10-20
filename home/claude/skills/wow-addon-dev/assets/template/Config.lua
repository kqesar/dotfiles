local _, ns = ...

local L = ns.L

-- Layout vertical : Blizzard génère les contrôles, gère la persistance,
-- l'apparence native, et surtout rend les options trouvables par la recherche
-- du panneau de réglages. Le canvas manuel (RegisterCanvasLayoutCategory) ne se
-- justifie que pour une interface qui n'est pas une liste de contrôles —
-- aperçu graphique, éditeur de position.
-- Le second retour est le layout : utile seulement pour insérer des en-têtes de
-- section (layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(...))).
local category = Settings.RegisterVerticalLayoutCategory(L["Addon Template"])

ns.settingsCategory = category

-- Appelée depuis ADDON_LOADED, une fois la base initialisée : les réglages
-- adossés à ns.db ont besoin que la table existe.
function ns.InitSettings()
	do
		-- Réglage adossé à une clé de la base : Blizzard lit et écrit tout seul.
		-- ATTENTION à la signature — elle a changé en 11.0.2, `variableKey` et
		-- `variableTbl` ont été insérés AU MILIEU de la liste. Une signature
		-- mémorisée d'une version antérieure produit un décalage silencieux.
		local setting = Settings.RegisterAddOnSetting(
			category,
			"ADDONTEMPLATE_ENABLED", -- identifiant unique et global
			"enabled", -- clé dans la table
			ns.db, -- la table qui porte la valeur
			Settings.VarType.Boolean,
			L["Enabled"],
			Settings.Default.True
		)

		-- L'effet de bord ne peut pas vivre dans la table : on l'accroche au
		-- changement de valeur. La forme méthode évite de redonner
		-- l'identifiant global du réglage.
		setting:SetValueChangedCallback(function(_, value)
			ns.SetEnabled(value)
		end)

		Settings.CreateCheckbox(
			category,
			setting,
			L["Enable the addon. When unchecked, nothing is displayed and no event is processed."]
		)
	end

	do
		local setting = Settings.RegisterAddOnSetting(
			category,
			"ADDONTEMPLATE_SHOW_WELCOME",
			"showWelcome",
			ns.db,
			Settings.VarType.Boolean,
			L["Show welcome message"],
			Settings.Default.True
		)
		Settings.CreateCheckbox(category, setting, L["Print a line in the chat frame when the addon loads."])
	end

	do
		local setting = Settings.RegisterAddOnSetting(
			category,
			"ADDONTEMPLATE_THRESHOLD",
			"threshold",
			ns.db,
			Settings.VarType.Number,
			L["Threshold"],
			0.35
		)

		-- min, max, pas — puis le format d'affichage de la valeur.
		local options = Settings.CreateSliderOptions(0.05, 0.95, 0.05)
		options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, function(value)
			return FormatPercentage(value, true)
		end)

		Settings.CreateSlider(
			category,
			setting,
			options,
			L["Below this fraction, the display switches to its alert state."]
		)
	end

	-- Toujours en dernier : la catégorie doit être complète avant d'être publiée.
	Settings.RegisterAddOnCategory(category)
end

function ns.OpenSettings()
	Settings.OpenToCategory(category:GetID())
end
