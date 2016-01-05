AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

AddCSLuaFile("cl_killicons.lua")
AddCSLuaFile("cl_utility.lua")
AddCSLuaFile("cl_scoreboard.lua")
AddCSLuaFile("cl_dermaskin.lua")

AddCSLuaFile("cl_hud.lua")
AddCSLuaFile("cl_zombie.lua")

AddCSLuaFile("sh_weapons.lua")
AddCSLuaFile("sh_players.lua")
AddCSLuaFile("sh_entites.lua")

AddCSLuaFile("sh_sounds.lua")
AddCSLuaFile("sh_zm_globals.lua")
AddCSLuaFile("sh_utility.lua")

AddCSLuaFile("cl_zm_options.lua")
AddCSLuaFile("sh_zm_options.lua")
AddCSLuaFile("cl_targetid.lua")

AddCSLuaFile("vgui/dpingmeter.lua")
AddCSLuaFile("vgui/dteamcounter.lua")
AddCSLuaFile("vgui/dteamheading.lua")
AddCSLuaFile("vgui/dzmhud.lua")

AddCSLuaFile("vgui/dexnotificationslist.lua")
AddCSLuaFile("vgui/dexroundedframe.lua")

include("sv_zm_options.lua")
include("sh_players.lua")
include("shared.lua")

GM.RoundsPlayed = 0
GM.UnReadyPlayers = {}
GM.ConnectingPlayers = {}
GM.ReadyTimer = 0

if file.Exists(GM.FolderName.."/gamemode/maps/"..game.GetMap()..".lua", "LUA") then
	include("maps/"..game.GetMap()..".lua")
end

function BroadcastLua(code)
	for _, pl in pairs(player.GetAll()) do
		pl:SendLua(code)
	end
end

player.GetByUniqueID = player.GetByUniqueID or function(uid)
	for _, pl in pairs(player.GetAll()) do
		if pl:UniqueID() == uid then return pl end
	end
end

function GM:InitPostEntity()
	gamemode.Call("InitPostEntityMap")
	RunConsoleCommand("mapcyclefile", "mapcycle_zombiemaster.txt")
	
	self:SetRoundStartTime(5)
	self:SetRoundStart(true)
	self:SetRoundActive(false)
end

function GM:InitPostEntityMap()
	gamemode.Call("SetupSpawnPoints")
end

function GM:SetupSpawnPoints()
	local z_spawn = ents.FindByClass( "info_player_zombiemaster" )
	local h_spawn = ents.FindByClass( "info_player_deathmatch" )
	
	team.SetSpawnPoint( TEAM_SURVIVOR, z_spawn )
	team.SetSpawnPoint( TEAM_ZOMBIEMASTER, h_spawn )
end

function GM:AddNetworkStrings()
	util.AddNetworkString("zm_gamemodecall")
	util.AddNetworkString("zm_trigger")
	util.AddNetworkString("zm_mapinfo")	
	util.AddNetworkString("zm_queue")
	util.AddNetworkString("zm_remove_queue")
	util.AddNetworkString("zm_sendcurrentgroups")
	util.AddNetworkString("zm_sendselectedgroup")
end

function GM:PlayerSpawnAsSpectator( pl )
	pl:StripWeapons()
	pl:ChangeTeam(TEAM_SPECTATOR)
	pl:Spectate(OBS_MODE_ROAMING)
	pl:SetNoTarget(true)
	pl:SetMoveType(MOVETYPE_NOCLIP)
	pl:SendLua("RunConsoleCommand('-left')")
	pl:SendLua("RunConsoleCommand('-right')")
end

function GM:PlayerDeathThink(pl)
	return false
end

function GM:CanPlayerSuicide(ply)
	if ply:Team() == TEAM_ZOMBIEMASTER then	
		gamemode.Call("TeamVictorious", true, "The Zombie Master has submitted.\n")
		return false
	end
end

