local CustomWeapons = {}
function GM:AddCustomWeapon(weaponclass, replacerclass, chance)
	if CustomWeapons[weaponclass] and CustomWeapons[weaponclass].Class == replacerclass then return end
	
	chance = chance or 1
	chance = math.Clamp(chance, 0, 1)
	
	CustomWeapons[weaponclass] = {Class = replacerclass, Chance = chance}
end

function GM:GetCustomWeapons()
	return CustomWeapons
end

local CustomAmmo = {}
function GM:AddCustomAmmo(ammotype, replacerclass, model, replacertype, chance, maxcount, pickupamount, damagetype, tracerstyle)
	if CustomAmmo[ammotype] and CustomAmmo[ammotype].Class == replacerclass then return end
	
	chance = chance or 1
	chance = math.Clamp(chance, 0, 1)
	maxcount = maxcount or 9999
	pickupamount = pickupamount or 10
	damagetype = damagetype or DMG_BULLET
	tracerstyle = tracerstyle or TRACER_LINE_AND_WHIZ
	
	CustomAmmo[ammotype] = {Class = replacerclass, Chance = chance, Type = replacertype, MaxCarry = maxcount, DmgType = damagetype, TracerType = tracerstyle}
	
	if not GAMEMODE.AmmoClass[replacerclass] then
		GAMEMODE.AmmoClass[replacerclass] = replacertype
	end
	
	if not GAMEMODE.AmmoCache[replacertype] then
		GAMEMODE.AmmoCache[replacertype] = pickupamount
	end
	
	if not GAMEMODE.AmmoModels[replacerclass] then
		GAMEMODE.AmmoModels[replacerclass] = model
	end
end

function GM:GetCustomAmmo()
	return CustomAmmo
end

CreateConVar("zm_physexp_cost", "400", FCVAR_REPLICATED, "How much spawning a explosion will cost.")
CreateConVar("zm_spotcreate_cost", "100", FCVAR_REPLICATED, "How much spawning a hidden zombie will cost.")
CreateConVar("zm_cost_shambler", "10", { FCVAR_NOTIFY, FCVAR_REPLICATED }, "The cost to spawn a Shambler")
CreateConVar("zm_cost_banshee", "70", { FCVAR_NOTIFY, FCVAR_REPLICATED }, "The cost to spawn a Banshee")
CreateConVar("zm_cost_hulk", "60", { FCVAR_NOTIFY, FCVAR_REPLICATED }, "The cost to spawn a Hulk")
CreateConVar("zm_cost_drifter", "25", { FCVAR_NOTIFY, FCVAR_REPLICATED }, "The cost to spawn a Drifter")
CreateConVar("zm_cost_immolator", "100", { FCVAR_NOTIFY, FCVAR_REPLICATED }, "The cost to spawn a Immolator")

CreateConVar("zm_popcost_banshee", "5", { FCVAR_NOTIFY, FCVAR_REPLICATED }, "How much a Banshee will add to the global zombie population.")
CreateConVar("zm_popcost_hulk", "4", { FCVAR_NOTIFY, FCVAR_REPLICATED }, "How much a Hulk will add to the global zombie population.")
CreateConVar("zm_popcost_shambler", "1", { FCVAR_NOTIFY, FCVAR_REPLICATED }, "How much a Shambler will add to the global zombie population.")
CreateConVar("zm_popcost_immolator", "5", { FCVAR_NOTIFY, FCVAR_REPLICATED }, "How much a Immolator will add to the global zombie population.")
CreateConVar("zm_popcost_drifter", "3", { FCVAR_NOTIFY, FCVAR_REPLICATED }, "How much a Drifter will add to the global zombie population.")
CreateConVar("zm_zombiemax", "50", { FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED }, "Sets maximum number of zombies the ZM is allowed to have active at once. Works like typical unit limit in RTS games.")
CreateConVar("zm_ambush_triggerrange", "96", FCVAR_REPLICATED, "The range ambush trigger points have.")
CreateConVar("zm_max_ragdolls", "15", FCVAR_REPLICATED, "Max ragdolls that can exist at one time.")
CreateConVar("zm_maxresource_increase", "35", FCVAR_REPLICATED, "Max increase in resources and income based on player count.")

CreateConVar("zm_maxammo_pistol", "80", FCVAR_REPLICATED, "Max pistol ammo that players can hold.")
CreateConVar("zm_maxammo_smg1", "60", FCVAR_REPLICATED, "Max smg1 ammo that players can hold.")
CreateConVar("zm_maxammo_357", "20", FCVAR_REPLICATED, "Max 357 ammo that players can hold.")
CreateConVar("zm_maxammo_buckshot", "24", FCVAR_REPLICATED, "Max buckshot ammo that players can hold.")
CreateConVar("zm_maxammo_revolver", "24", FCVAR_REPLICATED, "Max revolver ammo that players can hold.")
CreateConVar("zm_maxammo_molotov", "3", FCVAR_REPLICATED, "Max molotov ammo that players can hold.")

CreateConVar("zm_zombie_health", "55", { FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Sets the health used on the Shambler.")
CreateConVar("zm_fastzombie_health", "40", { FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Sets the health used on the Banshee.")
CreateConVar("zm_zombie_poison_health", "175", { FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Sets the health used on the Hulk.")
CreateConVar("zm_burnzombie_health", "110", { FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Sets the health used on the Immolator.")
CreateConVar("zm_dragzombie_health", "60", { FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Sets the health used on the Drifter.")

CreateConVar("zm_zombie_dmg_one_slash", "25", { FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Sets how much damage a Shambler does.")
CreateConVar("zm_zombie_poison_dmg_slash_min", "40", { FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Sets the min damage a Hulk will do.")
CreateConVar("zm_zombie_poison_dmg_slash_max", "50", { FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Sets the max damage a Hulk will do.")
CreateConVar("zm_fastzombie_clawdamage", "9", { FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Sets how much damage a Banshee does.")
CreateConVar("zm_fastzombie_leapdamage", "5", { FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Sets how much damage a Banshees leap does.")
CreateConVar("zm_dragzombie_damage", "3", { FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Sets how much damage a Drifter does.")