ZM_PHYSEXP_DAMAGE = 17500
ZM_PHYSEXP_RADIUS = 222
ZM_PHYSEXP_DELAY = 7.4

SF_PHYSEXPLOSION_NODAMAGE = 0x0001
SF_PHYSEXPLOSION_DISORIENT_PLAYER = 0x0010

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
GM.AmmoModels["item_ammo_357"] = "models/items/357ammo.mdl"
GM.AmmoModels["item_ammo_pistol"] = "models/items/boxsrounds.mdl"
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

gamemode.Call = hook.Run