function GM:PlayerInitialSpawn(pl)
	if self:GetRoundActive() and team.NumPlayers(TEAM_SURVIVOR) == 0 and not NotifiedRestart then
		PrintMessage(HUD_PRINTTALK, "The round is restarting...\n" )
		timer.Simple(2, function() gamemode.Call("PreRestartRound") end)
		timer.Simple(5, function() gamemode.Call("RestartRound") end)
		NotifiedRestart = true
	end
	
	pl.NextPainSound = 0
	pl.IsReady = false
	timer.Simple(0.1, function()
		gamemode.Call("PlayerSpawnAsSpectator", pl)
	end)
	
	if self.ReadyTimer == 0 and not zm_timer_started then
		zm_timer_started = true
		self.ReadyTimer = CurTime() + 10
	end
	
	table.RemoveByValue(self.ConnectingPlayers, pl:Name())
	table.insert(self.UnReadyPlayers, pl)
	
	net.Start("zm_mapinfo")
		net.WriteString(self.MapInfo)
	net.Send(pl)
end

function GM:PlayerConnect(name, ip)
	table.insert(self.ConnectingPlayers, name)
end

function GM:OnNPCKilled(npc, attacker, inflictor)
	local numragdolls = #ents.FindByClass("env_shooter")
	
	if numragdolls > GetConVar("zm_max_ragdolls"):GetInt() then
		for _, ragdoll in pairs(ents.FindByClass("env_shooter")) do
			if IsValid(ragdoll) then ragdoll:Remove() end
		end
	else
		for _, ragdoll in pairs(ents.FindByClass("env_shooter")) do
			timer.Simple(5, function() if IsValid(ragdoll) then ragdoll:Remove() end end)
		end
	end
end

