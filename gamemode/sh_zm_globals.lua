ZM_PHYSEXP_DAMAGE = 17500
ZM_PHYSEXP_RADIUS = 222
ZM_PHYSEXP_DELAY = 7.4

SF_PHYSEXPLOSION_NODAMAGE = 0x0001
SF_PHYSEXPLOSION_DISORIENT_PLAYER = 0x0010

GM.AmmoModels = {}
GM.AmmoModels["pistol"] = "models/Items/BoxSRounds.mdl"
GM.AmmoModels["smg1"] = "models/Items/BoxMRounds.mdl"
GM.AmmoModels["buckshot"] = "models/Items/BoxBuckshot.mdl"
GM.AmmoModels["357"] = "models/Items/357ammobox.mdl"
GM.AmmoModels["ar2"] = "models/Items/BoxMRounds.mdl"
GM.AmmoModels["revolver"] = "models/Items/revolverammo.mdl"
GM.AmmoModels["molotov"] = "models/weapons/molotov3rd_zm.mdl"

GM.AmmoCache = {}
GM.AmmoCache["pistol"] = 20
GM.AmmoCache["pistol_large"] = 100
GM.AmmoCache["smg1"] = 30
GM.AmmoCache["smg1_large"] = 180
GM.AmmoCache["ar2"] = 20
GM.AmmoCache["ar2_large"] = 100
GM.AmmoCache["357"] = 11
GM.AmmoCache["357_large"] = 20
GM.AmmoCache["buckshot"] = 8
GM.AmmoCache["revolver"] = 6
GM.AmmoCache["molotov"] = 1

CARRY_DRAG_MASS = 145
CARRY_DRAG_VOLUME = 120
CARRY_SPEEDLOSS_PERKG = 1.3
CARRY_SPEEDLOSS_MINSPEED = 88

GM.RandomPlayerModels = {}
for name, mdl in pairs(player_manager.AllValidModels()) do
	table.insert(GM.RandomPlayerModels, name)
end