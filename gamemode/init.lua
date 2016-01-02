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
	util.AddNetworkString("zm_topnotify")
	util.AddNetworkString("zm_centernotify")
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

GM.RagdollTable = {}
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

function GM:IncreaseResources()
	local players = #team.GetPlayers(TEAM_SURVIVOR)
	local resources = self:GetZMPoints()
	local increase = GetConVar("zm_maxresource_increase"):GetInt()
	local pZM = self:FindZM()
	
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

function GM:PlayerDeath(victim, inflictor, attacker)
	if inflictor.cpt_SNPC then
		if inflictor == attacker then
			inflictor:cpt_OnKilledEnemy("Player")
		end
	end	
end
		
function GM:DoPlayerDeath(ply, attacker, dmginfo)
	ply:CreateRagdoll()
	ply:AddDeaths( 1 )
	
	if IsValid(attacker) and attacker:IsPlayer() then
		if attacker == ply then
			attacker:AddFrags( -1 )
		else
			attacker:AddFrags( 1 )
		end
	end
	
	ply:PlayDeathSound()
	ply:ChangeTeam(TEAM_SPECTATOR)
	
	if not self:GetRoundEnd() then
		if team.NumPlayers(TEAM_SURVIVOR) <= 0 then
			gamemode.Call("TeamVictorious", false, "Undeath has prevailed!\n")
		end
	end
	
	local pZM = self:FindZM()
	if IsValid(pZM) and ply:IsSurvivor() then
		local income = math.random(GetConVar("zm_resourcegainperplayerdeathmin"):GetInt(), GetConVar("zm_resourcegainperplayerdeathmax"):GetInt())
		
		pZM:AddZMPoints(income)
		pZM:SetZMPointIncome(income)
	end
	
	return
end

function GM:CenterNotifyAll(...)
	net.Start("zs_centernotify")
		net.WriteTable({...})
	net.Broadcast()
end
GM.CenterNotify = GM.CenterNotifyAll

function GM:TopNotifyAll(...)
	net.Start("zs_topnotify")
		net.WriteTable({...})
	net.Broadcast()
end
GM.TopNotify = GM.TopNotifyAll

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
	
	if self.ReadyTimer == 0 and not zm_timer_started then
		zm_timer_started = true
		self.ReadyTimer = RealTime() + 10
	end
	
	if #self.ConnectingPlayers > 0 and RealTime() < self.ReadyTimer then
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