local VoiceSetTranslate = {}
VoiceSetTranslate["models/player/alyx.mdl"] = "alyx"
VoiceSetTranslate["models/player/barney.mdl"] = "barney"
VoiceSetTranslate["models/player/breen.mdl"] = "male"
VoiceSetTranslate["models/player/combine_soldier.mdl"] = "combine"
VoiceSetTranslate["models/player/combine_soldier_prisonguard.mdl"] = "combine"
VoiceSetTranslate["models/player/combine_super_soldier.mdl"] = "combine"
VoiceSetTranslate["models/player/eli.mdl"] = "male"
VoiceSetTranslate["models/player/gman_high.mdl"] = "male"
VoiceSetTranslate["models/player/kleiner.mdl"] = "male"
VoiceSetTranslate["models/player/monk.mdl"] = "monk"
VoiceSetTranslate["models/player/mossman.mdl"] = "female"
VoiceSetTranslate["models/player/odessa.mdl"] = "male"
VoiceSetTranslate["models/player/police.mdl"] = "combine"
VoiceSetTranslate["models/player/brsp.mdl"] = "female"
VoiceSetTranslate["models/player/moe_glados_p.mdl"] = "female"
VoiceSetTranslate["models/grim.mdl"] = "combine"
VoiceSetTranslate["models/jason278-players/gabe_3.mdl"] = "monk"
function GM:PlayerSpawn(ply)
	if ply:Team() == TEAM_SURVIVOR then
		ply:StripWeapons()
		ply:SetColor(color_white)

		if ply:GetMaterial() ~= "" then
			ply:SetMaterial("")
		end
		
		ply:ShouldDropWeapon(false)
		
		ply:SetMaxHealth( 100, true )  
		ply:SetWalkSpeed( 170 )  
		ply:SetRunSpeed( 170 )
		
		local desiredname = ply:GetInfo("cl_playermodel")
		local modelname = player_manager.TranslatePlayerModel(#desiredname == 0 and self.RandomPlayerModels[math.random(#self.RandomPlayerModels)] or desiredname)
		local lowermodelname = string.lower(modelname)
		ply:SetModel(modelname)
			
		if VoiceSetTranslate[lowermodelname] then
			ply.VoiceSet = VoiceSetTranslate[lowermodelname]
		elseif string.find(lowermodelname, "female", 1, true) then
			ply.VoiceSet = "female"
		else
			ply.VoiceSet = "male"
		end
			
		ply:SetCrouchedWalkSpeed(0.65)
		ply:SetMaxHealth(100)
		
		local pcol = Vector(ply:GetInfo("cl_playercolor"))
		pcol.x = math.Clamp(pcol.x, 0, 2.5)
		pcol.y = math.Clamp(pcol.y, 0, 2.5)
		pcol.z = math.Clamp(pcol.z, 0, 2.5)
		ply:SetPlayerColor(pcol)

		local wcol = Vector(ply:GetInfo("cl_weaponcolor"))
		wcol.x = math.Clamp(wcol.x, 0, 2.5)
		wcol.y = math.Clamp(wcol.y, 0, 2.5)
		wcol.z = math.Clamp(wcol.z, 0, 2.5)
		ply:SetWeaponColor(wcol)
		
		ply:SetupHands()
		
		ply:SetMoveType(MOVETYPE_WALK)
	end
	
	ply:SetNoTarget(not ply:IsSurvivor())
end

function GM:IncreaseResources(pZM)
	local players = #team.GetPlayers(TEAM_SURVIVOR)
	local resources = self:GetZMPoints()
	local increase = GetConVar("zm_maxresource_increase"):GetInt()
	
	increase = increase * math.Clamp(players, 1, 5)
	
	pZM:SetZMPoints(resources + increase)
	pZM:SetZMPointIncome(increase)
end

function GM:PlayerSetHandsModel( ply, ent )
	local info = self:GetHandsModel(ply)
	if info then
		ent:SetModel( info.model )
		ent:SetSkin( info.skin )
		ent:SetBodyGroups( info.body )
	end
end

function GM:PlayerShouldTakeDamage(pl, attacker)
	if attacker.PBAttacker and attacker.PBAttacker:IsValid() and CurTime() < attacker.NPBAttacker then -- Protection against prop_physbox team killing. physboxes don't respond to SetPhysicsAttacker()
		attacker = attacker.PBAttacker
	end

	if attacker:IsPlayer() and attacker ~= pl and not attacker.AllowTeamDamage and not pl.AllowTeamDamage and attacker:Team() == pl:Team() then return false end

	return true
end

function GM:PlayerNoClip(ply, desiredState)
	return ply:IsSuperAdmin()
end

local LastHumanDied = false	
function GM:DoPlayerDeath(ply, attacker, dmginfo)
	local plteam = ply:Team()
	local suicide = attacker == ply or attacker:IsWorld()
	
	ply:Freeze(false)
	
	if IsValid(attacker) and attacker:IsPlayer() then
		if attacker == ply then
			attacker:AddFrags(-1)
		else
			attacker:AddFrags(1)
		end
	end
	
	if ply:Health() <= -70 and not dmginfo:IsDamageType(DMG_DISSOLVE) then
		ply:Gib(dmginfo)
	else
		ply:CreateRagdoll()
	end
	
	local pZM = self:FindZM()
	if IsValid(pZM) and ply:IsSurvivor() then
		local income = math.random(GetConVar("zm_resourcegainperplayerdeathmin"):GetInt(), GetConVar("zm_resourcegainperplayerdeathmax"):GetInt())
		
		pZM:AddZMPoints(income)
		pZM:SetZMPointIncome(income)
	end
	
	local hands = ply:GetHands()
	if IsValid(hands) then
		hands:Remove()
	end
	
	ply:PlayDeathSound()
	timer.Simple(5, function() ply:ChangeTeam(TEAM_SPECTATOR) end)
	
	if team.NumPlayers(TEAM_SURVIVOR) == 1 then
		LastHumanDied = true
	end
	
	if not self:GetRoundEnd() then
		if LastHumanDied then
			gamemode.Call("TeamVictorious", false, "Undeath has prevailed!\n")
		end
	end
end

function GM:PostPlayerDeath( ply )
	ply:Spectate(OBS_MODE_ROAMING)
end

function GM:ReplaceMapWeapons()
	for _, ent in pairs(ents.FindByClass("weapon_*")) do
		if string.sub(ent:GetClass(), 1, 10) == "weapon_zm_" then
			local wep = ents.Create("prop_weapon")
			if wep:IsValid() then
				wep:SetPos(ent:GetPos())
				wep:SetAngles(ent:GetAngles())
				wep:SetWeaponType(ent:GetClass())
				wep:SetShouldRemoveAmmo(false)
				wep:Spawn()
				wep.IsPreplaced = true
			end
		end

		ent:Remove()
	end
end

function GM:PlayerHurt(victim, attacker, healthremaining, damage)
	if 0 < healthremaining then
		if victim:Team() == TEAM_SURVIVOR then
			victim:PlayPainSound()
		end
	end
end

local ammoreplacements = {
	["item_ammo_357"] = "357",
	["item_ammo_357_large"] = "357_large",
	["item_ammo_pistol"] = "pistol",
	["item_ammo_pistol_large"] = "pistol_large",
	["item_ammo_buckshot"] = "buckshot",
	["item_ammo_ar2"] = "ar2",
	["item_ammo_ar2_large"] = "ar2_large",
	["item_ammo_smg1"] = "smg1",
	["item_ammo_smg1_large"] = "smg1_large",
	["item_box_buckshot"] = "buckshot",
	["item_ammo_revolver"] = "revolver"
}
function GM:ReplaceMapAmmo()
	for classname, ammotype in pairs(ammoreplacements) do
		for _, ent in pairs(ents.FindByClass(classname)) do
			local newent = ents.Create("prop_ammo")
			if newent:IsValid() then
				newent:SetAmmoType(ammotype)
				newent.PlacedInMap = true
				newent:SetPos(ent:GetPos())
				newent:SetAngles(ent:GetAngles())
				newent:Spawn()
				newent:SetAmmo(self.AmmoCache[ammotype] or 1)
			end
			ent:Remove()
		end
	end
end

function GM:RestartRound()
	self:RestartLua()
	self:RestartGame()

	net.Start("zm_gamemodecall")
		net.WriteString("RestartRound")
	net.Broadcast()
end

function GM:RestartLua()
	zm_selection_started = false
	zm_zm_left = false
	NotifiedRestart = false
	zm_timer_started = false
	LastHumanDied = false
	self.ReadyTimer = 0
	income_time = 0
	
	self.groups = {}
	self.currentmaxgroup = 0
	self.selectedgroup = 0
	
	self:SetRoundStart(false)
	self:SetRoundActive(false)
	self:SetRoundEnd(false)
	self:SetRoundStartTime(1)
	
	self:SetCurZombiePop(0)
end

function GM:DoRestartGame()
	game.CleanUpMap(false)
	self:SetRoundStart(true)
	self.UnReadyPlayers = {}
	self.ConnectingPlayers = {}
end

function GM:RestartGame()
	for _, pl in pairs(player.GetAll()) do
		if IsValid(pl) then
			pl:StripAmmo()
			pl:SetFrags(0)
			pl:SetDeaths(0)
			pl:SetZMPoints(0)
			
			gamemode.Call("PlayerSpawnAsSpectator", pl)
		end
	end

	timer.Simple(0.25, function() self:DoRestartGame() end)
end

function GM:OnPlayerChangedTeam( ply, oldTeam, newTeam )
	if newTeam == TEAM_SPECTATOR then
		local Pos = ply:EyePos()
		ply:Spawn()
		ply:SetPos( Pos )
	elseif newTeam == TEAM_ZOMBIEMASTER then
		timer.Simple(0.1, function() ply:SendLua("GAMEMODE:CreateVGUI()") end)
	end
end

function GM:PreRestartRound()
	for _, pl in pairs(player.GetAll()) do
		pl:StripWeapons()
		pl:Spectate(OBS_MODE_ROAMING)
	end
end

function GM:FinishingRound(won, rounds)
	if self.RoundsPlayed > rounds then
		PrintMessage(HUD_PRINTTALK, "Changing map...\n" )
	else
		PrintMessage(HUD_PRINTTALK, "The round is restarting...\n" )
	end
end

function GM:CreateGibs(pos, headoffset)
	headoffset = headoffset or 0

	local headpos = Vector(pos.x, pos.y, pos.z + headoffset)
	for i = 1, 2 do
		local ent = ents.Create("prop_playergib")
		if ent:IsValid() then
			ent:SetPos(headpos + VectorRand() * 5)
			ent:SetAngles(VectorRand():Angle())
			ent:SetGibType(i)
			ent:Spawn()
		end
	end

	for i=1, 4 do
		local ent = ents.Create("prop_playergib")
		if ent:IsValid() then
			ent:SetPos(pos + VectorRand() * 12)
			ent:SetAngles(VectorRand():Angle())
			ent:SetGibType(math.random(3, #GAMEMODE.HumanGibs))
			ent:Spawn()
		end
	end
end

function GM:TeamVictorious(won, message)
	self:SetRoundEnd(true)
	gamemode.Call("IncrementRoundCount")
	
	if won then
		game.SetTimeScale(0.25)
		
		util.RemoveAll("prop_ammo")
		util.RemoveAll("prop_weapon")
	
		timer.Simple(2, function() game.SetTimeScale(1) end)
	end
	
	local rounds = GetConVar("zm_roundlimit"):GetInt()
	if self.RoundsPlayed > rounds then
		timer.Simple(5, function() gamemode.Call("LoadNextMap") end)
	else
		timer.Simple(2, function() gamemode.Call("PreRestartRound") end)
		timer.Simple(5, function() gamemode.Call("RestartRound") end)
	end
	
	PrintMessage(HUD_PRINTTALK, message)
	
	gamemode.Call("FinishingRound", won, rounds)
end

function GM:IncrementRoundCount()
	self.RoundsPlayed = self.RoundsPlayed + 1
end

function GM:InitialSpawnRound(ply)
	ply:ChangeTeam(TEAM_SURVIVOR)
	ply:UnSpectateAndSpawn()
	ply:SprintDisable()
	if ply:KeyDown(IN_WALK) then
		ply:ConCommand("-walk")
	end
					
	ply:SetCanWalk(false)
	ply:SetCanZoom(false)
	ply:AllowFlashlight(true)
	
	if GetConVar("zm_nocollideplayers"):GetBool() then
		ply:SetNoCollideWithTeammates(true)
		ply:SetCustomCollisionCheck(true)
	end
	
	ply:Give("weapon_zm_fists")
end

function GM:PlayerReady(pl)
	gamemode.Call("PlayerReadyRound", pl)
end

function GM:PlayerReadyRound(pl)
	if not pl:IsValid() then return end
	table.RemoveByValue(self.UnReadyPlayers, pl)
	
	pl:SendLua("GAMEMODE:MakePreferredMenu()")
	pl:ConCommand("-right")
	pl:ConCommand("-left")
	
	if self:GetRoundActive() and CurTime() < 10 then
		gamemode.Call("InitialSpawnRound", pl)
	end
end

concommand.Add("initpostentity", function(sender, command, arguments)
	if not sender.DidInitPostEntity then
		sender.DidInitPostEntity = true

		gamemode.Call("PlayerReady", sender)
	end
end)

function GM:EntityTakeDamage(ent, dmginfo)
	local attacker, inflictor = dmginfo:GetAttacker(), dmginfo:GetInflictor()
	
    -- We need to stop explosive chains team killing.
    if inflictor:IsValid() then
        local dmgtype = dmginfo:GetDamageType()
        if dmgtype == DMG_BLAST or dmgtype == DMG_BURN or dmgtype == DMG_SLOWBURN then
            if ent:IsPlayer() then
                if inflictor.LastExplosionTeam == ent:Team() and inflictor.LastExplosionAttacker ~= ent and inflictor.LastExplosionTime and CurTime() < inflictor.LastExplosionTime + 10 then -- Player damaged by physics object explosion / fire.
                    dmginfo:SetDamage(0)
                    dmginfo:ScaleDamage(0)
                    return
                end
            elseif inflictor ~= ent and string.sub(ent:GetClass(), 1, 12) == "prop_physics" and string.sub(inflictor:GetClass(), 1, 12) == "prop_physics" then -- Physics object damaged by physics object explosion / fire.
                ent.LastExplosionAttacker = inflictor.LastExplosionAttacker
                ent.LastExplosionTeam = inflictor.LastExplosionTeam
                ent.LastExplosionTime = CurTime()
            end
        elseif inflictor:IsPlayer() and string.sub(ent:GetClass(), 1, 12) == "prop_physics" then -- Physics object damaged by player.
            if inflictor:Team() == TEAM_HUMAN then
                local phys = ent:GetPhysicsObject()
                if phys:IsValid() and phys:HasGameFlag(FVPHYSICS_PLAYER_HELD) and inflictor:GetCarry() ~= ent or ent._LastDropped and CurTime() < ent._LastDropped + 3 and ent._LastDroppedBy ~= inflictor then -- Human player damaged a physics object while it was being carried or recently carried. They weren't the carrier.
                    dmginfo:SetDamage(0)
                    dmginfo:ScaleDamage(0)
                    return
                end
            end

            ent.LastExplosionAttacker = inflictor
            ent.LastExplosionTeam = inflictor:Team()
            ent.LastExplosionTime = CurTime()
        end
    end
end

function GM:SetRoundStartTime(time)
	self.RoundStartTime = time
end

function GM:GetRoundStartTime()
	return self.RoundStartTime or 2
end

local income_time = 0
function GM:PlayerPostThink(ply)
	if income_time ~= 0 and income_time <= CurTime() then
		if ply:IsZM() then
			ply:AddZMPoints(ply:GetZMPointIncome())
			income_time = CurTime() + GetConVar("zm_incometime"):GetInt()
		end
	end
end

local NextTick = 0
function GM:Think()
	local time = CurTime()
	local numplayers = #player.GetAll()
	
	if #self.ConnectingPlayers > 0 and CurTime() >= self.ReadyTimer then
		table.Empty(self.ConnectingPlayers)
	end
	
	if numplayers > 0 then
		if #self.UnReadyPlayers == 0 and #self.ConnectingPlayers == 0 and self:GetRoundStart() and not zm_selection_started then
			PrintMessage(HUD_PRINTCENTER, "All players are ready, choosing a Zombie Master!")
			zm_selection_started = true
			timer.Simple(self:GetRoundStartTime(), function()
				gamemode.Call("ZombieMasterVolunteers")
				for _, ent in pairs(ents.FindByClass("info_loadout")) do
					ent:Distribute()
				end
			end)
		end
	end
	
	if NextTick <= time then
		NextTick = time + 1
		
		local humans = team.GetPlayers(TEAM_SURVIVOR)
		for _, pl in pairs(humans) do
			if pl:Alive() then
				if pl:WaterLevel() >= 3 and not (pl.status_drown and pl.status_drown:IsValid()) then
					pl:GiveStatus("drown")
				end
			end
		end
	end
end

function GM:ShowHelp(pl)
	pl:SendLua("GAMEMODE:ShowHelp()")
end

function GM:PlayerDisconnected(ply)
	if self:GetRoundActive() then
		if ply:Team() == TEAM_ZOMBIEMASTER then
			gamemode.Call("TeamVictorious", true, "The Zombie Master has left!\n")
		elseif team.NumPlayers(TEAM_SURVIVOR) <= 0 then
			gamemode.Call("TeamVictorious", false, "All the humans have left!\n")
		end
	end
end

function GM:ZombieMasterVolunteers()
	if not GetConVar("zm_debug_nozombiemaster"):GetBool() then
		if team.NumPlayers(TEAM_ZOMBIEMASTER) == 1 then return end
		
		local PreferZM = {}
		local ZMList = {}
		for _, pl in pairs(player.GetAll()) do
			if pl:GetInfoNum("zm_preference", 0) == 1 then
				table.insert(PreferZM, pl)
			else
				table.insert(ZMList, pl)
			end
		end
		
		local pl = PreferZM[math.random(#PreferZM)] or ZMList[math.random(#ZMList)]
		
		if IsValid(pl) then
			pl:KillSilent()
			pl:SetFrags(0)
			pl:SetDeaths(0)
			pl:ChangeTeam(TEAM_ZOMBIEMASTER)
			pl:Spectate(OBS_MODE_ROAMING)
			pl:SetMoveType(MOVETYPE_NOCLIP)
			
			PrintMessage(HUD_PRINTTALK, pl:Name().." has become the Zombie Master")
			
			pl:SetZMPoints(425)
			pl:SetZMPointIncome(GetConVar("zm_maxresource_increase"):GetInt())
			gamemode.Call("IncreaseResources", ply)
			
			income_time = CurTime() + GetConVar("zm_incometime"):GetInt()
			
			local spawnpoints = ents.FindByClass("info_player_zombiemaster")
			local randspawn = spawnpoints[math.random(#spawnpoints)]
			if IsValid(randspawn) then
				local spawnpos, spawnang = randspawn:GetPos(), randspawn:GetAngles()
				pl:SetPos(spawnpos)
				pl:SetAngles(spawnang)
			end
		end
	end
	
	self:SetRoundStart(false)
	self:SetRoundActive(true)

	for _, ent in pairs(ents.FindByClass("prop_weapon")) do
		ent:Remove()
	end

	for _, ent in pairs(ents.FindByClass("prop_ammo")) do
		ent:Remove()
	end
	
	game.CleanUpMap(false)
	gamemode.Call("ReplaceMapWeapons")
	gamemode.Call("ReplaceMapAmmo")
	
	for _, ent in pairs(ents.FindByClass("prop_ammo")) do ent.PlacedInMap = true end
	for _, ent in pairs(ents.FindByClass("prop_weapon")) do ent.PlacedInMap = true end
	for _, ent in pairs(ents.FindByClass("prop_flashlightbattery")) do ent.PlacedInMap = true end
	
	for _, ply in pairs(team.GetPlayers(TEAM_SPECTATOR)) do
		gamemode.Call("InitialSpawnRound", ply)
	end
end

local function RealMap(map)
	return string.match(map, "(.+)%.bsp")
end
function GM:LoadNextMap()
	-- Just in case.
	timer.Simple(10, game.LoadNextMap)
	timer.Simple(15, function() RunConsoleCommand("changelevel", game.GetMap()) end)

	if file.Exists(GetConVar("mapcyclefile"):GetString(), "GAME") then
		game.LoadNextMap()
	else
		local maps = file.Find("maps/zm_*.bsp", "GAME")
		table.sort(maps)
		if #maps > 0 then
			local currentmap = game.GetMap()
			for i, map in ipairs(maps) do
				local lowermap = string.lower(map)
				local realmap = RealMap(lowermap)
				if realmap == currentmap then
					if maps[i + 1] then
						local nextmap = RealMap(maps[i + 1])
						if nextmap then
							RunConsoleCommand("changelevel", nextmap)
						end
					else
						local nextmap = RealMap(maps[1])
						if nextmap then
							RunConsoleCommand("changelevel", nextmap)
						end
					end

					break
				end
			end
		end
	end
end

function GM:TryHumanPickup(pl, entity)
    if entity:IsValid() and not entity.m_NoPickup then
        local entclass = string.sub(entity:GetClass(), 1, 12)
        if (entclass == "prop_physics" or entclass == "func_physbox" or entity.HumanHoldable and entity:HumanHoldable(pl)) and pl:Team() == TEAM_SURVIVOR and pl:Alive() and entity:GetMoveType() == MOVETYPE_VPHYSICS and entity:GetPhysicsObject():IsValid() and entity:GetPhysicsObject():GetMass() <= CARRY_DRAG_MASS and entity:GetPhysicsObject():IsMoveable() and entity:OBBMins():Length() + entity:OBBMaxs():Length() <= CARRY_DRAG_VOLUME then
            local holder, status = entity:GetHolder()
            if not holder and not pl:IsHolding() and CurTime() >= (pl.NextHold or 0)
            and pl:GetShootPos():Distance(entity:NearestPoint(pl:GetShootPos())) <= 64 and pl:GetGroundEntity() ~= entity then
                local newstatus = ents.Create("status_human_holding")
                if newstatus:IsValid() then
                    pl.NextHold = CurTime() + 0.25
                    pl.NextUnHold = CurTime() + 0.05
                    newstatus:SetPos(pl:GetShootPos())
                    newstatus:SetOwner(pl)
                    newstatus:SetParent(pl)
                    newstatus:SetObject(entity)
                    newstatus:Spawn()
                end
            end
        end
    end
end

function GM:KeyPress(pl, key)
    if key == IN_USE then
        if pl:Team() == TEAM_SURVIVOR and pl:Alive() then
            if pl:IsCarrying() then
                pl.status_human_holding:Remove()
            else
                self:TryHumanPickup(pl, pl:TraceLine(64).Entity)
            end
        end
	end
end

function GM:PlayerUse(pl, ent)
    if not pl:Alive() or pl:Team() == TEAM_ZOMBIEMASTER then return false end
	
	local entclass = ent:GetClass()
	if entclass == "prop_door_rotating" then
		if CurTime() < (ent.m_AntiDoorSpam or 0) then -- Prop doors can be glitched shut by mashing the use button.
			return false
		end
		ent.m_AntiDoorSpam = CurTime() + 0.85
	end

    if pl:IsHolding() and pl:GetHolding() ~= ent then return false end
	
    if pl:Team() == TEAM_SURVIVOR and not pl:IsCarrying() and pl:KeyPressed(IN_USE) then
        self:TryHumanPickup(pl, ent)
    end

    return true
end

function GM:PlayerSwitchFlashlight(pl, newstate)
	if pl:Team() == TEAM_ZOMBIEMASTER then
		pl:SendLua("RunConsoleCommand('zm_power_nightvision')")
		return false
	end

	return pl:IsSurvivor()
end

function GM:PlayerFootstep(pl, vPos, iFoot, strSoundName, fVolume, pFilter)
end

function GM:PlayerStepSoundTime(pl, iType, bWalking)
	local fStepTime = 350

	if iType == STEPSOUNDTIME_NORMAL or iType == STEPSOUNDTIME_WATER_FOOT then
		local fMaxSpeed = pl:GetMaxSpeed()
		if fMaxSpeed <= 100 then
			fStepTime = 400
		elseif fMaxSpeed <= 300 then
			fStepTime = 350
		else
			fStepTime = 250
		end
	elseif iType == STEPSOUNDTIME_ON_LADDER then
		fStepTime = 450
	elseif iType == STEPSOUNDTIME_WATER_KNEE then
		fStepTime = 600
	end

	if pl:Crouching() then
		fStepTime = fStepTime + 50
	end

	return fStepTime
end

function GM:PlayerStepSoundTime(pl, iType, bWalking)
	return 350
end

function GM:PlayerCanPickupWeapon(pl, ent)
	if pl:Team() == TEAM_ZOMBIEMASTER then
		return false
	end
	
	return true
end

function GM:SetCurZombiePop(amount)
	if amount == 0 then
		SetGlobalInt("m_iZombiePopCount", 0)
	else
		SetGlobalInt("m_iZombiePopCount", amount)
	end
end

function GM:SpawnZombie(pZM, entname, origin, angles, cost)
	local popcost = gamemode.Call("GetPopulationCost", entname)
	if (self:GetCurZombiePop() + popcost) > self:GetMaxZombiePop() then
		pZM:PrintMessage(HUD_PRINTCENTER, "Failed to spawn zombie: population limit reached!/n")
		return NULL
	end

	local pZombie = ents.Create(entname)

	if IsValid(pZombie) then
		pZombie:SetPos(origin)
		pZombie:DropToFloor()
		pZombie:SetOwner(pZM)

		angles.x = 0.0
		angles.z = 0.0
		pZombie:SetAngles(angles)

		pZombie:Spawn()
		pZombie:Activate()
		
		pZM:TakeZMPoints(cost)
		gamemode.Call("SetCurZombiePop", GAMEMODE:GetCurZombiePop() + popcost)

		return pZombie
	end
	
	return NULL
end

net.Receive("zm_trigger", function(length)
	local ent = net.ReadEntity()
	local activator = net.ReadEntity()
	local type = net.ReadString()
	
	if type == "trap" then
		ent:Trigger(activator)
	elseif type == "spawn" then
		ent:CreateUnit("npc_zombie")
	end
end)

function GM:AddResources()
	resource.AddWorkshop("591300663")
end