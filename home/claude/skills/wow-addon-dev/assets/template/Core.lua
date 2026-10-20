local ADDON_NAME, ns = ...

-- Fonctions capturées en local : un accès registre au lieu d'une indexation de
-- _G. Ne le faire que pour ce qui est appelé souvent — ici, l'affichage.
local format = string.format

-- La version fait autorité dans le TOC, jamais dans le code : un numéro
-- dupliqué finit toujours par diverger de celui que voit le joueur.
ns.version = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")

-- Ce fichier ne contient que de la logique : aucune frame, aucun enregistrement
-- auprès du client. C'est ce qui le rend chargeable et testable hors du jeu
-- (voir tests/logic_spec.lua). Les points d'entrée — événements, commandes
-- slash, compartiment d'addons — vivent dans Events.lua.

--=============================================================================
-- Base de données
--=============================================================================

-- Schéma de configuration : source de vérité unique des valeurs par défaut.
-- `version` sert aux migrations, il n'est pas une option.
local DEFAULTS = {
	version = 1,
	enabled = true,
	showWelcome = true,
	threshold = 0.35,
}

-- Migrations de schéma, jouées dans l'ordre. MIGRATIONS[n] fait passer une base
-- de la version n à n+1. Sans ce mécanisme, renommer une clé perd la
-- configuration de l'utilisateur — et il n'existe ni outil, ni rollback : la
-- base est un fichier Lua réécrit à la déconnexion.
local MIGRATIONS = {
	-- [1] = function(db)
	-- 	db.newName, db.oldName = db.oldName, nil
	-- end,
}

-- Complète récursivement la base avec les valeurs par défaut manquantes.
-- Indispensable : une base écrite par une version antérieure de l'addon n'a pas
-- les clés ajoutées depuis, et leur lecture rendrait nil.
local function ApplyDefaults(db, defaults)
	for key, value in pairs(defaults) do
		if type(value) == "table" then
			if type(db[key]) ~= "table" then
				db[key] = {}
			end
			ApplyDefaults(db[key], value)
		elseif db[key] == nil then
			db[key] = value
		end
	end
end

local function Migrate(db)
	while MIGRATIONS[db.version] do
		MIGRATIONS[db.version](db)
		db.version = db.version + 1
	end
end

-- Appelée depuis ADDON_LOADED : avant cet événement, la globale de
-- SavedVariables vaut nil et toute écriture part dans le vide.
function ns.InitDatabase()
	AddonTemplateDB = AddonTemplateDB or {}
	ns.db = AddonTemplateDB
	ApplyDefaults(ns.db, DEFAULTS)
	Migrate(ns.db)
end

--=============================================================================
-- Sortie console
--=============================================================================

local PREFIX = format("|cff33ff99%s|r :", ADDON_NAME)

function ns.Print(...)
	print(PREFIX, ...)
end

--=============================================================================
-- Logique métier
--=============================================================================

-- Bascule l'activation et applique l'effet. Passer par cette fonction plutôt
-- que d'écrire ns.db.enabled directement : c'est ici que vit l'effet de bord.
function ns.SetEnabled(enabled)
	ns.db.enabled = enabled and true or false

	if ns.db.enabled then
		ns.Enable()
	else
		ns.Disable()
	end
end

function ns.Enable()
	-- Point d'accroche : créer/afficher les frames, s'abonner aux événements
	-- coûteux. Rien ici ne doit supposer que le monde est chargé — c'est le
	-- rôle de PLAYER_LOGIN.
end

function ns.Disable()
	-- Symétrique d'Enable : masquer, se désabonner, annuler les tickers.
	-- Un addon désactivé doit coûter zéro, pas « presque zéro ».
end
