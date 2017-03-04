GM.Name = "Zombie Master"
GM.Author = "Forrest Mark X"
GM.Email = "forrestmarkx@outlook.com"
GM.Website = "http://steamcommunity.com/id/ForrestMarkX/"
GM.TeamBased = true

GM.Credits = {
	{"Forrest Mark X", "http://steamcommunity.com/id/ForrestMarkX/", "Programmer"},
	{"William \"JetBoom\" Moodhe", "www.noxiousnet.com", "Code snippets from Zombie Survival"},
	{"Chewgum", "", "Vestige gamemode code"},
	{"Mka0207", "http://steamcommunity.com/id/mka0207/myworkshopfiles", "Building the base and icon work"},
	{"Kigen", "", "Providing the shared networking library"},
	{"xyzzy", "", "Some bits of code from iNPC to make the engine NPCs less stupid"},
	
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

include("sh_networking.lua")
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

function GM:Initialize()
	for name, mdl in pairs(player_manager.AllValidModels()) do
		util.PrecacheModel(mdl)
	end
	
	for _, mdl in pairs(file.Find("models/zombie/*.mdl", "GAME")) do
		util.PrecacheModel(mdl)
	end
	
	game.AddAmmoType({ name = "pistol", dmgtype = DMG_BULLET, tracer = TRACER_LINE_AND_WHIZ, plydmg = GetConVar("sk_plr_dmg_pistol"):GetInt(), npcdmg = GetConVar("sk_npc_dmg_pistol"):GetInt(), maxcarry = 80, force = 1225 })
	game.AddAmmoType({ name = "smg1", dmgtype = DMG_BULLET, tracer = TRACER_LINE_AND_WHIZ, plydmg = GetConVar("sk_plr_dmg_smg1"):GetInt(), npcdmg = GetConVar("sk_npc_dmg_smg1"):GetInt(), maxcarry = 60, force = 1225 })
	game.AddAmmoType({ name = "357", dmgtype = DMG_BULLET, tracer = TRACER_LINE_AND_WHIZ, plydmg = GetConVar("sk_plr_dmg_357"):GetInt(), npcdmg = GetConVar("sk_npc_dmg_357"):GetInt(), maxcarry = 20, force = 5000 })
	game.AddAmmoType({ name = "buckshot", dmgtype = bit.bor(DMG_BULLET, DMG_BUCKSHOT), tracer = TRACER_LINE_AND_WHIZ, plydmg = GetConVar("sk_plr_dmg_buckshot"):GetInt(), npcdmg = GetConVar("sk_npc_dmg_buckshot"):GetInt(), maxcarry = 24, force = 1200 })
	game.AddAmmoType({ name = "revolver", dmgtype = DMG_BULLET, tracer = TRACER_LINE_AND_WHIZ, plydmg = 0, npcdmg = 0, maxcarry = 24, force = 5000 })
	game.AddAmmoType({ name = "molotov", dmgtype = DMG_BURN, tracer = TRACER_NONE, plydmg = 0, npcdmg = 0, maxcarry = 3, force = 0 })
	game.AddAmmoType({name = "unused"})
	
	hook.Call("BuildZombieDataTable", self)
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

function GM:PlayerIsAdmin(pl)
	return pl:IsAdmin()
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
    return GetSharedBool("zm_zmselection_start", false)
end

function GM:GetRoundStart()
    return GetSharedBool("zm_round_start", false)
end

function GM:GetRoundActive()
    return GetSharedBool("zm_round_active", false)
end

function GM:GetRoundEnd()
    return GetSharedBool("zm_round_ended", false)
end

function GM:SetupMove(ply, mv, cmd)
	player_manager.RunClass(ply, "SetupMove", mv, cmd)
end