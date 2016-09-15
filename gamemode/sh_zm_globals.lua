ZM_PHYSEXP_DAMAGE = 17500
ZM_PHYSEXP_RADIUS = 222
ZM_PHYSEXP_DELAY = 7.4

FL_SPAWN_SHAMBLER_ALLOWED = 1
FL_SPAWN_BANSHEE_ALLOWED = 2
FL_SPAWN_HULK_ALLOWED = 4
FL_SPAWN_DRIFTER_ALLOWED = 8
FL_SPAWN_IMMOLATOR_ALLOWED = 16

SF_PHYSEXPLOSION_NODAMAGE = 1
SF_PHYSEXPLOSION_PUSH_PLAYER = 2
SF_PHYSEXPLOSION_PUSH_RADIALLY = 4
SF_PHYSEXPLOSION_TESTLOS = 8
SF_PHYSEXPLOSION_DISORIENT_PLAYER = 16

SF_ZOMBIE_WANDER_ON_IDLE = 32

HUMAN_WIN_SCORE = 50
HUMAN_LOSS_SCORE = 50

GM.ContributorList = {}
GM.ContributorList["STEAM_0:1:3307510"]  = "JetBoom"
GM.ContributorList["STEAM_0:0:8232794"] = "Chewgum"
GM.ContributorList["STEAM_0:0:18000855"] = "Mka0207"
GM.ContributorList["STEAM_0:0:8169277"] = "AzoNa"
GM.ContributorList["STEAM_0:0:54424319"] = "FoxHound"
GM.ContributorList["STEAM_0:1:77685948"] = "plianes766"
GM.ContributorList["STEAM_0:0:78650013"] = "Gabil"
GM.ContributorList["STEAM_0:1:19573596"] = "Navi"
GM.ContributorList["STEAM_0:1:43090758"] = "Kit Ballard"
GM.ContributorList["STEAM_0:1:21671914"] = "xyzzy"
GM.ContributorList["STEAM_0:0:18209215"] = "RS689"
GM.ContributorList["STEAM_0:1:52431091"] = "Brendan Tan"
GM.ContributorList["STEAM_0:0:7621671"] = "Marco"

GM.AmmoClass = {}
GM.AmmoClass["item_ammo_357"] = "357"
GM.AmmoClass["item_ammo_357_large"] = "357_large"
GM.AmmoClass["item_ammo_pistol"] = "pistol"
GM.AmmoClass["item_ammo_pistol_large"] = "pistol_large"
GM.AmmoClass["item_ammo_ar2"] = "ar2"
GM.AmmoClass["item_ammo_ar2_large"] = "ar2_large"
GM.AmmoClass["item_ammo_smg1"] = "smg1"
GM.AmmoClass["item_ammo_smg1_large"] = "smg1_large"
GM.AmmoClass["item_box_buckshot"] = "buckshot"
GM.AmmoClass["item_ammo_revolver"] = "revolver"
GM.AmmoClass["weapon_zm_molotov"] = "molotov"

GM.AmmoCache = {}
GM.AmmoCache["pistol"] = 20
GM.AmmoCache["pistol_large"] = 100
GM.AmmoCache["smg1"] = 30
GM.AmmoCache["smg1_large"] = 180
GM.AmmoCache["ar2"] = 20
GM.AmmoCache["ar2_large"] = 100
GM.AmmoCache["357"] = 11
GM.AmmoCache["357_large"] = 20
GM.AmmoCache["buckshot"] = 20
GM.AmmoCache["revolver"] = 6
GM.AmmoCache["molotov"] = 1

GM.AmmoModels = {}
GM.AmmoModels["item_ammo_revolver"] = "models/Items/revolverammo.mdl"
GM.AmmoModels["item_ammo_smg1"] = "models/items/boxmrounds.mdl"
GM.AmmoModels["item_ammo_smg1_large"] = "models/items/boxmrounds.mdl"
GM.AmmoModels["item_ammo_357"] = "models/items/357ammo.mdl"
GM.AmmoModels["item_ammo_357_large"] = "models/items/357ammo.mdl"
GM.AmmoModels["item_ammo_pistol"] = "models/items/boxsrounds.mdl"
GM.AmmoModels["item_ammo_pistol_large"] = "models/items/boxsrounds.mdl"
GM.AmmoModels["item_box_buckshot"] = "models/items/boxbuckshot.mdl"

CARRY_MASS = 145
CARRY_VOLUME = 120

GM.HumanGibs = {
	Model("models/gibs/HGIBS.mdl"),
	Model("models/gibs/HGIBS_spine.mdl"),

	Model("models/gibs/HGIBS_rib.mdl"),
	Model("models/gibs/HGIBS_scapula.mdl"),
	Model("models/gibs/antlion_gib_medium_2.mdl"),
	Model("models/gibs/Antlion_gib_Large_1.mdl"),
	Model("models/gibs/Strider_Gib4.mdl")
}

GM.RestrictedPMs = {}
GM.RestrictedPMs["zombie"] = true
GM.RestrictedPMs["zombiefast"] = true
GM.RestrictedPMs["corpse"] = true
GM.RestrictedPMs["charple"] = true
GM.RestrictedPMs["skeleton"] = true
GM.RestrictedPMs["zombine"] = true

GM.RandomPlayerModels = {}

local playermodels = player_manager.AllValidModels()
for name, mdl in pairs(playermodels) do
	if not GM.RestrictedPMs[name] then
		table.insert(GM.RandomPlayerModels, name)
	end
end