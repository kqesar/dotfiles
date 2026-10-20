local ADDON_NAME, ns = ...

local L = ns.L

local frame = CreateFrame("Frame")

-- Table de gestionnaires plutôt qu'un grand if/elseif : la déclaration d'un
-- gestionnaire vaut abonnement (voir la boucle en bas de fichier), donc on ne
-- peut plus oublier un RegisterEvent.
local handlers = {}

--=============================================================================
-- Cycle de vie
--=============================================================================

-- Premier événement utile. Les SavedVariables valent nil avant lui : toute
-- initialisation faite à la lecture du fichier écrirait dans le vide.
-- En revanche le monde n'est PAS chargé — UnitLevel("player") peut rendre 0.
function handlers.ADDON_LOADED(name)
	if name ~= ADDON_NAME then
		return
	end

	-- ADDON_LOADED refire pour chaque addon à la demande : on se désabonne.
	frame:UnregisterEvent("ADDON_LOADED")

	ns.InitDatabase()
	ns.InitSettings()
end

-- Tous les addons sont chargés, l'API d'unité est fiable. C'est ici qu'on
-- construit l'UI et qu'on lit l'état du joueur.
function handlers.PLAYER_LOGIN()
	if ns.db.showWelcome then
		ns.Print(L["loaded"], ns.version)
	end

	ns.SetEnabled(ns.db.enabled)
end

-- PIÈGE : cet événement REFIRE à chaque entrée en instance, en champ de
-- bataille, à chaque téléportation. Tout setup unique doit se garder — d'où
-- les deux arguments.
function handlers.PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)
	if isInitialLogin or isReloadingUi then
		return
	end

	-- Changement de zone instanciée : rafraîchir ce qui en dépend.
end

-- Dernier moment pour écrire dans les SavedVariables. Aucune API réseau ne
-- répond ici : uniquement de la sérialisation locale.
function handlers.PLAYER_LOGOUT()
	-- ns.db est déjà la table sauvegardée : rien à faire dans le cas simple.
end

--=============================================================================
-- Combat
--=============================================================================

-- Nom contre-intuitif : « régénération désactivée » signifie ENTRÉE en combat.
function handlers.PLAYER_REGEN_DISABLED()
	-- Toute action interdite en combat doit être reportée — voir le drapeau
	-- ci-dessous et PLAYER_REGEN_ENABLED.
end

-- SORTIE de combat : le moment où les actions protégées redeviennent
-- possibles. C'est ici qu'on rattrape ce qui a été reporté.
function handlers.PLAYER_REGEN_ENABLED()
	if ns.pendingLayout then
		ns.pendingLayout = false
		-- ns.ApplyLayout()
	end
end

--=============================================================================
-- Restrictions Midnight
--=============================================================================

-- Un Enum.AddOnRestrictionType vient de changer d'état : les données de combat
-- viennent de devenir secrètes, ou de redevenir lisibles. Basculer ici entre
-- mode complet et mode dégradé coûte bien moins cher que de tester à chaque
-- rafraîchissement.
function handlers.ADDON_RESTRICTION_STATE_CHANGED()
	-- ns.restricted = C_Secrets.HasSecretRestrictions()
end

--=============================================================================
-- Câblage
--=============================================================================

frame:SetScript("OnEvent", function(_, event, ...)
	-- Pas de garde sur l'absence de gestionnaire : un événement enregistré sans
	-- gestionnaire est un bug, on veut l'erreur dans BugSack plutôt qu'un
	-- silence.
	handlers[event](...)
end)

for event in pairs(handlers) do
	frame:RegisterEvent(event)
end

-- Pour un événement porteur d'unité, préférer RegisterUnitEvent : le filtrage
-- est fait par le moteur au lieu d'un `if unit ~= "player" then return end`
-- appelé des milliers de fois par combat.
--
--   frame:RegisterUnitEvent("UNIT_HEALTH", "player", "target")

--=============================================================================
-- Commandes slash
--=============================================================================

-- SLASH_<CLE><n> et SlashCmdList.<CLE> sont imposés par le client : ce sont les
-- rares globales légitimes d'un addon. Toujours préfixer la clé par le nom de
-- l'addon, sous peine de collision avec un autre addon.
SLASH_ADDONTEMPLATE1 = "/addontemplate"
SLASH_ADDONTEMPLATE2 = "/atp"

local function PrintHelp()
	ns.Print(L["Commands:"])
	print("  /atp config  -", L["open the options panel"])
	print("  /atp toggle  -", L["toggle the addon on or off"])
	print("  /atp status  -", L["print the current status"])
end

SlashCmdList.ADDONTEMPLATE = function(input)
	local command = (input or ""):match("^(%S*)"):lower()

	if command == "" or command == "help" then
		PrintHelp()
	elseif command == "config" then
		ns.OpenSettings()
	elseif command == "toggle" then
		ns.SetEnabled(not ns.db.enabled)
		ns.Print(ns.db.enabled and L["enabled"] or L["disabled"])
	elseif command == "status" then
		ns.Print(ns.db.enabled and L["enabled"] or L["disabled"])
	else
		ns.Print(format(L["Unknown command: %s"], command))
		PrintHelp()
	end
end
