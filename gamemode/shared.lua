GM.Name = "Zombie Master"
GM.Author = "Forrest Mark X"
GM.Email = "forrestmarkx@outlook.com"
GM.Website = "http://steamcommunity.com/id/ForrestMarkX/"
GM.TeamBased = true

GM.Credits = {
	{"Forrest Mark X", "http://steamcommunity.com/id/ForrestMarkX/", "Programmer"},
	{"William \"JetBoom\" Moodhe", "http://www.noxiousnet.com", "Code snippets from Zombie Survival"},
	{"Chewgum", "", "Vestige gamemode code"},
	{"Mka0207", "http://steamcommunity.com/id/mka0207/myworkshopfiles", "Building the base and icon work"},
	
	{"AzoNa, Gabil", "", "French translation"},
	{"FoxHound", "", "English (UK) translation"},
	{"plianes766", "", "Chinese (Traditional) translation"},
	{"Navi", "", "Korean translation"},
	{"Kit Ballard, RS689", "", "German translation"},
	{"Brendan Tan", "", "Chinese (Simplified) translation"},
	{"Marco", "", "Swedish translation"},
	{"Der eisenballs", "", "Hebrew translation"},
	{"Comic King", "", "Croatian & Serbian translation"}
}

include("sh_translate.lua")
include("sh_sounds.lua")
include("sh_zm_globals.lua")
include("sh_utility.lua")
include("sh_zerolag.lua")

include("sh_zm_options.lua")

include("sh_weapons.lua")
include("sh_players.lua")
include("sh_entites.lua")
include("sh_zombies.lua")

include("player_class/player_zm.lua")
include("player_class/player_survivor.lua")
include("player_class/player_zombiemaster.lua")
include("player_class/player_spectator.lua")

GM.NetworkVarCallbacks = {}
GM.iZombieList = {}

function GM:Initialize()
	hook.Call("SetupCustomItems", self)
	
	for _, mdl in pairs(file.Find("models/zombie/*.mdl", "GAME")) do
		util.PrecacheModel(mdl)
	end
	
	game.AddAmmoType({ name = "pistol", dmgtype = DMG_BULLET, tracer = TRACER_LINE_AND_WHIZ, plydmg = GetConVar("sk_plr_dmg_pistol"):GetInt(), npcdmg = GetConVar("sk_npc_dmg_pistol"):GetInt(), maxcarry = GetConVar("zm_maxammo_pistol"):GetInt(), force = 1225 })
	game.AddAmmoType({ name = "smg1", dmgtype = DMG_BULLET, tracer = TRACER_LINE_AND_WHIZ, plydmg = GetConVar("sk_plr_dmg_smg1"):GetInt(), npcdmg = GetConVar("sk_npc_dmg_smg1"):GetInt(), maxcarry = GetConVar("zm_maxammo_smg1"):GetInt(), force = 1225 })
	game.AddAmmoType({ name = "357", dmgtype = DMG_BULLET, tracer = TRACER_LINE_AND_WHIZ, plydmg = GetConVar("sk_plr_dmg_357"):GetInt(), npcdmg = GetConVar("sk_npc_dmg_357"):GetInt(), maxcarry = GetConVar("zm_maxammo_357"):GetInt(), force = 5000 })
	game.AddAmmoType({ name = "buckshot", dmgtype = bit.bor(DMG_BULLET, DMG_BUCKSHOT), tracer = TRACER_LINE_AND_WHIZ, plydmg = GetConVar("sk_plr_dmg_buckshot"):GetInt(), npcdmg = GetConVar("sk_npc_dmg_buckshot"):GetInt(), maxcarry = GetConVar("zm_maxammo_buckshot"):GetInt(), force = 1200 })
	game.AddAmmoType({ name = "revolver", dmgtype = DMG_BULLET, tracer = TRACER_LINE_AND_WHIZ, plydmg = 0, npcdmg = 0, maxcarry = GetConVar("zm_maxammo_revolver"):GetInt(), force = 5000 })
	game.AddAmmoType({ name = "molotov", dmgtype = DMG_BURN, tracer = TRACER_NONE, plydmg = 0, npcdmg = 0, maxcarry = GetConVar("zm_maxammo_molotov"):GetInt(), force = 0 })
	game.AddAmmoType({name = "unused"})
	
	hook.Call("BuildZombieDataTable", self)
	hook.Call("SetupNetworkingCallbacks", self)
	
	if SERVER then game.ConsoleCommand("mp_flashlight 1\n") end
