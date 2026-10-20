-- Banc d'essai hors-jeu de la logique métier.
--
--     lua5.1 tests/logic_spec.lua
--
-- Ce fichier n'est PAS listé dans le TOC : il ne se charge jamais en jeu.
--
-- Raison d'être : dès que l'addon prend des décisions croisant plusieurs
-- conditions, les vérifier en jeu suppose de reproduire chaque situation. Ici
-- on pilote les conditions depuis une table et on assène des assertions.
--
-- Ce que ça ne teste pas : l'UI, les événements, le comportement réel des
-- valeurs secrètes. Ce que ça teste : les décisions — la partie où les bugs
-- coûtent cher et sont les plus pénibles à reproduire.

--=============================================================================
-- Simulacres d'API WoW
--=============================================================================

-- Le monde simulé. Chaque scénario le modifie plutôt que de redéfinir les
-- fonctions : les simulacres restent triviaux et lisibles.
local world = {
	instanceType = "none",
	difficultyID = 0,
	inCombat = false,
}

_G.GetInstanceInfo = function()
	return "Aucune", world.instanceType, world.difficultyID
end
_G.UnitAffectingCombat = function()
	return world.inCombat
end
_G.C_AddOns = {
	GetAddOnMetadata = function()
		return "test"
	end,
}
_G.GetLocale = function()
	return "enUS"
end
_G.issecretvalue = function()
	return false
end
_G.DEFAULT_CHAT_FRAME = nil

-- Ajouter ici les simulacres dont le code chargé a besoin AU CHARGEMENT.
-- Ceux dont il a besoin à l'exécution peuvent attendre le premier scénario.

--=============================================================================
-- Chargement de l'addon, dans l'ordre du TOC
--=============================================================================

local ns = {}

local function LoadFile(path)
	local chunk = assert(loadfile(path))
	-- Reproduit les deux arguments implicites que le client passe à chaque
	-- fichier d'un addon : le nom du dossier et la table privée partagée.
	chunk("AddonTemplate", ns)
end

local here = arg[0]:match("^(.*)/[^/]*$") or "."
LoadFile(here .. "/../Locales.lua")
LoadFile(here .. "/../Core.lua")

-- Ne charger que les fichiers sans dépendance à l'UI : tout ce qui appelle
-- CreateFrame au chargement demanderait des simulacres disproportionnés.
-- Neutraliser les rappels d'UI que la logique déclenche.
-- ns.UpdateDisplay = function() end

--=============================================================================
-- Mini-harnais d'assertions
--=============================================================================

local passed, failed = 0, 0

local function check(label, actual, expected)
	if actual == expected then
		passed = passed + 1
		io.write(("  ok    %s\n"):format(label))
	else
		failed = failed + 1
		io.write(("  ECHEC %s\n          attendu %s, obtenu %s\n"):format(label, tostring(expected), tostring(actual)))
	end
end

local function scenario(name)
	io.write(("\n%s\n"):format(name))
end

-- Remet une base et un monde neufs. Sans ça, les scénarios se contaminent.
local function reset(overrides)
	_G.AddonTemplateDB = nil
	ns.InitDatabase()

	world.instanceType, world.difficultyID, world.inCombat = "none", 0, false
	for key, value in pairs(overrides or {}) do
		world[key] = value
	end
end

--=============================================================================
-- Scénarios
--=============================================================================

scenario("Valeurs par défaut de la base")
reset()
check("la base existe", type(AddonTemplateDB), "table")
check("valeur par défaut appliquée", AddonTemplateDB.enabled, true)

scenario("Complément d'une base ancienne")
-- Une base écrite par une version antérieure n'a pas les clés ajoutées depuis.
_G.AddonTemplateDB = { enabled = false }
ns.InitDatabase()
check("choix existant préservé", AddonTemplateDB.enabled, false)
check("clé ajoutée depuis est comblée", AddonTemplateDB.threshold, 0.35)

-- Ajouter ici un scénario par branche de décision — et surtout UN SCÉNARIO PAR
-- RÉGRESSION CORRIGÉE. C'est là que ce fichier paie : le bug ne peut plus
-- revenir sans être signalé.

--=============================================================================
-- Bilan
--=============================================================================

io.write(("\n%d vérifications, %d échec(s)\n"):format(passed + failed, failed))
os.exit(failed == 0 and 0 or 1)