function GM:SpawnZombie(entname, origin, angles, cost)
	local pZM = self:FindZM()
	local popcost = gamemode.Call("GetPopulationCost", entname)
	if (self:GetCurZombiePop() + popcost) > self:GetMaxZombiePop() then
		pZM:PrintMessage(HUD_PRINTCENTER, "Failed to spawn zombie: population limit reached!/n")
		return NULL
	end

	local pZombie = ents.Create(entname)

	if IsValid(pZombie) then
		pZombie:SetPos(origin)

		angles.x = 0.0
		angles.z = 0.0
		pZombie:SetAngles(angles)

		pZombie:Spawn()
		pZombie:Activate()
		
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
	resource.AddFile( "materials/background01.vtf" )
	
	resource.AddFile( "materials/bboard/zm_bboard_batt.vmt" )
	resource.AddFile( "materials/bboard/zm_bboard_batt.vtf" )
	resource.AddFile( "materials/bboard/zm_bboard_btyre.vmt" )
	resource.AddFile( "materials/bboard/zm_bboard_btyre.vtf" )
	resource.AddFile( "materials/bboard/zm_bboard_fcan1.vmt" )
	resource.AddFile( "materials/bboard/zm_bboard_fcan1.vtf" )
	resource.AddFile( "materials/bboard/zm_bboard_fcan2.vmt" )
	resource.AddFile( "materials/bboard/zm_bboard_fcan2.vtf" )
	resource.AddFile( "materials/bboard/zm_bboard_ftyre.vmt" )
	resource.AddFile( "materials/bboard/zm_bboard_ftyre.vtf" )
	resource.AddFile( "materials/bboard/zm_bboard_items.vmt" )
	resource.AddFile( "materials/bboard/zm_bboard_items.vtf" )
	
	resource.AddFile( "materials/concrete/concretefloor010b_nobump.vmt" )
	resource.AddFile( "materials/concrete/concretefloor013c_nobump.vmt" )
	resource.AddFile( "materials/concrete/concretefloor028c_nobump.vmt" )
	resource.AddFile( "materials/concrete/concretefloor037b_nobump.vmt" )
	resource.AddFile( "materials/concrete/concretefloor039a_nobump.vmt" )
	resource.AddFile( "materials/concrete/concretefloor039b_nobump.vmt" )
	resource.AddFile( "materials/concrete/concretewall004b_nobump.vmt" )
	resource.AddFile( "materials/concrete/concretewall004c_nobump.vmt" )
	resource.AddFile( "materials/containers/metalcrate001a.vmt" )
	resource.AddFile( "materials/containers/metalcrate001a.vtf" )
	resource.AddFile( "materials/containers/metalcrate001b.vmt" )
	resource.AddFile( "materials/containers/metalcrate001b.vtf" )
	resource.AddFile( "materials/containers/metalcrate001c.vmt" )
	resource.AddFile( "materials/containers/metalcrate001c.vtf" )
	resource.AddFile( "materials/containers/metalcrate001d.vmt" )
	resource.AddFile( "materials/containers/metalcrate001d.vtf" )
	resource.AddFile( "materials/containers/metalcrate002a.vmt" )
	resource.AddFile( "materials/containers/metalcrate002a.vtf" )
	resource.AddFile( "materials/containers/metalcrate002b.vmt" )
	resource.AddFile( "materials/containers/metalcrate002b.vtf" )
	resource.AddFile( "materials/containers/metalcrate002c.vmt" )
	resource.AddFile( "materials/containers/metalcrate002c.vtf" )
	resource.AddFile( "materials/containers/metalcrate002d.vmt" )
	resource.AddFile( "materials/containers/metalcrate002d.vtf" )
	resource.AddFile( "materials/containers/metalcrate004d.vmt" )
	resource.AddFile( "materials/containers/metalcrate004d.vtf" )
	resource.AddFile( "materials/containers/metalcrate005a.vmt" )
	resource.AddFile( "materials/containers/metalcrate005a.vtf" )
	resource.AddFile( "materials/containers/metalcrate006a.vmt" )
	resource.AddFile( "materials/containers/metalcrate006a.vtf" )
	resource.AddFile( "materials/containers/metalcrate007a.vmt" )
	resource.AddFile( "materials/containers/metalcrate007a.vtf" )
	resource.AddFile( "materials/containers/metalcrate008a.vmt" )
	resource.AddFile( "materials/containers/metalcrate008a.vtf" )
	resource.AddFile( "materials/containers/metalcrate009a.vmt" )
	resource.AddFile( "materials/containers/metalcrate009a.vtf" )
	resource.AddFile( "materials/containers/metalcrate010a.vmt" )
	resource.AddFile( "materials/containers/metalcrate010a.vtf" )
	resource.AddFile( "materials/containers/picrate_512_clean.vmt" )
	resource.AddFile( "materials/containers/picrate_512_clean.vtf" )
	resource.AddFile( "materials/containers/picrate_512_het.vmt" )
	resource.AddFile( "materials/containers/picrate_512_het.vtf" )
	resource.AddFile( "materials/containers/picrate_long.vtf" )
	resource.AddFile( "materials/containers/picrate_long_clean.vmt" )
	resource.AddFile( "materials/containers/picrate_long_clean.vtf" )
	resource.AddFile( "materials/containers/picrate_long_mil.vmt" )
	resource.AddFile( "materials/containers/picrate_long_mil.vtf" )
	resource.AddFile( "materials/containers/warehouse_crate_1.vmt" )
	resource.AddFile( "materials/containers/warehouse_crate_1.vtf" )
	
	resource.AddFile( "materials/decals/decalgraffiti003a.vtf" )
	resource.AddFile( "materials/decals/decalgraffiti011a.vtf" )
	resource.AddFile( "materials/decals/decalgraffiti012a.vtf" )
	resource.AddFile( "materials/decals/decalgraffiti024a.vtf" )
	resource.AddFile( "materials/decals/decalgraffiti037a.vtf" )
	resource.AddFile( "materials/decals/decalgraffiti056a.vtf" )
	resource.AddFile( "materials/decals/decalgraffiti059a.vtf" )
	resource.AddFile( "materials/decals/decal_posterbreen.vtf" )
	resource.AddFile( "materials/decals/decal_posters002a.vtf" )
	resource.AddFile( "materials/decals/decal_posters003a.vtf" )
	resource.AddFile( "materials/decals/decal_posters005a.vtf" )
	resource.AddFile( "materials/decals/decal_posters006a.vtf" )
	resource.AddFile( "materials/decals/holes64_03.vtf" )
	resource.AddFile( "materials/decals/infwalldetail17.vtf" )
	resource.AddFile( "materials/decals/offpaintingb.vmt" )
	resource.AddFile( "materials/decals/omh_1.vmt" )
	resource.AddFile( "materials/decals/omh_1.vtf" )
	resource.AddFile( "materials/decals/omh_2.vmt" )
	resource.AddFile( "materials/decals/omh_2.vtf" )
	
	resource.AddFile( "materials/effects/strider_bulge_dudv.vtf" )
	resource.AddFile( "materials/effects/strider_bulge_dudv_DX60.vmt" )
	resource.AddFile( "materials/effects/strider_bulge_dx60.vmt" )
	resource.AddFile( "materials/effects/strider_bulge_normal.vtf" )
	resource.AddFile( "materials/effects/zm_arrows.vmt" )
	resource.AddFile( "materials/effects/zm_arrows.vtf" )
	resource.AddFile( "materials/effects/zm_healthring.vmt" )
	resource.AddFile( "materials/effects/zm_healthring.vtf" )
	resource.AddFile( "materials/effects/zm_nightvis.vmt" )
	resource.AddFile( "materials/effects/zm_nightvis.vtf" )
	resource.AddFile( "materials/effects/zm_refract.vmt" )
	resource.AddFile( "materials/effects/zm_ring.vmt" )
	resource.AddFile( "materials/effects/zm_ring.vtf" )
	resource.AddFile( "materials/effects/zombie_select.vmt" )
	resource.AddFile( "materials/effects/zombie_selection.vtf" )
	resource.AddFile( "materials/effects/zombie_selection_alt.vtf" )
	
	resource.AddFile( "materials/lawyer/cratewall_1.vmt" )
	resource.AddFile( "materials/lawyer/cratewall_1.vtf" )
	resource.AddFile( "materials/lawyer/cratewall_1_normal.vtf" )
	resource.AddFile( "materials/lawyer/cratewall_2.vmt" )
	resource.AddFile( "materials/lawyer/cratewall_2.vtf" )
	resource.AddFile( "materials/lawyer/cratewall_2_normal.vtf" )
	resource.AddFile( "materials/lawyer/cratewall_3.vmt" )
	resource.AddFile( "materials/lawyer/cratewall_3.vtf" )
	resource.AddFile( "materials/lawyer/cratewall_3_normal.vtf" )
	resource.AddFile( "materials/lawyer/cratewall_4.vmt" )
	resource.AddFile( "materials/lawyer/cratewall_4.vtf" )
	resource.AddFile( "materials/lawyer/cratewall_4_normal.vtf" )
	resource.AddFile( "materials/lawyer/crate_lawyer.vmt" )
	resource.AddFile( "materials/lawyer/crate_lawyer.vtf" )
	resource.AddFile( "materials/lawyer/crate_lawyer_normal.vtf" )
	resource.AddFile( "materials/lawyer/crate_lawyer_top.vmt" )
	resource.AddFile( "materials/lawyer/crate_lawyer_top.vtf" )
	resource.AddFile( "materials/lawyer/crate_lawyer_top_normal.vtf" )
	resource.AddFile( "materials/lawyer/serverroomcarpet.vmt" )
	resource.AddFile( "materials/lawyer/serverroomcarpet.vtf" )
	resource.AddFile( "materials/lawyer/serverroomcarpet_normal.vtf" )
	resource.AddFile( "materials/lawyer.vtf" )
	
	resource.AddFile( "materials/lostcoast/models/props_monastery/interior_dome_wall_window.vmt" )
	resource.AddFile( "materials/lostcoast/models/props_monastery/interior_dome_wall_window.vtf" )
	resource.AddFile( "materials/lostcoast/models/props_monastery/interior_dome_wall_window_dx60.vmt" )
	resource.AddFile( "materials/lostcoast/models/props_monastery/interior_dome_wall_window_normal.vtf" )
	resource.AddFile( "materials/lostcoast/models/props_monastery/Monastery_Stain_Window001a.vmt" )
	resource.AddFile( "materials/lostcoast/models/props_monastery/Monastery_Stain_Window001a.vtf" )
	resource.AddFile( "materials/lostcoast/models/props_monastery/Monastery_Stain_Window001a_dx60.vmt" )
	resource.AddFile( "materials/lostcoast/models/props_monastery/Monastery_Stain_Window001a_normal.vtf" )
	
	resource.AddFile( "materials/metal/citadel_metalwall077a_nospec.vmt" )
	resource.AddFile( "materials/metal/citadel_metalwall077a_nospec.vtf" )
	resource.AddFile( "materials/metal/metalcrate001pi.vmt" )
	resource.AddFile( "materials/metal/metalcrate001pi.vtf" )
	resource.AddFile( "materials/metal/metalfilecabinet002a.vmt" )
	resource.AddFile( "materials/metal/metalfilecabinet002a.vtf" )
	resource.AddFile( "materials/metal/metalpipe003a.vmt" )
	resource.AddFile( "materials/metal/metalwall001a_nobump.vmt" )
	resource.AddFile( "materials/metal/metalwall001b_nobump.vmt" )
	resource.AddFile( "materials/metal/metalwall001d_nobump.vmt" )
	resource.AddFile( "materials/metal/metalwall001f_nobump.vmt" )
	resource.AddFile( "materials/metal/metalwall014a_nobump.vmt" )
	resource.AddFile( "materials/metal/metalwall018a_nobump.vmt" )
	resource.AddFile( "materials/metal/metalwall018b_nobump.vmt" )
	resource.AddFile( "materials/metal/metalwall018e_nobump.vmt" )
	resource.AddFile( "materials/metal/metalwall018f_nobump.vmt" )
	resource.AddFile( "materials/metal/metalwall021a_nobump.vmt" )
	resource.AddFile( "materials/metal/metalwall021b_nobump.vmt" )
	resource.AddFile( "materials/metal/metalwall021e_nobump.vmt" )
	resource.AddFile( "materials/metal/metalwall021f_nobump.vmt" )
	resource.AddFile( "materials/metal/metalwall026a_nobump.vmt" )
	resource.AddFile( "materials/metal/metalwall058a.vmt" )
	resource.AddFile( "materials/metal/metalwall058a.vtf" )
	
	resource.AddFile( "materials/models/blue.vmt" )
	resource.AddFile( "materials/models/blue.vtf" )
	resource.AddFile( "materials/models/glow.vmt" )
	resource.AddFile( "materials/models/glow.vtf" )
	resource.AddFile( "materials/models/glow_orange.vtf" )
	resource.AddFile( "materials/models/Gold.vmt" )
	resource.AddFile( "materials/models/gold.vtf" )
	
	resource.AddFile( "materials/models/humans/female/group01/Fem_Survivor1.vmt" )
	resource.AddFile( "materials/models/humans/female/group01/Fem_Survivor2.vmt" )
	resource.AddFile( "materials/models/humans/female/group01/Fem_Survivor3.vmt" )
	resource.AddFile( "materials/models/humans/female/group01/Fem_Survivor4.vmt" )
	resource.AddFile( "materials/models/humans/female/group01/Fem_Survivor6.vmt" )
	resource.AddFile( "materials/models/humans/female/group01/Fem_Survivor7.vmt" )
	resource.AddFile( "materials/models/humans/female/group02/Fem_Survivor1.vmt" )
	resource.AddFile( "materials/models/humans/female/group02/Fem_Survivor1.vtf" )
	resource.AddFile( "materials/models/humans/female/group02/Fem_Survivor2.vmt" )
	resource.AddFile( "materials/models/humans/female/group02/Fem_Survivor2.vtf" )
	resource.AddFile( "materials/models/humans/female/group02/Fem_Survivor3.vmt" )
	resource.AddFile( "materials/models/humans/female/group02/Fem_Survivor3.vtf" )
	resource.AddFile( "materials/models/humans/female/group02/Fem_Survivor4.vmt" )
	resource.AddFile( "materials/models/humans/female/group02/Fem_Survivor4.vtf" )
	resource.AddFile( "materials/models/humans/female/group02/Fem_Survivor6.vmt" )
	resource.AddFile( "materials/models/humans/female/group02/Fem_Survivor6.vtf" )
	resource.AddFile( "materials/models/humans/female/group02/Fem_Survivor7.vmt" )
	resource.AddFile( "materials/models/humans/female/group02/Fem_Survivor7.vtf" )
	
	resource.AddFile( "materials/models/humans/male/group02/citizen_sheet_pi.vmt" )
	resource.AddFile( "materials/models/humans/male/group02/citizen_sheet_pi.vtf" )
	resource.AddFile( "materials/models/humans/male/group02/citizen_sheet_pi_normal.vtf" )
	resource.AddFile( "materials/models/humans/male/group02/pi_facemap.vmt" )
	resource.AddFile( "materials/models/humans/male/group02/pi_facemap.vtf" )
	
	resource.AddFile( "materials/models/items/revolverammo.vmt" )
	resource.AddFile( "materials/models/items/revolverammo.vtf" )
	
	resource.AddFile( "materials/models/largedoor_right.vmt" )
	resource.AddFile( "materials/models/largedoor_right.vtf" )
	
	resource.AddFile( "materials/models/null.vmt" )
	resource.AddFile( "materials/models/null.vtf" )
	resource.AddFile( "materials/models/orange.vmt" )
	
	resource.AddFile( "materials/models/props/bell.vmt" )
	resource.AddFile( "materials/models/props/bell.vtf" )
	resource.AddFile( "materials/models/props/deathball_sheet.vmt" )
	resource.AddFile( "materials/models/props/deathball_sheet.vtf" )
	resource.AddFile( "materials/models/props/metalceiling005a.vmt" )
	resource.AddFile( "materials/models/props/metalceiling005a.vtf" )
	resource.AddFile( "materials/models/props/metalceiling005a_normal.vtf" )
	resource.AddFile( "materials/models/props/pew.vmt" )
	resource.AddFile( "materials/models/props/pew.vtf" )
	resource.AddFile( "materials/models/props_c17/Frame002a_skin2.vtf" )
	resource.AddFile( "materials/models/props_c17/Frame002a_skin3.vtf" )
	resource.AddFile( "materials/models/props_c17/Frame002a_skin4.vtf" )
	resource.AddFile( "materials/models/props_c17/Frame002a_skin5.vtf" )
	resource.AddFile( "materials/models/props_c17/Frame002a_skin6.vtf" )
	resource.AddFile( "materials/models/props_c17/Oil_Drum001_splode.vmt" )
	resource.AddFile( "materials/models/props_c17/Oil_Drum001_splode.vtf" )
	resource.AddFile( "materials/models/props_interiors/SodaMachine01a.vmt" )
	resource.AddFile( "materials/models/props_interiors/SodaMachine01a.vtf" )
	resource.AddFile( "materials/models/props_junk/garbage003a_01.vtf" )
	resource.AddFile( "materials/models/props_junk/PopCan01a.vtf" )
	resource.AddFile( "materials/models/props_junk/PopCan02a.vtf" )
	resource.AddFile( "materials/models/props_junk/PopCan03a.vtf" )
	resource.AddFile( "materials/models/props_lab/bewaredog.vtf" )
	resource.AddFile( "materials/models/props_lab/clipboard_sheet.vtf" )
	resource.AddFile( "materials/models/props_lab/computer_disp.vtf" )
	resource.AddFile( "materials/models/props_lab/corkboard001_sheet.vtf" )
	resource.AddFile( "materials/models/props_lab/corkboard002_sheet.vtf" )
	resource.AddFile( "materials/models/props_lab/photo_group001a.vtf" )
	resource.AddFile( "materials/models/props_lab/photo_group002a.vtf" )
	resource.AddFile( "materials/models/props_lab/security_screen.vtf" )
	resource.AddFile( "materials/models/props_lab/security_screens.vtf" )
	resource.AddFile( "materials/models/props_lab/workspace_sheet.vtf" )
	resource.AddFile( "materials/models/props_vehicles/Apc001.vmt" )
	resource.AddFile( "materials/models/props_vehicles/Apc001.vtf" )
	resource.AddFile( "materials/models/props_vehicles/Apc_Tire001.vmt" )
	resource.AddFile( "materials/models/props_vehicles/Apc_Tire001.vtf" )
	
	resource.AddFile( "materials/models/Red.vmt" )
	resource.AddFile( "materials/models/red.vtf" )
	resource.AddFile( "materials/models/red2.vmt" )
	
	resource.AddFile( "materials/models/ship1/largedoor_left.vmt" )
	resource.AddFile( "materials/models/ship1/largedoor_left.vtf" )
	resource.AddFile( "materials/models/ship1/largedoor_right.vmt" )
	resource.AddFile( "materials/models/ship1/largedoor_right.vtf" )
	
	resource.AddFile( "materials/models/shotgun/casing01.vmt" )
	resource.AddFile( "materials/models/shotgun/casing01.vtf" )
	resource.AddFile( "materials/models/shotgun/shotgun_zm_diffuse.vmt" )
	resource.AddFile( "materials/models/shotgun/shotgun_zm_diffuse.vtf" )
	resource.AddFile( "materials/models/shotgun/shotgun_zm_exp.vtf" )
	resource.AddFile( "materials/models/shotgun/shotgun_zm_normals.vtf" )
	resource.AddFile( "materials/models/shotgun/shotgun_zm_normals_env.vtf" )
	resource.AddFile( "materials/models/shotgun/v_hand_sheet.vmt" )
	resource.AddFile( "materials/models/shotgun/v_hand_sheet.vtf" )
	resource.AddFile( "materials/models/shotgun/v_hand_sheet_normal.vtf" )
	
	resource.AddFile( "materials/models/Silver.vmt" )
	resource.AddFile( "materials/models/silver.vtf" )
	
	resource.AddFile( "materials/models/weapons/flashlight_zm/flashlight3rd_diffuse.vmt" )
	resource.AddFile( "materials/models/weapons/flashlight_zm/flashlight3rd_diffuse.vtf" )
	resource.AddFile( "materials/models/weapons/flashlight_zm/flashlight_diffuse.vmt" )
	resource.AddFile( "materials/models/weapons/flashlight_zm/flashlight_diffuse.vtf" )
	resource.AddFile( "materials/models/weapons/flashlight_zm/flashlight_normal.vtf" )
	
	resource.AddFile( "materials/models/weapons/hands_zm/v_hand_sheet.vmt" )
	resource.AddFile( "materials/models/weapons/hands_zm/v_hand_sheet_zm.vmt" )
	resource.AddFile( "materials/models/weapons/hands_zm/v_hand_sheet_zm.vtf" )
	resource.AddFile( "materials/models/weapons/hands_zm/v_hand_sheet_zm_normal.vtf" )
	
	resource.AddFile( "materials/models/weapons/molotov_zm/fire.vmt" )
	resource.AddFile( "materials/models/weapons/molotov_zm/fireoff.vmt" )
	resource.AddFile( "materials/models/weapons/molotov_zm/fireoff.vtf" )
	resource.AddFile( "materials/models/weapons/molotov_zm/molotovfull_diffuse.vmt" )
	resource.AddFile( "materials/models/weapons/molotov_zm/molotovfull_diffuse.vtf" )
	resource.AddFile( "materials/models/weapons/molotov_zm/molotovfull_normal.vtf" )
	resource.AddFile( "materials/models/weapons/molotov_zm/molotov_3rdDiffuse.vmt" )
	resource.AddFile( "materials/models/weapons/molotov_zm/molotov_3rdDiffuse.vtf" )
	resource.AddFile( "materials/models/weapons/molotov_zm/molotov_3rdNormalsMap.vtf" )
	
	resource.AddFile( "materials/models/weapons/pistol_zm/pistol3rd_diffuse.vmt" )
	resource.AddFile( "materials/models/weapons/pistol_zm/pistol3rd_diffuse.vtf" )
	resource.AddFile( "materials/models/weapons/pistol_zm/pistol3rd_normal.vtf" )
	resource.AddFile( "materials/models/weapons/pistol_zm/pistol_diffuse.vmt" )
	resource.AddFile( "materials/models/weapons/pistol_zm/pistol_diffuse.vtf" )
	resource.AddFile( "materials/models/weapons/pistol_zm/pistol_normal.vtf" )
	
	resource.AddFile( "materials/models/weapons/rifle_zm/rifle_zm_3rd.vmt" )
	resource.AddFile( "materials/models/weapons/rifle_zm/rifle_zm_3rd.vtf" )
	resource.AddFile( "materials/models/weapons/rifle_zm/rifle_zm_3rd_specular_mask.vtf" )
	resource.AddFile( "materials/models/weapons/rifle_zm/rifle_zm_cartridge.vmt" )
	resource.AddFile( "materials/models/weapons/rifle_zm/rifle_zm_cartridge.vtf" )
	resource.AddFile( "materials/models/weapons/rifle_zm/rifle_zm_diffuse.vmt" )
	resource.AddFile( "materials/models/weapons/rifle_zm/rifle_zm_diffuse.vtf" )
	resource.AddFile( "materials/models/weapons/rifle_zm/rifle_zm_normal.vtf" )
	
	resource.AddFile( "materials/models/weapons/shotgun_zm/shotgun4.vtf" )
	resource.AddFile( "materials/models/weapons/shotgun_zm/shotgun4diffuse.vmt" )
	resource.AddFile( "materials/models/weapons/shotgun_zm/shotgun4diffuse.vtf" )
	
	resource.AddFile( "materials/models/weapons/sledgehammer_zm/sledgehammer.vmt" )
	resource.AddFile( "materials/models/weapons/sledgehammer_zm/sledgehammer_diffuse.vtf" )
	resource.AddFile( "materials/models/weapons/sledgehammer_zm/sledgehammer_normal.vtf" )
	resource.AddFile( "materials/models/weapons/sledgehammer_zm/sledge_sheet.vmt" )
	resource.AddFile( "materials/models/weapons/sledgehammer_zm/sledge_sheet.vtf" )
	resource.AddFile( "materials/models/weapons/sledgehammer_zm/sledge_sheet_nrml.vtf" )
	
	resource.AddFile( "materials/models/weapons/v_mac_zm/mac10_sheet.vmt" )
	resource.AddFile( "materials/models/weapons/v_mac_zm/mac10_sheet.vtf" )
	resource.AddFile( "materials/models/weapons/v_mac_zm/mac10_sheet_spec.vtf" )
	
	resource.AddFile( "materials/models/weapons/v_revolver_zm/v_revolver_sheet.vmt" )
	resource.AddFile( "materials/models/weapons/v_revolver_zm/v_revolver_sheet.vtf" )
	resource.AddFile( "materials/models/weapons/v_revolver_zm/v_revolver_sheet_nrml.vtf" )
	
	resource.AddFile( "materials/models/weapons/v_shotgun/remington_sheet.vmt" )
	resource.AddFile( "materials/models/weapons/v_shotgun/remington_sheet.vtf" )
	resource.AddFile( "materials/models/weapons/v_shotgun/remington_sheet_spec.vtf" )
	
	resource.AddFile( "materials/models/weapons/v_slam/new lense.vmt" )
	resource.AddFile( "materials/models/weapons/v_slam/new lense.vtf" )
	resource.AddFile( "materials/models/weapons/v_slam/new light1.vmt" )
	resource.AddFile( "materials/models/weapons/v_slam/new light1.vtf" )
	resource.AddFile( "materials/models/weapons/v_slam/new light2.vmt" )
	resource.AddFile( "materials/models/weapons/v_slam/new light2.vtf" )
	resource.AddFile( "materials/models/weapons/v_slam/new slam.vmt" )
	resource.AddFile( "materials/models/weapons/v_slam/new slam.vtf" )
	resource.AddFile( "materials/models/weapons/v_slam/retexture trigger.vmt" )
	resource.AddFile( "materials/models/weapons/v_slam/retexture trigger.vtf" )
	resource.AddFile( "materials/models/weapons/v_slam/v_slam.vmt" )
	resource.AddFile( "materials/models/weapons/v_slam/v_slam.vtf" )
	resource.AddFile( "materials/models/weapons/v_slam/v_slam_normal.vtf" )
	
	resource.AddFile( "materials/models/weapons/v_smg/mac10_sheet.vmt" )
	resource.AddFile( "materials/models/weapons/v_smg/mac10_sheet.vtf" )
	resource.AddFile( "materials/models/weapons/v_smg/mac10_spec.vtf" )
	
	resource.AddFile( "materials/models/weapons/v_stunstick/v_stunstick_diffuse.vmt" )
	resource.AddFile( "materials/models/weapons/v_stunstick/v_stunstick_diffuse.vtf" )
	resource.AddFile( "materials/models/weapons/v_stunstick/v_stunstick_normal.vtf" )
	
	resource.AddFile( "materials/models/weapons/w_357/w_357.vmt" )
	resource.AddFile( "materials/models/weapons/w_357/w_357.vtf" )
	resource.AddFile( "materials/models/weapons/w_357/w_357_spec.vtf" )
	
	resource.AddFile( "materials/models/weapons/w_shotgun_zm/w_shotgun_zm.vmt" )
	resource.AddFile( "materials/models/weapons/w_shotgun_zm/w_shotgun_zm.vtf" )
	
	resource.AddFile( "materials/models/weapons/zm_pistol/pist_fiveseven.vmt" )
	resource.AddFile( "materials/models/weapons/zm_pistol/pist_fiveseven.vtf" )
	resource.AddFile( "materials/models/weapons/zm_pistol/pist_fiveseven_ref.vtf" )
	
	resource.AddFile( "materials/models/Zombie/zombie_classic/art_facemap.vtf" )
	resource.AddFile( "materials/models/Zombie/zombie_classic/mike_facemap.vtf" )
	resource.AddFile( "materials/models/Zombie/zombie_classic/test_facemap.vtf" )
	resource.AddFile( "materials/models/Zombie/zombie_classic_humantest/eyeball_l.vtf" )
	resource.AddFile( "materials/models/Zombie/zombie_classic_humantest/pupil_l.vtf" )
	
	resource.AddFile( "materials/models/Zombie_Classic/art_facemap.vmt" )
	resource.AddFile( "materials/models/Zombie_Classic/art_facemap.vtf" )
	resource.AddFile( "materials/models/Zombie_Classic/citizen_sheet.vmt" )
	resource.AddFile( "materials/models/Zombie_Classic/citizen_sheet.vtf" )
	resource.AddFile( "materials/models/Zombie_Classic/citizen_sheet2.vmt" )
	resource.AddFile( "materials/models/Zombie_Classic/citizen_sheet2.vtf" )
	resource.AddFile( "materials/models/Zombie_Classic/citizen_sheet3.vmt" )
	resource.AddFile( "materials/models/Zombie_Classic/citizen_sheet3.vtf" )
	resource.AddFile( "materials/models/Zombie_Classic/corpse1.vmt" )
	resource.AddFile( "materials/models/Zombie_Classic/corpse1.vtf" )
	resource.AddFile( "materials/models/Zombie_Classic/dark_eyeball_l.vmt" )
	resource.AddFile( "materials/models/Zombie_Classic/dark_eyeball_r.vmt" )
	resource.AddFile( "materials/models/Zombie_Classic/erdim_cylmap.vmt" )
	resource.AddFile( "materials/models/Zombie_Classic/erdim_cylmap.vtf" )
	resource.AddFile( "materials/models/Zombie_Classic/eric_facemap.vmt" )
	resource.AddFile( "materials/models/Zombie_Classic/eric_facemap.vtf" )
	resource.AddFile( "materials/models/Zombie_Classic/eyeball_l.vmt" )
	resource.AddFile( "materials/models/Zombie_Classic/eyeball_l.vtf" )
	resource.AddFile( "materials/models/Zombie_Classic/eyeball_r.vmt" )
	resource.AddFile( "materials/models/Zombie_Classic/eyeball_r.vtf" )
	resource.AddFile( "materials/models/Zombie_Classic/joe_facemap.vmt" )
	resource.AddFile( "materials/models/Zombie_Classic/joe_facemap.vtf" )
	resource.AddFile( "materials/models/Zombie_Classic/mike_facemap.vmt" )
	resource.AddFile( "materials/models/Zombie_Classic/mike_facemap.vtf" )
	resource.AddFile( "materials/models/Zombie_Classic/pupil_l.vtf" )
	resource.AddFile( "materials/models/Zombie_Classic/pupil_r.vtf" )
	resource.AddFile( "materials/models/Zombie_Classic/sandro_facemap.vmt" )
	resource.AddFile( "materials/models/Zombie_Classic/sandro_facemap.vtf" )
	resource.AddFile( "materials/models/Zombie_Classic/ted_facemap.vmt" )
	resource.AddFile( "materials/models/Zombie_Classic/ted_facemap.vtf" )
	resource.AddFile( "materials/models/Zombie_Classic/vance_facemap.vmt" )
	resource.AddFile( "materials/models/Zombie_Classic/vance_facemap.vtf" )
	resource.AddFile( "materials/models/Zombie_Classic/van_facemap.vmt" )
	resource.AddFile( "materials/models/Zombie_Classic/van_facemap.vtf" )
	
	resource.AddFile( "materials/models/Zombie_Fast/corpse1.vmt" )
	resource.AddFile( "materials/models/Zombie_Fast/corpse1.vtf" )
	
	resource.AddFile( "materials/nature/blenddirtmud003a_nobump.vmt" )
	resource.AddFile( "materials/nature/rockwall006a_nobump.vmt" )
	
	resource.AddFile( "materials/plaster/plasterwall034a_nobump.vmt" )
	resource.AddFile( "materials/plaster/plasterwall034b_nobump.vmt" )
	resource.AddFile( "materials/plaster/plasterwall034d_nobump.vmt" )
	resource.AddFile( "materials/plaster/plasterwall034f_nobump.vmt" )
	
	resource.AddFile( "materials/postprocess/alpha.vtf" )
	resource.AddFile( "materials/postprocess/blend.vmt" )
	resource.AddFile( "materials/postprocess/blurx.vmt" )
	resource.AddFile( "materials/postprocess/blury.vmt" )
	resource.AddFile( "materials/postprocess/nightvision.vmt" )
	
	resource.AddFile( "materials/Props/bell.vmt" )
	resource.AddFile( "materials/Props/bell.vtf" )
	resource.AddFile( "materials/Props/deathball_sheet.vmt" )
	resource.AddFile( "materials/Props/deathball_sheet.vtf" )
	resource.AddFile( "materials/Props/metalceiling005a.vmt" )
	resource.AddFile( "materials/Props/metalceiling005a.vtf" )
	resource.AddFile( "materials/Props/metalceiling005a_normal.vtf" )
	resource.AddFile( "materials/Props/metalfilecabinet002a.vmt" )
	resource.AddFile( "materials/Props/metalfilecabinet002a.vtf" )
	resource.AddFile( "materials/Props/metalladder001.vmt" )
	resource.AddFile( "materials/Props/Metalladder001.vtf" )
	resource.AddFile( "materials/Props/paperposter001a.vtf" )
	resource.AddFile( "materials/Props/paperposter001b.vtf" )
	resource.AddFile( "materials/Props/paperposter002a.vtf" )
	resource.AddFile( "materials/Props/paperposter002b.vtf" )
	resource.AddFile( "materials/Props/paperposter003a.vtf" )
	resource.AddFile( "materials/Props/paperposter003b.vtf" )
	resource.AddFile( "materials/Props/paperposter005a.vtf" )
	
	resource.AddFile( "materials/sign/redsign.vmt" )
	resource.AddFile( "materials/sign/redsign.vtf" )
	resource.AddFile( "materials/sign/whitesign.vmt" )
	resource.AddFile( "materials/sign/whitesign.vtf" )
	
	resource.AddFile( "materials/sprites/fire_greyscale.vtf" )
	resource.AddFile( "materials/sprites/fire_vm.vmt" )
	resource.AddFile( "materials/sprites/fire_vm_grey.vmt" )
	resource.AddFile( "materials/sprites/flamefromabove.vmt" )
	resource.AddFile( "materials/sprites/flamefromabove.vtf" )
	resource.AddFile( "materials/sprites/glow.vmt" )
	resource.AddFile( "materials/sprites/glow.vtf" )
	resource.AddFile( "materials/sprites/glow04_noz.vmt" )
	resource.AddFile( "materials/sprites/orangecore1.vmt" )
	resource.AddFile( "materials/sprites/orangecore2.vmt" )
	resource.AddFile( "materials/sprites/orangeflare1.vmt" )
	resource.AddFile( "materials/sprites/orangelight1.vmt" )
	resource.AddFile( "materials/sprites/orangelight1_noz.vmt" )
	resource.AddFile( "materials/sprites/orangetest.vmt" )
	
	resource.AddFile( "materials/temp/5446d717.vtf" )
	resource.AddFile( "materials/temp/7e52e0ac.vtf" )
	resource.AddFile( "materials/temp/ada7c148.vtf" )
	resource.AddFile( "materials/temp/e4e75983.vtf" )
	
	resource.AddFile( "materials/tile/tilefloor019a_nobump.vmt" )
	
	resource.AddFile( "materials/truckpic/truckpic (13).vmt" )
	resource.AddFile( "materials/truckpic/truckpic (14).vtf" )
	resource.AddFile( "materials/truckpic/truckpic.vmt" )
	resource.AddFile( "materials/truckpic/truckpic.vtf" )
	
	resource.AddFile( "materials/VGUI/gfx/VGUI/hl2mp_logo.vmt" )
	resource.AddFile( "materials/VGUI/gfx/VGUI/hl2mp_logo.vtf" )
	resource.AddFile( "materials/VGUI/gfx/VGUI/not_available.vmt" )
	resource.AddFile( "materials/VGUI/gfx/VGUI/not_available.vtf" )
	resource.AddFile( "materials/VGUI/gfx/VGUI/round_corner_ne.vmt" )
	resource.AddFile( "materials/VGUI/gfx/VGUI/round_corner_ne.vtf" )
	resource.AddFile( "materials/VGUI/gfx/VGUI/round_corner_nw.vmt" )
	resource.AddFile( "materials/VGUI/gfx/VGUI/round_corner_nw.vtf" )
	resource.AddFile( "materials/VGUI/gfx/VGUI/round_corner_se.vmt" )
	resource.AddFile( "materials/VGUI/gfx/VGUI/round_corner_se.vtf" )
	resource.AddFile( "materials/VGUI/gfx/VGUI/round_corner_sw.vmt" )
	resource.AddFile( "materials/VGUI/gfx/VGUI/round_corner_sw.vtf" )
	resource.AddFile( "materials/VGUI/gfx/VGUI/solid_background.vmt" )
	resource.AddFile( "materials/VGUI/gfx/VGUI/solid_background.vtf" )
	resource.AddFile( "materials/VGUI/gfx/VGUI/spray_bullseye.vmt" )
	resource.AddFile( "materials/VGUI/gfx/VGUI/Spray_bullseye.vtf" )
	resource.AddFile( "materials/VGUI/gfx/VGUI/trans_background.vmt" )
	resource.AddFile( "materials/VGUI/gfx/VGUI/trans_background.vtf" )
	resource.AddFile( "materials/VGUI/loading.vmt" )
	resource.AddFile( "materials/VGUI/loading.vtf" )
	resource.AddFile( "materials/VGUI/logos/back.vmt" )
	resource.AddFile( "materials/VGUI/logos/back.vtf" )
	resource.AddFile( "materials/VGUI/logos/brainfork.vmt" )
	resource.AddFile( "materials/VGUI/logos/brainfork.vtf" )
	resource.AddFile( "materials/VGUI/logos/cross.vmt" )
	resource.AddFile( "materials/VGUI/logos/cross.vtf" )
	resource.AddFile( "materials/VGUI/logos/decomposing.vmt" )
	resource.AddFile( "materials/VGUI/logos/decomposing.vtf" )
	resource.AddFile( "materials/VGUI/logos/eat.vmt" )
	resource.AddFile( "materials/VGUI/logos/eat.vtf" )
	resource.AddFile( "materials/VGUI/logos/no.vmt" )
	resource.AddFile( "materials/VGUI/logos/no.vtf" )
	resource.AddFile( "materials/VGUI/logos/pent.vmt" )
	resource.AddFile( "materials/VGUI/logos/pent.vtf" )
	resource.AddFile( "materials/VGUI/logos/pressure.vmt" )
	resource.AddFile( "materials/VGUI/logos/pressure.vtf" )
	resource.AddFile( "materials/VGUI/logos/repent.vmt" )
	resource.AddFile( "materials/VGUI/logos/repent.vtf" )
	resource.AddFile( "materials/VGUI/logos/rip.vmt" )
	resource.AddFile( "materials/VGUI/logos/rip.vtf" )
	resource.AddFile( "materials/VGUI/logos/skull.vmt" )
	resource.AddFile( "materials/VGUI/logos/skull.vtf" )
	resource.AddFile( "materials/VGUI/logos/Spray_canned.vmt" )
	resource.AddFile( "materials/VGUI/logos/Spray_canned.vtf" )
	resource.AddFile( "materials/VGUI/logos/Spray_combine.vmt" )
	resource.AddFile( "materials/VGUI/logos/Spray_combine.vtf" )
	resource.AddFile( "materials/VGUI/logos/Spray_cop.vmt" )
	resource.AddFile( "materials/VGUI/logos/Spray_cop.vtf" )
	resource.AddFile( "materials/VGUI/logos/Spray_dog.vmt" )
	resource.AddFile( "materials/VGUI/logos/Spray_dog.vtf" )
	resource.AddFile( "materials/VGUI/logos/Spray_freeman.vmt" )
	resource.AddFile( "materials/VGUI/logos/Spray_freeman.vtf" )
	resource.AddFile( "materials/VGUI/logos/Spray_head.vmt" )
	resource.AddFile( "materials/VGUI/logos/Spray_head.vtf" )
	resource.AddFile( "materials/VGUI/logos/Spray_lambda.vmt" )
	resource.AddFile( "materials/VGUI/logos/Spray_lambda.vtf" )
	resource.AddFile( "materials/VGUI/logos/Spray_plumbed.vmt" )
	resource.AddFile( "materials/VGUI/logos/Spray_plumbed.vtf" )
	resource.AddFile( "materials/VGUI/logos/Spray_soldier.vmt" )
	resource.AddFile( "materials/VGUI/logos/Spray_soldier.vtf" )
	resource.AddFile( "materials/VGUI/logos/UI/back.vmt" )
	resource.AddFile( "materials/VGUI/logos/UI/brainfork.vmt" )
	resource.AddFile( "materials/VGUI/logos/UI/cross.vmt" )
	resource.AddFile( "materials/VGUI/logos/UI/decomposing.vmt" )
	resource.AddFile( "materials/VGUI/logos/UI/eat.vmt" )
	resource.AddFile( "materials/VGUI/logos/UI/no.vmt" )
	resource.AddFile( "materials/VGUI/logos/UI/pent.vmt" )
	resource.AddFile( "materials/VGUI/logos/UI/pressure.vmt" )
	resource.AddFile( "materials/VGUI/logos/UI/repent.vmt" )
	resource.AddFile( "materials/VGUI/logos/UI/rip.vmt" )
	resource.AddFile( "materials/VGUI/logos/UI/skull.vmt" )
	resource.AddFile( "materials/VGUI/logos/UI/spray_canned.vmt" )
	resource.AddFile( "materials/VGUI/logos/UI/spray_combine.vmt" )
	resource.AddFile( "materials/VGUI/logos/UI/spray_cop.vmt" )
	resource.AddFile( "materials/VGUI/logos/UI/spray_dog.vmt" )
	resource.AddFile( "materials/VGUI/logos/UI/spray_freeman.vmt" )
	resource.AddFile( "materials/VGUI/logos/UI/spray_head.vmt" )
	resource.AddFile( "materials/VGUI/logos/UI/spray_lambda.vmt" )
	resource.AddFile( "materials/VGUI/logos/UI/walk.vmt" )
	resource.AddFile( "materials/VGUI/logos/walk.vmt" )
	resource.AddFile( "materials/VGUI/logos/walk.vtf" )
	resource.AddFile( "materials/VGUI/miniarrows.vmt" )
	resource.AddFile( "materials/VGUI/miniarrows.vtf" )
	resource.AddFile( "materials/VGUI/miniceiling.vmt" )
	resource.AddFile( "materials/VGUI/miniceiling.vtf" )
	resource.AddFile( "materials/VGUI/minicrosshair.vmt" )
	resource.AddFile( "materials/VGUI/minicrosshair.vtf" )
	resource.AddFile( "materials/VGUI/minideletezombies.vmt" )
	resource.AddFile( "materials/VGUI/minideletezombies.vtf" )
	resource.AddFile( "materials/VGUI/minieye.vmt" )
	resource.AddFile( "materials/VGUI/minieye.vtf" )
	resource.AddFile( "materials/VGUI/minifigures.vmt" )
	resource.AddFile( "materials/VGUI/minifigures.vtf" )
	resource.AddFile( "materials/VGUI/minigroupadd.vmt" )
	resource.AddFile( "materials/VGUI/minigroupadd.vtf" )
	resource.AddFile( "materials/VGUI/minigroupselect.vmt" )
	resource.AddFile( "materials/VGUI/minigroupselect.vtf" )
	resource.AddFile( "materials/VGUI/miniselectall.vmt" )
	resource.AddFile( "materials/VGUI/miniselectall.vtf" )
	resource.AddFile( "materials/VGUI/minishield.vmt" )
	resource.AddFile( "materials/VGUI/minishield.vtf" )
	resource.AddFile( "materials/VGUI/minishockwave.vmt" )
	resource.AddFile( "materials/VGUI/minishockwave.vtf" )
	resource.AddFile( "materials/VGUI/miniskull.vmt" )
	resource.AddFile( "materials/VGUI/miniskull.vtf" )
	resource.AddFile( "materials/VGUI/minispotcreate.vmt" )
	resource.AddFile( "materials/VGUI/minispotcreate.vtf" )
	resource.AddFile( "materials/VGUI/playermodels/humans/Group02/female_01.vmt" )
	resource.AddFile( "materials/VGUI/playermodels/humans/Group02/female_01.vtf" )
	resource.AddFile( "materials/VGUI/playermodels/humans/Group02/female_02.vmt" )
	resource.AddFile( "materials/VGUI/playermodels/humans/Group02/female_02.vtf" )
	resource.AddFile( "materials/VGUI/playermodels/humans/Group02/female_03.vmt" )
	resource.AddFile( "materials/VGUI/playermodels/humans/Group02/female_03.vtf" )
	resource.AddFile( "materials/VGUI/playermodels/humans/Group02/female_04.vmt" )
	resource.AddFile( "materials/VGUI/playermodels/humans/Group02/female_04.vtf" )
	resource.AddFile( "materials/VGUI/playermodels/humans/Group02/female_06.vmt" )
	resource.AddFile( "materials/VGUI/playermodels/humans/Group02/female_06.vtf" )
	resource.AddFile( "materials/VGUI/playermodels/humans/Group02/female_07.vmt" )
	resource.AddFile( "materials/VGUI/playermodels/humans/Group02/female_07.vtf" )
	resource.AddFile( "materials/VGUI/playermodels/humans/Group02/Male_01.vmt" )
	resource.AddFile( "materials/VGUI/playermodels/humans/Group02/Male_01.vtf" )
	resource.AddFile( "materials/VGUI/playermodels/humans/Group02/Male_02.vmt" )
	resource.AddFile( "materials/VGUI/playermodels/humans/Group02/Male_02.vtf" )
	resource.AddFile( "materials/VGUI/playermodels/humans/Group02/Male_03.vmt" )
	resource.AddFile( "materials/VGUI/playermodels/humans/Group02/Male_03.vtf" )
	resource.AddFile( "materials/VGUI/playermodels/humans/Group02/Male_04.vmt" )
	resource.AddFile( "materials/VGUI/playermodels/humans/Group02/Male_04.vtf" )
	resource.AddFile( "materials/VGUI/playermodels/humans/Group02/Male_05.vmt" )
	resource.AddFile( "materials/VGUI/playermodels/humans/Group02/Male_05.vtf" )
	resource.AddFile( "materials/VGUI/playermodels/humans/Group02/Male_06.vmt" )
	resource.AddFile( "materials/VGUI/playermodels/humans/Group02/Male_06.vtf" )
	resource.AddFile( "materials/VGUI/playermodels/humans/Group02/Male_07.vmt" )
	resource.AddFile( "materials/VGUI/playermodels/humans/Group02/Male_07.vtf" )
	resource.AddFile( "materials/VGUI/playermodels/humans/Group02/Male_08.vmt" )
	resource.AddFile( "materials/VGUI/playermodels/humans/Group02/Male_08.vtf" )
	resource.AddFile( "materials/VGUI/playermodels/humans/Group02/Male_09.vmt" )
	resource.AddFile( "materials/VGUI/playermodels/humans/Group02/Male_09.vtf" )
	resource.AddFile( "materials/VGUI/playermodels/male_lawyer.vmt" )
	resource.AddFile( "materials/VGUI/playermodels/male_lawyer.vtf" )
	resource.AddFile( "materials/VGUI/playermodels/male_pi.vmt" )
	resource.AddFile( "materials/VGUI/playermodels/male_pi.vtf" )
	resource.AddFile( "materials/VGUI/zombies/banshee.vtf" )
	resource.AddFile( "materials/VGUI/zombies/banshee_small.vtf" )
	resource.AddFile( "materials/VGUI/zombies/drifter.vtf" )
	resource.AddFile( "materials/VGUI/zombies/drifter_small.vtf" )
	resource.AddFile( "materials/VGUI/zombies/hulk.vtf" )
	resource.AddFile( "materials/VGUI/zombies/hulk_small.vtf" )
	resource.AddFile( "materials/VGUI/zombies/immolator.vtf" )
	resource.AddFile( "materials/VGUI/zombies/immolator_small.vtf" )
	resource.AddFile( "materials/VGUI/zombies/info_banshee.vmt" )
	resource.AddFile( "materials/VGUI/zombies/info_drifter.vmt" )
	resource.AddFile( "materials/VGUI/zombies/info_hulk.vmt" )
	resource.AddFile( "materials/VGUI/zombies/info_immolator.vmt" )
	resource.AddFile( "materials/VGUI/zombies/info_shambler.vmt" )
	resource.AddFile( "materials/VGUI/zombies/queue_banshee.vmt" )
	resource.AddFile( "materials/VGUI/zombies/queue_drifter.vmt" )
	resource.AddFile( "materials/VGUI/zombies/queue_hulk.vmt" )
	resource.AddFile( "materials/VGUI/zombies/queue_immolator.vmt" )
	resource.AddFile( "materials/VGUI/zombies/queue_shambler.vmt" )
	resource.AddFile( "materials/VGUI/zombies/shambler.vtf" )
	resource.AddFile( "materials/VGUI/zombies/shambler_small.vtf" )
	
	resource.AddFile( "materials/wood/woodshelf003a.vmt" )
	resource.AddFile( "materials/wood/woodshelf003a.vtf" )
	
	resource.AddFile( "materials/zm_overlay.png" )
	
	resource.AddFile( "models/alphatest.mdl" )
	
	resource.AddFile( "models/humans/zm_draggy.mdl" )
	
	resource.AddFile( "models/items/revolverammo.mdl" )
	
	resource.AddFile( "models/male_pi.mdl" )
	resource.AddFile( "models/manipulatable.mdl" )
	
	resource.AddFile( "models/props/bell.mdl" )
	resource.AddFile( "models/props/deathball.mdl" )
	resource.AddFile( "models/props/pew.mdl" )
	resource.AddFile( "models/props/zm_metalladder001.mdl" )
	resource.AddFile( "models/props_c17/oildrum001_asplode.mdl" )
	resource.AddFile( "models/props_vehicles/apc001.mdl" )
	resource.AddFile( "models/props_vehicles/apc_tire001.mdl" )
	resource.AddFile( "models/props_vehicles/zmapc001.mdl" )
	resource.AddFile( "models/props_vehicles/zmapc_tire001.mdl" )
	
	resource.AddFile( "models/rallypoint.mdl" )
	resource.AddFile( "models/spawnnode.mdl" )
	resource.AddFile( "models/trap.mdl" )
	
	resource.AddFile( "models/weapons/c_fists_zm.mdl" )
	resource.AddFile( "models/weapons/c_flashlight_zm.mdl" )
	resource.AddFile( "models/weapons/c_mac_zm.mdl" )
	resource.AddFile( "models/weapons/c_molotov_zm.mdl" )
	resource.AddFile( "models/weapons/c_pistol_zm.mdl" )
	resource.AddFile( "models/weapons/c_revolver_zm.mdl" )
	resource.AddFile( "models/weapons/c_rifle_zm.mdl" )
	resource.AddFile( "models/weapons/c_shotgun_zm.mdl" )
	resource.AddFile( "models/weapons/c_sledgehammer_zm.mdl" )
	resource.AddFile( "models/weapons/flashlight3rd_zm.mdl" )
	resource.AddFile( "models/weapons/invisible_vm.mdl" )
	resource.AddFile( "models/weapons/molotov3rd_zm.mdl" )
	resource.AddFile( "models/weapons/pistol3rd_zm.mdl" )
	resource.AddFile( "models/weapons/rifle_zm_3rd.mdl" )
	resource.AddFile( "models/weapons/shotgun_zm_3rd.mdl" )
	resource.AddFile( "models/weapons/sledgehammer3rd_zm.mdl" )
	resource.AddFile( "models/weapons/smg_zm_3rd.mdl" )
	resource.AddFile( "models/weapons/w_null.mdl" )
	resource.AddFile( "models/weapons/w_shotgun_zm.mdl" )
	
	resource.AddFile( "models/zombie/burnzie.mdl" )
	resource.AddFile( "models/zombie/hulk.mdl" )
	resource.AddFile( "models/zombie/zm_classic.mdl" )
	resource.AddFile( "models/zombie/zm_classic_01.mdl" )
	resource.AddFile( "models/zombie/zm_classic_02.mdl" )
	resource.AddFile( "models/zombie/zm_classic_03.mdl" )
	resource.AddFile( "models/zombie/zm_classic_04.mdl" )
	resource.AddFile( "models/zombie/zm_classic_05.mdl" )
	resource.AddFile( "models/zombie/zm_classic_06.mdl" )
	resource.AddFile( "models/zombie/zm_classic_07.mdl" )
	resource.AddFile( "models/zombie/zm_classic_08.mdl" )
	resource.AddFile( "models/zombie/zm_classic_09.mdl" )
	resource.AddFile( "models/zombie/zm_classic_10.mdl" )
	resource.AddFile( "models/zombie/zm_fast.mdl" )
	resource.AddFile( "models/zombiespawner.mdl" )
	
	resource.AddFile( "particles/zm_blood.pcf" )
	
	resource.AddFile( "resource/fonts/typenoksidi.ttf" )
	resource.AddFile( "resource/fonts/zombiemaster.ttf" )
	
	resource.AddFile( "sound/ambient/lightning.wav" )
	resource.AddFile( "sound/bell/bell1.wav" )
	resource.AddFile( "sound/common/talk.wav" )
	
	resource.AddFile( "sound/npc/banshee/breathe_loop1.wav" )
	resource.AddFile( "sound/npc/banshee/claw_miss1.wav" )
	resource.AddFile( "sound/npc/banshee/claw_miss2.wav" )
	resource.AddFile( "sound/npc/banshee/claw_strike1.wav" )
	resource.AddFile( "sound/npc/banshee/claw_strike2.wav" )
	resource.AddFile( "sound/npc/banshee/claw_strike3.wav" )
	resource.AddFile( "sound/npc/banshee/foot1.wav" )
	resource.AddFile( "sound/npc/banshee/foot2.wav" )
	resource.AddFile( "sound/npc/banshee/foot3.wav" )
	resource.AddFile( "sound/npc/banshee/foot4.wav" )
	resource.AddFile( "sound/npc/banshee/fz_alert_close1.wav" )
	resource.AddFile( "sound/npc/banshee/fz_alert_far1.wav" )
	resource.AddFile( "sound/npc/banshee/fz_frenzy1.wav" )
	resource.AddFile( "sound/npc/banshee/fz_frenzy2.wav" )
	resource.AddFile( "sound/npc/banshee/fz_frenzy3.wav" )
	resource.AddFile( "sound/npc/banshee/fz_frenzy4.wav" )
	resource.AddFile( "sound/npc/banshee/fz_frenzy5.wav" )
	resource.AddFile( "sound/npc/banshee/fz_frenzy6.wav" )
	resource.AddFile( "sound/npc/banshee/fz_frenzy7.wav" )
	resource.AddFile( "sound/npc/banshee/fz_scream1.wav" )
	resource.AddFile( "sound/npc/banshee/fz_scream2.wav" )
	resource.AddFile( "sound/npc/banshee/fz_scream3.wav" )
	resource.AddFile( "sound/npc/banshee/gurgle_loop1.wav" )
	resource.AddFile( "sound/npc/banshee/idle1.wav" )
	resource.AddFile( "sound/npc/banshee/idle2.wav" )
	resource.AddFile( "sound/npc/banshee/idle3.wav" )
	resource.AddFile( "sound/npc/banshee/leap1.wav" )
	resource.AddFile( "sound/npc/banshee/leap2.wav" )
	resource.AddFile( "sound/npc/banshee/leap3_long.wav" )
	resource.AddFile( "sound/npc/banshee/leap_begin.wav" )
	resource.AddFile( "sound/npc/banshee/test.wav" )
	resource.AddFile( "sound/npc/banshee/wake1.wav" )
	
	resource.AddFile( "sound/npc/shamblie/claw_miss1.wav" )
	resource.AddFile( "sound/npc/shamblie/claw_miss2.wav" )
	resource.AddFile( "sound/npc/shamblie/claw_strike1.wav" )
	resource.AddFile( "sound/npc/shamblie/claw_strike2.wav" )
	resource.AddFile( "sound/npc/shamblie/claw_strike3.wav" )
	resource.AddFile( "sound/npc/shamblie/foot1.wav" )
	resource.AddFile( "sound/npc/shamblie/foot2.wav" )
	resource.AddFile( "sound/npc/shamblie/foot3.wav" )
	resource.AddFile( "sound/npc/shamblie/foot_slide1.wav" )
	resource.AddFile( "sound/npc/shamblie/foot_slide2.wav" )
	resource.AddFile( "sound/npc/shamblie/foot_slide3.wav" )
	resource.AddFile( "sound/npc/shamblie/Growl_0.wav" )
	resource.AddFile( "sound/npc/shamblie/Growl_1.wav" )
	resource.AddFile( "sound/npc/shamblie/Growl_2.wav" )
	resource.AddFile( "sound/npc/shamblie/growl_3.wav" )
	resource.AddFile( "sound/npc/shamblie/Growl_4.wav" )
	resource.AddFile( "sound/npc/shamblie/Growl_5.wav" )
	resource.AddFile( "sound/npc/shamblie/Growl_6.wav" )
	resource.AddFile( "sound/npc/shamblie/Growl_7.wav" )
	resource.AddFile( "sound/npc/shamblie/Growl_8.wav" )
	resource.AddFile( "sound/npc/shamblie/Hit_0.wav" )
	resource.AddFile( "sound/npc/shamblie/Hit_1.wav" )
	resource.AddFile( "sound/npc/shamblie/Hit_2.wav" )
	resource.AddFile( "sound/npc/shamblie/Hit_3.wav" )
	resource.AddFile( "sound/npc/shamblie/Hit_4.wav" )
	resource.AddFile( "sound/npc/shamblie/hit_5.wav" )
	resource.AddFile( "sound/npc/shamblie/Hit_6.wav" )
	resource.AddFile( "sound/npc/shamblie/Hit_7.wav" )
	resource.AddFile( "sound/npc/shamblie/moan_loop1.wav" )
	resource.AddFile( "sound/npc/shamblie/moan_loop2.wav" )
	resource.AddFile( "sound/npc/shamblie/moan_loop3.wav" )
	resource.AddFile( "sound/npc/shamblie/moan_loop4.wav" )
	resource.AddFile( "sound/npc/shamblie/zombie_alert1.wav" )
	resource.AddFile( "sound/npc/shamblie/zombie_alert2.wav" )
	resource.AddFile( "sound/npc/shamblie/zombie_alert3.wav" )
	resource.AddFile( "sound/npc/shamblie/zombie_die1.wav" )
	resource.AddFile( "sound/npc/shamblie/zombie_die2.wav" )
	resource.AddFile( "sound/npc/shamblie/zombie_die3.wav" )
	resource.AddFile( "sound/npc/shamblie/zombie_hit.wav" )
	resource.AddFile( "sound/npc/shamblie/zombie_pound_door.wav" )
	resource.AddFile( "sound/npc/shamblie/zo_attack1.wav" )
	resource.AddFile( "sound/npc/shamblie/zo_attack2.wav" )
	
	resource.AddFile( "sound/powers/explosion_3.wav" )
	resource.AddFile( "sound/powers/explosion_3_boom.wav" )
	
	resource.AddFile( "sound/weapons/1molotov/mtov_break1.wav" )
	resource.AddFile( "sound/weapons/1molotov/mtov_break2.wav" )
	resource.AddFile( "sound/weapons/1molotov/mtov_flame1.wav" )
	resource.AddFile( "sound/weapons/1molotov/mtov_flame2.wav" )
	resource.AddFile( "sound/weapons/1molotov/mtov_flame3.wav" )
	resource.AddFile( "sound/weapons/fists_zm/swing1.wav" )
	resource.AddFile( "sound/weapons/flashlight_zm/flashlight_swing.wav" )
	resource.AddFile( "sound/weapons/flashlight_zm/flashlight_swinghit.wav" )
	resource.AddFile( "sound/weapons/pistol_zm/pistol_zm_empty.wav" )
	resource.AddFile( "sound/weapons/pistol_zm/pistol_zm_fire1.wav" )
	resource.AddFile( "sound/weapons/pistol_zm/pistol_zm_fire1_dist.wav" )
	resource.AddFile( "sound/weapons/pistol_zm/pistol_zm_fire2.wav" )
	resource.AddFile( "sound/weapons/pistol_zm/pistol_zm_fire2_dist.wav" )
	resource.AddFile( "sound/weapons/pistol_zm/pistol_zm_reload1.wav" )
	resource.AddFile( "sound/weapons/revolver_zm/revolver_fire.wav" )
	resource.AddFile( "sound/weapons/revolver_zm/revolver_reload.wav" )
	resource.AddFile( "sound/weapons/rifle_zm/zm_rifle_empty.wav" )
	resource.AddFile( "sound/weapons/rifle_zm/zm_rifle_fire1.wav" )
	resource.AddFile( "sound/weapons/rifle_zm/zm_rifle_fire2.wav" )
	resource.AddFile( "sound/weapons/rifle_zm/zm_rifle_lever.wav" )
	resource.AddFile( "sound/weapons/rifle_zm/zm_rifle_reload1.wav" )
	resource.AddFile( "sound/weapons/rifle_zm/zm_rifle_reload2.wav" )
	resource.AddFile( "sound/weapons/shotgun_zm/shotgun_cock_zm.wav" )
	resource.AddFile( "sound/weapons/shotgun_zm/shotgun_dbl_fire.wav" )
	resource.AddFile( "sound/weapons/shotgun_zm/shotgun_dbl_fire7_zm.wav" )
	resource.AddFile( "sound/weapons/shotgun_zm/shotgun_dbl_fire7_zm_dist.wav" )
	resource.AddFile( "sound/weapons/shotgun_zm/shotgun_empty_zm.wav" )
	resource.AddFile( "sound/weapons/shotgun_zm/shotgun_fire6_zm.wav" )
	resource.AddFile( "sound/weapons/shotgun_zm/shotgun_fire7_zm.wav" )
	resource.AddFile( "sound/weapons/shotgun_zm/shotgun_fire7_zm_dist.wav" )
	resource.AddFile( "sound/weapons/shotgun_zm/shotgun_fire7_zm_dist2.wav" )
	resource.AddFile( "sound/weapons/shotgun_zm/shotgun_reload1_zm.wav" )
	resource.AddFile( "sound/weapons/shotgun_zm/shotgun_reload2_zm.wav" )
	resource.AddFile( "sound/weapons/shotgun_zm/shotgun_reload3_zm.wav" )
	resource.AddFile( "sound/weapons/sledge_zm/sledge_swing.wav" )
	resource.AddFile( "sound/weapons/sledge_zm/sledge_swingalt.wav" )
	resource.AddFile( "sound/weapons/smg_zm/smg_fire.wav" )
	resource.AddFile( "sound/weapons/smg_zm/smg_fire_distancefade.wav" )
	resource.AddFile( "sound/weapons/smg_zm/smg_reload1.wav" )
	resource.AddFile( "sound/weapons/smg_zm/smg_reload2.wav" )
	resource.AddFile( "sound/weapons/smg_zm/smg_reload3.wav" )
end