end

function GM:SetupCustomItems()
end

function GM:SetupNetworkingCallbacks()
	self:AddNetworkingCallbacks("holding", function(ent, value) ent.bIsHolding = value end)
	self:AddNetworkingCallbacks("selected", function(ent, value) ent.bIsSelected = value end)
	self:AddNetworkingCallbacks("bClingingCeiling", function(ent, value) ent.m_bClinging = value end)
	self:AddNetworkingCallbacks("bIsEngineNPC", function(ent, value) ent.IsEngineNPC = value end)
end

function GM:CreateTeams()
	TEAM_SURVIVOR = 1
	team.SetUp(TEAM_SURVIVOR, "Survivors", Color(255, 64, 64, 255)) 
	team.SetSpawnPoint(TEAM_SURVIVOR, "info_player_deathmatch")
	
	TEAM_ZOMBIEMASTER = 2
	team.SetUp(TEAM_ZOMBIEMASTER, "Zombie Master", Color(153, 255, 153, 255))
	team.SetSpawnPoint(TEAM_ZOMBIEMASTER, "info_player_zombiemaster")
	
	team.SetUp(TEAM_SPECTATOR, "Spectators", Color(120, 120, 120, 255))
	team.SetSpawnPoint(TEAM_SPECTATOR, {"info_player_deathmatch", "info_player_zombiemaster", "worldspawn"})
end

function GM:FindZM()
	return team.GetPlayers(TEAM_ZOMBIEMASTER)[1]
end

function GM:PlayerShouldTakeDamage(pl, attacker)
	return player_manager.RunClass(pl, "ShouldTakeDamage", attacker)
end

function GM:IsSpecialPerson(pl, image)
	local img, tooltip
	local steamid = pl:SteamID()

	if steamid == "STEAM_0:0:18807892" then
		img = "icon16/page_white_cplusplus.png"
		tooltip = "ForrestMarkX\nDeveloper!"
	elseif pl:IsAdmin() then
		img = "icon16/shield.png"
		tooltip = "Admin"
	end
	
	local contributor = self.ContributorList[steamid]
	if contributor then
		img = "icon16/heart.png"
		tooltip = contributor.."\nContributor!"
	end

	if img then
		if CLIENT then
			image:SetImage(img)
			image:SetTooltip(tooltip)
		end

		return true
	end

	return false
end

function GM:GetZMSelection()
    return GetGlobalBool("zm_zmselection_start", false)
end

function GM:GetRoundStart()
    return GetGlobalBool("zm_round_start", false)
end

function GM:GetRoundActive()
    return GetGlobalBool("zm_round_active", false)
end

function GM:GetRoundEnd()
    return GetGlobalBool("zm_round_ended", false)
end

function GM:SetupMove(ply, mv, cmd)
	player_manager.RunClass(ply, "SetupMove", mv, cmd)
end

function GM:AddNetworkingCallbacks(name, func)
	if self.NetworkVarCallbacks[name] then return end
	self.NetworkVarCallbacks[name] = func
end

function GM:EntityNetworkedVarChanged(ent, name, oldval, newval)
	if self.NetworkVarCallbacks[name] ~= nil then self.NetworkVarCallbacks[name](ent, newval) end
	
	if CLIENT and ent.PostNetReceive then
		ent:PostNetReceive(name, oldval, newval)
	end
end

function GM:ShouldCollide(ent1, ent2)
	return not (ent1:IsPlayer() and ent2:IsPlayer())
end

function GM:EntityRemoved(ent)
	if ent:IsNPC() and self.iZombieList[ent] ~= nil then self.iZombieList[ent] = nil end
end

function GM:GravGunPickupAllowed(ply, ent)
	return player_manager.RunClass(ply, "AllowPickup", ent)
end