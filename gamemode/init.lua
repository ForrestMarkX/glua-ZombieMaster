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
AddCSLuaFile("vgui/dzombiepanel.lua")
AddCSLuaFile("vgui/dpowerpanel.lua")

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

function GM:InitPostEntity()
	RunConsoleCommand("mapcyclefile", "mapcycle_zombiemaster.txt")
	
	self:SetRoundStartTime(5)
	self:SetRoundStart(true)
	self:SetRoundActive(false)
end

function GM:InitPostEntityMap()
	self:SetupAmmo()
	self:SetupSpawnPoints()
	
	for _, ent in pairs(ents.FindByClass("prop_physics")) do
		self:ConvertEntTo(ent, "prop_physics_multiplayer")
	end
	
	for _, ent in pairs(ents.FindByClass("func_physbox")) do
		self:ConvertEntTo(ent, "func_physbox_multiplayer")
	end
end

function GM:EntityFireBullets(ent, data)
	data.Callback = function(attacker, tr, dmginfo)
		if tr.Hit then
			local entity = tr.Entity
			if IsValid(entity) and entity:IsNPC() and dmginfo:GetDamage() >= entity:Health() then
				entity:SetBulletForce(dmginfo:GetDamageForce(), tr.PhysicsBone)
			end
		end
	end
	
	return true
end

function GM:SetupAmmo()
	local ammotbl = ents.FindByClass("item_ammo_*")
	table.Add(ammotbl, ents.FindByClass("item_box_*"))
	
	for _, ammo in pairs(ammotbl) do
		if ammo:GetClass() == "item_ammo_revolver" then continue end
		
		local ammotype = self.AmmoClass[ammo:GetClass()]
		if ammotype then
			local ent = ents.Create("item_zm_ammo")
			if IsValid(ent) then
				ent:SetPos(ammo:GetPos())
				ent:SetAngles(ammo:GetAngles())
				
				ent.ClassName = ammo:GetClass()
				ent.Model = ammo:GetModel()
				ent.AmmoAmount = self.AmmoCache[ammotype]
				ent.AmmoType = ammotype
				ent:Spawn()
				
				self.AmmoModels[ammo:GetClass()] = ammo:GetModel()
				
				ammo:Remove()
			end
		end
	end
end

function GM:SetupSpawnPoints()
	local z_spawn = ents.FindByClass( "info_player_zombiemaster" )
	local h_spawn = ents.FindByClass( "info_player_deathmatch" )
	
	team.SetSpawnPoint( TEAM_SURVIVOR, z_spawn )
	team.SetSpawnPoint( TEAM_ZOMBIEMASTER, h_spawn )
end

function GM:OnEntityCreated(ent)
	if ent:IsNPC() then
		if string.sub(ent:GetClass(), 1, 12) == "npc_headcrab" then
			ent:Remove() 
			return
		end
		
		local entname = string.lower(ent:GetClass())
	
		timer.Simple(0, function()
			if not IsValid(ent) then return end
			
			if ent.GetNumBodyGroups and ent.SetBodyGroup then
				for k = 0, ent:GetNumBodyGroups() - 1 do
					ent:SetBodyGroup(k, 0)
				end
			end
			
			gamemode.Call("SetupNPCZombieModels", ent)
			ent:SetShouldServerRagdoll(false)
		end)
		
		--AddRelationship does not work for some reason but AddEntityRelationship does
		if string.lower(entname) == "npc_zombie" or string.lower(entname) == "npc_poisonzombie" or string.lower(entname) == "npc_fastzombie" then
			local zombies = ents.FindByClass("npc_burnzombie")
			table.Add(zombies, ents.FindByClass("npc_dragzombie"))
			
			for _, zom in pairs(zombies) do
				ent:AddEntityRelationship(zom, D_LI, 99)
			end
		else
			local zombies = ents.FindByClass("npc_zombie")
			table.Add(zombies, ents.FindByClass("npc_fastzombie"))
			table.Add(zombies, ents.FindByClass("npc_poisonzombie"))
			
			for _, zom in pairs(zombies) do
				zom:AddEntityRelationship(ent, D_LI, 99)
			end	
		end
	end
end

function GM:PlayerSpawnAsSpectator(pl)
	pl:StripWeapons()
	pl:ChangeTeam(TEAM_SPECTATOR)
	pl:Spectate(OBS_MODE_ROAMING)
	pl:SetNoTarget(true)
	pl:SetMoveType(MOVETYPE_NOCLIP)
	pl:SendLua("RunConsoleCommand('-left')")
	pl:SendLua("RunConsoleCommand('-right')")
	
	pl:Extinguish()
	
	pl:SetHull(Vector(-0.1, -0.1, 0), Vector(0.1, 0.1, 18.1))
	pl:SetHullDuck(Vector(-0.1, -0.1, 0), Vector(0.1, 0.1, 18.1))
end

function GM:PlayerDeathThink(pl)
	return false
end

function GM:CanPlayerSuicide(ply)
	if ply:IsZM() and not self:GetRoundEnd() then	
		gamemode.Call("TeamVictorious", true, "The Zombie Master has submitted.\n")
	end
	
	return ply:IsSurvivor()
end

function GM:PlayerInitialSpawn(pl)
	pl:SetTeam(TEAM_UNASSIGNED)
	pl:StripWeapons()
	pl:Spectate(OBS_MODE_ROAMING)
	pl:SetNoTarget(true)
	pl:SetMoveType(MOVETYPE_NOCLIP)
	
	if self:GetRoundActive() and team.NumPlayers(TEAM_SURVIVOR) == 0 and not NotifiedRestart then
		PrintMessage(HUD_PRINTTALK, "The round is restarting...\n" )
		timer.Simple(2, function() gamemode.Call("PreRestartRound") end)
		timer.Simple(5, function() gamemode.Call("RestartRound") end)
		NotifiedRestart = true
	end
	
	pl.NextPainSound = 0
	pl.IsReady = false
	
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
	if ply:IsSpectator() or ply:Team() == TEAM_UNASSIGNED then
		gamemode.Call("PlayerSpawnAsSpectator", ply)
		return
	end
	
	if ply:IsSurvivor() then
		ply:StripWeapons()
		ply:SetColor(color_white)

		if ply:GetMaterial() ~= "" then
			ply:SetMaterial("")
		end
		
		ply:ShouldDropWeapon(true)
		
		ply:SetMaxHealth(100, true)  
		gamemode.Call("SetPlayerSpeed", ply, 190, 190)
		
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
	
	hook.Call("PlayerLoadout", GAMEMODE, ply)
end

function GM:IncreaseResources(pZM)
	if not IsValid(pZM) then return end
	
	local players = #team.GetPlayers(TEAM_SURVIVOR)
	local resources = pZM:GetZMPoints()
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

function GM:PlayerNoClip(ply, desiredState)
	return ply:IsSuperAdmin() or ply:IsZM() or ply:IsSpectator()
end

function GM:OnNPCKilled(ent, attacker, inflictor)
	local class = ent:GetClass()
	if class == "npc_zombie" or class == "npc_fastzombie" or class == "npc_poisonzombie" then
		local owner = ent:GetOwner()
		if IsValid(owner) and owner:IsPlayer() then
			local popCost = self:GetPopulationCost(class)
			local population = self:GetCurZombiePop()

			popCost = popCost or 1

			self:SetCurZombiePop(population - popCost)
		end
		
		net.Start("zm_spawnclientragdoll")
			net.WriteEntity(ent)
		net.Broadcast()
	end
	
	return true
end

function GM:PlayerDeath(ply, inflictor, attacker)
	if attacker:IsNPC() then
		local attackername = ""
		
		local pZM = self:FindZM()
		if IsValid(pZM) then
			pZM:AddFrags(1)
		end
		
		for _, zombie in pairs(self:GetZombieTable()) do
			if zombie.class == attacker:GetClass() then
				attackername = zombie.name
				break
			end
		end
		
		net.Start("PlayerKilledByNPC")
			net.WriteEntity(ply)
			net.WriteString(inflictor:GetClass())
			net.WriteString(attackername)
		net.Broadcast()
		
		MsgAll(ply:Nick() .. " was killed by " .. attackername .. "\n")
		
		return
	end
	
	self.BaseClass.PlayerDeath(self, ply, inflictor, attacker)
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
	
	timer.Simple(0.1, function() 
		gamemode.Call("PlayerSpawnAsSpectator", ply)
		
		if not self:GetRoundEnd() and self:GetRoundActive() then
			if team.NumPlayers(TEAM_SURVIVOR) == 0 then
				gamemode.Call("TeamVictorious", false, "Undeath has prevailed!\n")
			end
		end
	end)
end

function GM:PostPlayerDeath(ply)
	ply:Spectate(OBS_MODE_ROAMING)
end

function GM:PlayerHurt(victim, attacker, healthremaining, damage)
	if 0 < healthremaining then
		if victim:IsSurvivor() then
			victim:PlayPainSound()
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

function GM:PostCleanupMap()
	self:SetupAmmo()
end

function GM:DoRestartGame()
	game.CleanUpMap(false)
	hook.Call("InitPostEntityMap", self)
	
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

function GM:OnPlayerChangedTeam(ply, oldTeam, newTeam)
	if newTeam == TEAM_SPECTATOR then
		ply:SetPos(ply:EyePos())
	elseif newTeam == TEAM_ZOMBIEMASTER then
		timer.Simple(0.1, function() ply:SendLua("GAMEMODE:CreateVGUI()") end)
	end
	
	if newteam ~= TEAM_SURVIVOR then
		ply:Spectate(OBS_MODE_ROAMING)
		ply:SetMoveType(MOVETYPE_NOCLIP)
		ply:GodEnable()
	else
		ply:SetMoveType(MOVETYPE_WALK)
		ply:GodDisable()
	end
end

-- You can override or hook and return false in case you have your own map change system.
local function RealMap(map)
	return string_match(map, "(.+)%.bsp")
end
function GM:LoadNextMap()
	-- Just in case.
	timer.Simple(5, game.LoadNextMap)
	timer.Simple(10, function() RunConsoleCommand("changelevel", game.GetMap()) end)

	if file.Exists(GetConVarString("mapcyclefile"), "GAME") then
		game.LoadNextMap()
	else
		local maps = file.Find("maps/zm_*.bsp", "GAME")
		table_sort(maps)
		if #maps > 0 then
			local currentmap = game.GetMap()
			for i, map in ipairs(maps) do
				local lowermap = string_lower(map)
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
		timer.Simple(2, function() game.SetTimeScale(1) end)
	end
	
	local rounds = GetConVar("zm_roundlimit"):GetInt()
	if self.RoundsPlayed > rounds then
		timer.Simple(3, function() hook.Call("LoadNextMap", self) end)
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
	
	ply:SetCustomCollisionCheck(true)
	ply:SetAvoidPlayers(true)
	ply:UnSpectate()
	ply:Spawn()
	
	ply:SprintDisable()
	if ply:KeyDown(IN_WALK) then
		ply:ConCommand("-walk")
	end
		
	ply:ResetHull()
	ply:SetCanWalk(false)
	ply:SetCanZoom(false)
	ply:AllowFlashlight(true)
	
	if GetConVar("zm_nocollideplayers"):GetBool() then
		ply:SetAvoidPlayers(false)
		ply:SetNoCollideWithTeammates(true)
	end
end

function GM:PlayerReady(pl)
	gamemode.Call("PlayerReadyRound", pl)
end

function GM:PlayerReadyRound(pl)
	if not pl:IsValid() then return end
	table.RemoveByValue(self.UnReadyPlayers, pl)
	
	pl:SendLua("GAMEMODE:MakePreferredMenu()")
	
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

function GM:ConvertEntTo(prop, convertto)
	if convertto == "" or convertto == nil then return end
	if not IsValid(prop:GetPhysicsObject()) then return end
	
	local ent = ents.Create(convertto)
	if IsValid(ent) then
		ent:SetName(prop:GetName())
		ent:SetPos(prop:GetPos())
		ent:SetAngles(prop:GetAngles())
		ent:SetModel(prop:GetModel())
		ent:SetMaterial(prop:GetMaterial())
		ent:SetSkin(prop:GetSkin() or 0)
		ent:SetBodyGroups(prop:GetBodyGroups())
		ent:SetCollisionGroup(prop:GetCollisionGroup())
		ent:SetModelScale(prop:GetModelScale() or 1)
		ent:SetParent(prop:GetParent())
		ent:SetOwner(prop:GetOwner())
		ent:SetSolid(prop:GetSolid())
		ent:SetMoveType(prop:GetMoveType())
		ent:SetRenderFX(prop:GetRenderFX())
		ent:SetGravity(prop:GetGravity())
		ent:SetMoveCollide(prop:GetMoveCollide())
		ent:SetNoDraw(prop:GetNoDraw())
		ent:SetNotSolid(prop:IsSolid())
		ent:SetRenderMode(prop:GetRenderMode())
		ent:SetSolidFlags(prop:GetSolidFlags())
		ent:SetSpawnEffect(prop:GetSpawnEffect())
		ent:SetCollisionBounds(prop:GetCollisionBounds())
		ent:SetColor(prop:GetColor())
		ent:SetCustomCollisionCheck(prop:GetCustomCollisionCheck())
		ent:SetFriction(prop:GetFriction())
		ent:SetGroundEntity(prop:GetGroundEntity())
		ent:SetTransmitWithParent(prop:GetTransmitWithParent())
		
		for index, mat in pairs(prop:GetMaterials()) do
			ent:SetSubMaterial(index - 1, mat)
		end
		
		if prop:Health() > 0 then
			ent:SetHealth(prop:Health())
		end
		
		for key, value in pairs(prop:GetKeyValues()) do
			ent:SetKeyValue(key, value)
		end
		
		ent:Spawn()
		ent:Activate()
		
		local phys = prop:GetPhysicsObject()
		if IsValid(phys) then
			local phys2 = ent:GetPhysicsObject()
			if IsValid(phys2) then
				phys2:SetMass(phys:GetMass())
				phys2:SetMaterial(phys:GetMaterial())
				
				if phys:IsMotionEnabled() then
					phys2:Wake()
				else
					phys2:EnableMotion(false)
				end
			end
		end
		
		if string.find(prop:GetClass(), "func_physbox") then
			if not IsValid(ent:GetPhysicsObject()) then
				ent:PhysicsInitBox(prop:OBBMins(), prop:OBBMaxs())
			end
		end
		
		ent:SetTable(prop:GetTable())
		
		prop:Remove()
	end
end

function GM:EntityTakeDamage(ent, dmginfo)
	local attacker, inflictor = dmginfo:GetAttacker(), dmginfo:GetInflictor()
	local damage = dmginfo:GetDamage()
	
	if ent:IsPlayerHolding() and damage > 10 then
		DropEntityIfHeld(ent)
	end
	
	if ent:IsNPC() then
		if ent:Health() <= damage then
			dmginfo:SetDamageType(DMG_REMOVENORAGDOLL)
		end
		
		local atkowner = attacker.OwnerClass
		if IsValid(attacker) and attacker:GetClass() == "env_fire" and atkowner and atkowner == "npc_burnzombie" then
			dmginfo:SetDamageType(DMG_GENERIC)
			dmginfo:SetDamage(0)
			dmginfo:ScaleDamage(0)
			return
		end
	end
	
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
function GM:PlayerPostThink(pl)
	if income_time ~= 0 and income_time <= CurTime() then
		if pl:IsZM() then
			pl:AddZMPoints(pl:GetZMPointIncome())
			income_time = CurTime() + GetConVar("zm_incometime"):GetInt()
		end
	end
	
	if pl:IsSpectator() then
		if pl:GetObserverMode() == OBS_MODE_ROAMING then 
			if pl:KeyPressed(IN_ATTACK) then
				pl.SpectatedPlayerKey = (pl.SpectatedPlayerKey or 0) + 1
				local players = {}

				for k, v in pairs(team.GetPlayers(TEAM_SURVIVOR)) do
					if v:Alive() and v ~= pl then
						table.insert(players, v)
					end
				end
				
				if pl.SpectatedPlayerKey > #players then
					pl.SpectatedPlayerKey = 0
					return
				end

				pl:StripWeapons()
				local specplayer = players[pl.SpectatedPlayerKey]

				if specplayer then
					pl:SetPos(specplayer:GetPos())
				end
			elseif pl:KeyPressed(IN_ATTACK2) then
				pl.SpectatedPlayerKey = (pl.SpectatedPlayerKey or 0) - 1

				local players = {}

				for k, v in pairs(team.GetPlayers(TEAM_SURVIVOR)) do
					if v:Alive() and v ~= pl then
						table.insert(players, v)
					end
				end
				
				if pl.SpectatedPlayerKey < 0 then
					pl.SpectatedPlayerKey = #players
					return
				end

				pl:StripWeapons()
				local specplayer = players[pl.SpectatedPlayerKey]

				if specplayer then
					pl:SetPos(specplayer:GetPos())
				end
			end
		end
	elseif pl:IsZM() then
		if pl:KeyPressed(IN_RELOAD) then
			pl.SpectatedPlayerKey = (pl.SpectatedPlayerKey or 0) + 1
			local players = {}

			for k, v in pairs(team.GetPlayers(TEAM_SURVIVOR)) do
				if v:Alive() and v ~= pl then
					table.insert(players, v)
				end
			end
			
			if pl.SpectatedPlayerKey > #players then
				pl.SpectatedPlayerKey = 0
				return
			end

			pl:StripWeapons()
			local specplayer = players[pl.SpectatedPlayerKey]

			if specplayer then
				pl:SetPos(specplayer:GetPos())
			end
		elseif pl:KeyPressed(IN_USE) then
			pl.SpectatedPlayerKey = (pl.SpectatedPlayerKey or 0) - 1

			local players = {}

			for k, v in pairs(team.GetPlayers(TEAM_SURVIVOR)) do
				if v:Alive() and v ~= pl then
					table.insert(players, v)
				end
			end
			
			if pl.SpectatedPlayerKey < 0 then
				pl.SpectatedPlayerKey = #players
				return
			end

			pl:StripWeapons()
			local specplayer = players[pl.SpectatedPlayerKey]

			if specplayer then
				pl:SetPos(specplayer:GetPos())
			end
		end
	end
end

function GM:PlayerLoadout(ply)
	if ply:IsSurvivor() then ply:Give("weapon_zm_fists") end
	return true
end

local NextTick = 0
function GM:Think()
	local time = CurTime()
	local players = player.GetAll()
	
	if #self.ConnectingPlayers > 0 and CurTime() >= self.ReadyTimer then
		table.Empty(self.ConnectingPlayers)
	end
	
	-- Originally from TTT
	local humans = team.GetPlayers(TEAM_SURVIVOR)
	for i= 1, #humans do
		local ply = humans[i]
        if ply:WaterLevel() == 3 then
			if ply:IsOnFire() then
				ply:Extinguish()
			end

            if ply.drowning then
				if ply.drowning < CurTime() then
					local dmginfo = DamageInfo()
					dmginfo:SetDamage(15)
					dmginfo:SetDamageType(DMG_DROWN)
					dmginfo:SetAttacker(game.GetWorld())

					ply:TakeDamageInfo(dmginfo)

					ply.drowning = CurTime() + 1
				end
            else
				ply.drowning = CurTime() + 30
            end
         else
			ply.drowning = nil
         end
	end
	
	if #players > 0 then
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
		
		if #players > 20 then
			for _, ply in pairs(players) do
				ply:SetAvoidPlayers(false)
				if not ply:GetNoCollideWithTeammates() then 
					ply:SetNoCollideWithTeammates(true) 
				end
			end
		end
		
		for k, v in ipairs(ents.FindByClass("npc_*")) do
			if v:IsNPC() then
				if not IsValid(v:GetEnemy()) then
					local nearest_ply
					local dist = 0
					for i, j in ipairs(team.GetPlayers(TEAM_SURVIVOR)) do
						local dist2 = j:GetPos():Distance(v:GetPos())
						if dist2 < dist then
							dist = dist2
							nearest_ply = j
						end
					end
					v:SetEnemy(nearest_ply)
				end
			end
		end
	end
end

function GM:ShowHelp(pl)
	pl:SendLua("GAMEMODE:ShowHelp()")
end

function GM:ShowTeam(pl)
	pl:SendLua("GAMEMODE:ShowOptions()")
end

function GM:PlayerDisconnected(ply)
	if self:GetRoundActive() then
		if ply:IsZM() then
			gamemode.Call("TeamVictorious", true, "The Zombie Master has left!\n")
		elseif team.NumPlayers(TEAM_SURVIVOR) <= 0 then
			gamemode.Call("TeamVictorious", false, "All the humans have left!\n")
		end
	end
end

function GM:IsSpawnpointSuitable(pl, spawnpointent, bMakeSuitable)
	local Pos = spawnpointent:GetPos()
	local Ents = ents.FindInBox(Pos + Vector(-16, -16, 0), Pos + Vector(16, 16, 64))
	
	if pl:Team() == TEAM_SPECTATOR then return true end
	
	local Blockers = 0
	for k, v in pairs( Ents ) do
		if IsValid(v) and v ~= pl and v:GetClass() == "player" and v:Alive() then
			Blockers = Blockers + 1
		end
	end
	
	if bMakeSuitable then return true end
	if Blockers > 0 then return false end
	
	return true
end

function GM:ZombieMasterVolunteers()
	if not GetConVar("zm_debug_nozombiemaster"):GetBool() then
		if team.NumPlayers(TEAM_ZOMBIEMASTER) == 1 then return end
		
		local iHighest = -1
		local ZMList = {}
		for _, pl in pairs(player.GetAll()) do
			if IsValid(pl) and pl.m_iZMPriority and pl.m_iZMPriority > iHighest and pl:GetInfoNum("zm_preference", 0) == 1 then
				iHighest = pl.m_iZMPriority
			end
			
			if IsValid(pl) and pl.m_iZMPriority and pl.m_iZMPriority == iHighest and pl:GetInfoNum("zm_preference", 0) == 1 then
				table.insert(ZMList, pl)
			end
		end
		
		local pl = nil
		if #ZMList > 0 then
			pl = ZMList[math.random(#ZMList)]
		else
			local players = player.GetAll()
			pl = players[math.random(#players)]
		end
		
		if IsValid(pl) then
			pl:KillSilent()
			pl:SetFrags(0)
			pl:SetDeaths(0)
			pl:ChangeTeam(TEAM_ZOMBIEMASTER)
			pl:Spectate(OBS_MODE_ROAMING)
			pl:SetMoveType(MOVETYPE_NOCLIP)
			
			pl.m_iZMPriority = 0
			
			PrintMessage(HUD_PRINTTALK, pl:Name().." has become the Zombie Master")
			util.PrintMessageC(pl, "To move around as the ZM hold down shift or your +speed key and or if you need help press F1 >> Help.", Color(255, 0, 0))
			
			pl:SetZMPoints(425)
			pl:SetZMPointIncome(GetConVar("zm_maxresource_increase"):GetInt())
			gamemode.Call("IncreaseResources", pl)
			
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
	
	for _, ply in pairs(player.GetAll()) do
		if IsValid(ply) then
			if ply:IsSpectator() then continue end
			ply.m_iZMPriority = (ply.m_iZMPriority or 0) + 10
		end
	end
	
	game.CleanUpMap(false)
	hook.Call("InitPostEntityMap", self)
	
	for _, ply in pairs(team.GetPlayers(TEAM_SPECTATOR)) do
		gamemode.Call("InitialSpawnRound", ply)
	end
end

function GM:AllowPlayerPickup(pl, ent)
	if ent:IsPlayerHolding() then return false end
	
	local entclass = ent:GetClass()
	if string.sub(entclass, 1, 12) == "prop_physics" or string.sub(entclass, 1, 12) == "func_physbox" or entclass == "item_zmmo_zm" or string.sub(entclass, 1 , 10) == "weapon_zm_" and pl:IsSurvivor() and pl:Alive() and ent:GetMoveType() == MOVETYPE_VPHYSICS and ent:GetPhysicsObject():IsValid() and ent:GetPhysicsObject():GetMass() <= CARRY_MASS and ent:GetPhysicsObject():IsMoveable() and ent:OBBMins():Length() + ent:OBBMaxs():Length() <= CARRY_VOLUME then
		return true
	end
	
	return pl:IsSurvivor()
end

function GM:PlayerCanHearPlayersVoice(listener, talker)
	return true, false
end

function GM:KeyPress(pl, key)
    if key == IN_USE then
        if pl:IsSurvivor() and pl:Alive() then
			local tr = util.TraceLine({
				start = pl:EyePos(),
				endpos = pl:EyePos() + pl:EyeAngles():Forward() * 64,
				filter = player.GetAll()
			})
			local ent = tr.Entity

			gamemode.Call("PlayerUse", pl, ent)
        end
	end
end

function GM:PlayerUse(pl, ent)
	if not IsValid(ent) then return false end
	if not pl:Alive() or pl:IsZM() or pl:IsSpectator() then return false end
	if ent:IsPlayerHolding() then return false end

	local entclass = ent:GetClass()
	if entclass == "prop_door_rotating" then
		if CurTime() < (ent.m_AntiDoorSpam or 0) then
			return false
		end
		ent.m_AntiDoorSpam = CurTime() + 0.85
	elseif pl:IsSurvivor() then
		if string.sub(entclass, 1 , 12) == "prop_physics" or string.sub(entclass, 1 , 12) == "func_physbox" then
			if gamemode.Call("AllowPlayerPickup", pl, ent) and not ent:IsPlayerHolding() then
				pl:DropObject()
				
				local phys = ent:GetPhysicsObject()
				if IsValid(phys) then
					if phys:IsMotionEnabled() then
						pl:PickupObject(ent)
					end
				end
			end
		end
	end

	return true
end

function GM:PlayerSwitchFlashlight(pl, newstate)
	return pl:IsSurvivor()
end

function GM:PlayerCanPickupWeapon(pl, ent)
	if pl.DelayPickup and pl.DelayPickup > CurTime() then 
		pl.DelayPickup = 0
		return false 
	end
	
	if pl:IsSurvivor() and pl:Alive() then
		if ent.ThrowTime and ent.ThrowTime > CurTime() then return false end
		if pl:HasWeapon(ent:GetClass()) and ent.WeaponIsAmmo then return gamemode.Call("PlayerCanPickupItem", pl, ent) end
		
		if pl:HasWeapon(ent:GetClass()) then return false end
		
		local weps = pl:GetWeapons()
		for index, wep in pairs(weps) do
			if wep:GetSlot() == ent:GetSlot() then
				return false
			end
		end
		
		if ent:CreatedByMap() or ent.Dropped then
			local class = ent:GetClass()
			
			pl:Give(class)
			
			local wep = pl:GetWeapon(class)
			if not wep.IsMelee and wep:GetClass() == class then
				wep:SetClip1(ent:Clip1())
				wep:SetClip2(ent:Clip2())
			end
			
			ent:Remove()
			return false
		end
		
		return true
	end
	
	pl.DelayPickup = CurTime() + 0.2
	
	return false
end

function GM:PlayerCanPickupItem(pl, item)
	if pl.DelayItemPickup and pl.DelayItemPickup > CurTime() then 
		pl.DelayItemPickup = 0
		return false 
	end
	
	if pl:Alive() and pl:IsSurvivor() and string.sub(item:GetClass(), 1, 10) == "item_ammo_" or item:GetClass() == "item_zm_ammo" or item:GetClass() == "weapon_zm_molotov" then
		if item.ThrowTime and item.ThrowTime > CurTime() then return false end
		
		for _, wep in pairs(pl:GetWeapons()) do
			local primaryammo = wep.Primary and wep.Primary.Ammo or ""
			local secondaryammo = wep.Secondary and wep.Secondary.Ammo or ""
			local ammotype = self.AmmoClass[item.ClassName] or ""
			
			if string.lower(primaryammo) == string.lower(ammotype) or string.lower(secondaryammo) == string.lower(ammotype) then
				local ammoid = game.GetAmmoID(ammotype)
				if pl:GetAmmoCount(ammotype) < game.GetAmmoMax(ammoid) then
					return true
				end
			end
		end
		
		return false
	end
	
	pl.DelayItemPickup = CurTime() + 0.2
	
	return pl:IsSurvivor()
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
		pZombie:SetKeyValue("spawnflags", bit.bor(SF_NPC_FADE_CORPSE, SF_NPC_ALWAYSTHINK))
		pZombie:SetKeyValue("crabcount", -1)
		
		pZombie:SetPos(origin)
		pZombie:SetOwner(pZM)
		
		local tr = util.TraceHull({
			start = origin,
			endpos = origin + -angles:Up() * 10000,
			mins = Vector(-12, -12, 0), 
			maxs = Vector(12, 12, 8),
			mask = MASK_NPCSOLID
		})
		if tr.Hit and tr.HitWorld and not tr.HitSky then
			pZombie:SetPos(tr.HitPos + Vector(0, 0, 12))
		end
		
		angles.x = 0.0
		angles.z = 0.0
		pZombie:SetAngles(angles)
	
		gamemode.Call("SetupNPCZombieModels", pZombie)

		pZombie:Spawn()
		pZombie:Activate()
		pZombie:Fire("SetBodyGroup", 0)
		
		pZombie:CapabilitiesAdd(bit.bor(CAP_FRIENDLY_DMG_IMMUNE, CAP_SQUAD, CAP_OPEN_DOORS, CAP_AUTO_DOORS))
		pZombie:SetBloodColor(BLOOD_COLOR_RED)
		
		if pZombie.GetNumBodyGroups and pZombie.SetBodyGroup then
			for k = 0, pZombie:GetNumBodyGroups() - 1 do
				pZombie:SetBodyGroup(k, 0)
			end
		end
		
		pZombie:SetKeyValue("m_fIsHeadless", "1")
		
		pZM:TakeZMPoints(cost)
		GAMEMODE:SetCurZombiePop(GAMEMODE:GetCurZombiePop() + popcost)

		return pZombie
	end
	
	return NULL
end

function GM:AddResources()
	resource.AddFile( "materials/background01.vtf" )
	resource.AddFile( "materials/bboard/zm_bboard_batt.vtf" )
	resource.AddFile( "materials/bboard/zm_bboard_btyre.vtf" )
	resource.AddFile( "materials/bboard/zm_bboard_fcan1.vtf" )
	resource.AddFile( "materials/bboard/zm_bboard_fcan2.vtf" )
	resource.AddFile( "materials/bboard/zm_bboard_ftyre.vtf" )
	resource.AddFile( "materials/bboard/zm_bboard_items.vtf" )
	resource.AddFile( "materials/containers/metalcrate001a.vtf" )
	resource.AddFile( "materials/containers/metalcrate001b.vtf" )
	resource.AddFile( "materials/containers/metalcrate001c.vtf" )
	resource.AddFile( "materials/containers/metalcrate001d.vtf" )
	resource.AddFile( "materials/containers/metalcrate002a.vtf" )
	resource.AddFile( "materials/containers/metalcrate002b.vtf" )
	resource.AddFile( "materials/containers/metalcrate002c.vtf" )
	resource.AddFile( "materials/containers/metalcrate002d.vtf" )
	resource.AddFile( "materials/containers/metalcrate004d.vtf" )
	resource.AddFile( "materials/containers/metalcrate005a.vtf" )
	resource.AddFile( "materials/containers/metalcrate006a.vtf" )
	resource.AddFile( "materials/containers/metalcrate007a.vtf" )
	resource.AddFile( "materials/containers/metalcrate008a.vtf" )
	resource.AddFile( "materials/containers/metalcrate009a.vtf" )
	resource.AddFile( "materials/containers/metalcrate010a.vtf" )
	resource.AddFile( "materials/containers/picrate_512_clean.vtf" )
	resource.AddFile( "materials/containers/picrate_512_het.vtf" )
	resource.AddFile( "materials/containers/picrate_long.vtf" )
	resource.AddFile( "materials/containers/picrate_long_clean.vtf" )
	resource.AddFile( "materials/containers/picrate_long_mil.vtf" )
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
	resource.AddFile( "materials/decals/omh_1.vtf" )
	resource.AddFile( "materials/decals/omh_2.vtf" )
	resource.AddFile( "materials/effects/strider_bulge_dudv.vtf" )
	resource.AddFile( "materials/effects/strider_bulge_normal.vtf" )
	resource.AddFile( "materials/effects/zm_arrows.vtf" )
	resource.AddFile( "materials/effects/zm_healthring.vtf" )
	resource.AddFile( "materials/effects/zm_nightvis.vtf" )
	resource.AddFile( "materials/effects/zm_ring.vtf" )
	resource.AddFile( "materials/effects/zombie_selection.vtf" )
	resource.AddFile( "materials/effects/zombie_selection_alt.vtf" )
	resource.AddFile( "materials/lawyer/cratewall_1.vtf" )
	resource.AddFile( "materials/lawyer/cratewall_1_normal.vtf" )
	resource.AddFile( "materials/lawyer/cratewall_2.vtf" )
	resource.AddFile( "materials/lawyer/cratewall_2_normal.vtf" )
	resource.AddFile( "materials/lawyer/cratewall_3.vtf" )
	resource.AddFile( "materials/lawyer/cratewall_3_normal.vtf" )
	resource.AddFile( "materials/lawyer/cratewall_4.vtf" )
	resource.AddFile( "materials/lawyer/cratewall_4_normal.vtf" )
	resource.AddFile( "materials/lawyer/crate_lawyer.vtf" )
	resource.AddFile( "materials/lawyer/crate_lawyer_normal.vtf" )
	resource.AddFile( "materials/lawyer/crate_lawyer_top.vtf" )
	resource.AddFile( "materials/lawyer/crate_lawyer_top_normal.vtf" )
	resource.AddFile( "materials/lawyer/serverroomcarpet.vtf" )
	resource.AddFile( "materials/lawyer/serverroomcarpet_normal.vtf" )
	resource.AddFile( "materials/lawyer.vtf" )
	resource.AddFile( "materials/lostcoast/models/props_monastery/interior_dome_wall_window.vtf" )
	resource.AddFile( "materials/lostcoast/models/props_monastery/interior_dome_wall_window_normal.vtf" )
	resource.AddFile( "materials/lostcoast/models/props_monastery/monastery_stain_window001a.vtf" )
	resource.AddFile( "materials/lostcoast/models/props_monastery/monastery_stain_window001a_normal.vtf" )
	resource.AddFile( "materials/metal/citadel_metalwall077a_nospec.vtf" )
	resource.AddFile( "materials/metal/metalcrate001pi.vtf" )
	resource.AddFile( "materials/metal/metalfilecabinet002a.vtf" )
	resource.AddFile( "materials/metal/metalwall058a.vtf" )
	resource.AddFile( "materials/models/blue.vtf" )
	resource.AddFile( "materials/models/glow.vtf" )
	resource.AddFile( "materials/models/glow_orange.vtf" )
	resource.AddFile( "materials/models/gold.vtf" )
	resource.AddFile( "materials/models/humans/female/group02/fem_survivor1.vtf" )
	resource.AddFile( "materials/models/humans/female/group02/fem_survivor2.vtf" )
	resource.AddFile( "materials/models/humans/female/group02/fem_survivor3.vtf" )
	resource.AddFile( "materials/models/humans/female/group02/fem_survivor4.vtf" )
	resource.AddFile( "materials/models/humans/female/group02/fem_survivor6.vtf" )
	resource.AddFile( "materials/models/humans/female/group02/fem_survivor7.vtf" )
	resource.AddFile( "materials/models/humans/male/group02/citizen_sheet_pi.vtf" )
	resource.AddFile( "materials/models/humans/male/group02/citizen_sheet_pi_normal.vtf" )
	resource.AddFile( "materials/models/humans/male/group02/pi_facemap.vtf" )
	resource.AddFile( "materials/models/items/revolverammo.vtf" )
	resource.AddFile( "materials/models/largedoor_right.vtf" )
	resource.AddFile( "materials/models/null.vtf" )
	resource.AddFile( "materials/models/props/bell.vtf" )
	resource.AddFile( "materials/models/props/deathball_sheet.vtf" )
	resource.AddFile( "materials/models/props/metalceiling005a.vtf" )
	resource.AddFile( "materials/models/props/metalceiling005a_normal.vtf" )
	resource.AddFile( "materials/models/props/pew.vtf" )
	resource.AddFile( "materials/models/props_c17/frame002a_skin2.vtf" )
	resource.AddFile( "materials/models/props_c17/frame002a_skin3.vtf" )
	resource.AddFile( "materials/models/props_c17/frame002a_skin4.vtf" )
	resource.AddFile( "materials/models/props_c17/frame002a_skin5.vtf" )
	resource.AddFile( "materials/models/props_c17/frame002a_skin6.vtf" )
	resource.AddFile( "materials/models/props_c17/oil_drum001_splode.vtf" )
	resource.AddFile( "materials/models/props_interiors/sodamachine01a.vtf" )
	resource.AddFile( "materials/models/props_junk/garbage003a_01.vtf" )
	resource.AddFile( "materials/models/props_junk/popcan01a.vtf" )
	resource.AddFile( "materials/models/props_junk/popcan02a.vtf" )
	resource.AddFile( "materials/models/props_junk/popcan03a.vtf" )
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
	resource.AddFile( "materials/models/props_vehicles/apc001.vtf" )
	resource.AddFile( "materials/models/props_vehicles/apc_tire001.vtf" )
	resource.AddFile( "materials/models/red.vtf" )
	resource.AddFile( "materials/models/ship1/largedoor_left.vtf" )
	resource.AddFile( "materials/models/ship1/largedoor_right.vtf" )
	resource.AddFile( "materials/models/shotgun/casing01.vtf" )
	resource.AddFile( "materials/models/shotgun/shotgun_zm_diffuse.vtf" )
	resource.AddFile( "materials/models/shotgun/shotgun_zm_exp.vtf" )
	resource.AddFile( "materials/models/shotgun/shotgun_zm_normals.vtf" )
	resource.AddFile( "materials/models/shotgun/shotgun_zm_normals_env.vtf" )
	resource.AddFile( "materials/models/shotgun/v_hand_sheet.vtf" )
	resource.AddFile( "materials/models/shotgun/v_hand_sheet_normal.vtf" )
	resource.AddFile( "materials/models/silver.vtf" )
	resource.AddFile( "materials/models/weapons/flashlight_zm/flashlight3rd_diffuse.vtf" )
	resource.AddFile( "materials/models/weapons/flashlight_zm/flashlight_diffuse.vtf" )
	resource.AddFile( "materials/models/weapons/flashlight_zm/flashlight_normal.vtf" )
	resource.AddFile( "materials/models/weapons/hands_zm/v_hand_sheet_zm.vtf" )
	resource.AddFile( "materials/models/weapons/hands_zm/v_hand_sheet_zm_normal.vtf" )
	resource.AddFile( "materials/models/weapons/molotov_zm/fireoff.vtf" )
	resource.AddFile( "materials/models/weapons/molotov_zm/molotovfull_diffuse.vtf" )
	resource.AddFile( "materials/models/weapons/molotov_zm/molotovfull_normal.vtf" )
	resource.AddFile( "materials/models/weapons/molotov_zm/molotov_3rddiffuse.vtf" )
	resource.AddFile( "materials/models/weapons/molotov_zm/molotov_3rdnormalsmap.vtf" )
	resource.AddFile( "materials/models/weapons/pistol_zm/pistol3rd_diffuse.vtf" )
	resource.AddFile( "materials/models/weapons/pistol_zm/pistol3rd_normal.vtf" )
	resource.AddFile( "materials/models/weapons/pistol_zm/pistol_diffuse.vtf" )
	resource.AddFile( "materials/models/weapons/pistol_zm/pistol_normal.vtf" )
	resource.AddFile( "materials/models/weapons/rifle_zm/rifle_zm_3rd.vtf" )
	resource.AddFile( "materials/models/weapons/rifle_zm/rifle_zm_3rd_specular_mask.vtf" )
	resource.AddFile( "materials/models/weapons/rifle_zm/rifle_zm_cartridge.vtf" )
	resource.AddFile( "materials/models/weapons/rifle_zm/rifle_zm_diffuse.vtf" )
	resource.AddFile( "materials/models/weapons/rifle_zm/rifle_zm_normal.vtf" )
	resource.AddFile( "materials/models/weapons/shotgun_zm/shotgun4.vtf" )
	resource.AddFile( "materials/models/weapons/shotgun_zm/shotgun4diffuse.vtf" )
	resource.AddFile( "materials/models/weapons/sledgehammer_zm/sledgehammer_diffuse.vtf" )
	resource.AddFile( "materials/models/weapons/sledgehammer_zm/sledgehammer_normal.vtf" )
	resource.AddFile( "materials/models/weapons/sledgehammer_zm/sledge_sheet.vtf" )
	resource.AddFile( "materials/models/weapons/sledgehammer_zm/sledge_sheet_nrml.vtf" )
	resource.AddFile( "materials/models/weapons/v_mac_zm/mac10_sheet.vtf" )
	resource.AddFile( "materials/models/weapons/v_mac_zm/mac10_sheet_spec.vtf" )
	resource.AddFile( "materials/models/weapons/v_revolver_zm/v_revolver_sheet.vtf" )
	resource.AddFile( "materials/models/weapons/v_revolver_zm/v_revolver_sheet_nrml.vtf" )
	resource.AddFile( "materials/models/weapons/v_shotgun/remington_sheet.vtf" )
	resource.AddFile( "materials/models/weapons/v_shotgun/remington_sheet_spec.vtf" )
	resource.AddFile( "materials/models/weapons/v_slam/new lense.vtf" )
	resource.AddFile( "materials/models/weapons/v_slam/new light1.vtf" )
	resource.AddFile( "materials/models/weapons/v_slam/new light2.vtf" )
	resource.AddFile( "materials/models/weapons/v_slam/new slam.vtf" )
	resource.AddFile( "materials/models/weapons/v_slam/retexture trigger.vtf" )
	resource.AddFile( "materials/models/weapons/v_slam/v_slam.vtf" )
	resource.AddFile( "materials/models/weapons/v_slam/v_slam_normal.vtf" )
	resource.AddFile( "materials/models/weapons/v_smg/mac10_sheet.vtf" )
	resource.AddFile( "materials/models/weapons/v_smg/mac10_spec.vtf" )
	resource.AddFile( "materials/models/weapons/v_stunstick/v_stunstick_diffuse.vtf" )
	resource.AddFile( "materials/models/weapons/v_stunstick/v_stunstick_normal.vtf" )
	resource.AddFile( "materials/models/weapons/w_357/w_357.vtf" )
	resource.AddFile( "materials/models/weapons/w_357/w_357_spec.vtf" )
	resource.AddFile( "materials/models/weapons/w_shotgun_zm/w_shotgun_zm.vtf" )
	resource.AddFile( "materials/models/weapons/zm_pistol/pist_fiveseven.vtf" )
	resource.AddFile( "materials/models/weapons/zm_pistol/pist_fiveseven_ref.vtf" )
	resource.AddFile( "materials/models/zombie/zombie_classic/art_facemap.vtf" )
	resource.AddFile( "materials/models/zombie/zombie_classic/mike_facemap.vtf" )
	resource.AddFile( "materials/models/zombie/zombie_classic/test_facemap.vtf" )
	resource.AddFile( "materials/models/zombie/zombie_classic_humantest/eyeball_l.vtf" )
	resource.AddFile( "materials/models/zombie/zombie_classic_humantest/pupil_l.vtf" )
	resource.AddFile( "materials/models/zombie_classic/art_facemap.vtf" )
	resource.AddFile( "materials/models/zombie_classic/citizen_sheet.vtf" )
	resource.AddFile( "materials/models/zombie_classic/citizen_sheet2.vtf" )
	resource.AddFile( "materials/models/zombie_classic/citizen_sheet3.vtf" )
	resource.AddFile( "materials/models/zombie_classic/corpse1.vtf" )
	resource.AddFile( "materials/models/zombie_classic/erdim_cylmap.vtf" )
	resource.AddFile( "materials/models/zombie_classic/eric_facemap.vtf" )
	resource.AddFile( "materials/models/zombie_classic/eyeball_l.vtf" )
	resource.AddFile( "materials/models/zombie_classic/eyeball_r.vtf" )
	resource.AddFile( "materials/models/zombie_classic/joe_facemap.vtf" )
	resource.AddFile( "materials/models/zombie_classic/mike_facemap.vtf" )
	resource.AddFile( "materials/models/zombie_classic/pupil_l.vtf" )
	resource.AddFile( "materials/models/zombie_classic/pupil_r.vtf" )
	resource.AddFile( "materials/models/zombie_classic/sandro_facemap.vtf" )
	resource.AddFile( "materials/models/zombie_classic/ted_facemap.vtf" )
	resource.AddFile( "materials/models/zombie_classic/vance_facemap.vtf" )
	resource.AddFile( "materials/models/zombie_classic/van_facemap.vtf" )
	resource.AddFile( "materials/models/zombie_fast/corpse1.vtf" )
	resource.AddFile( "materials/postprocess/alpha.vtf" )
	resource.AddFile( "materials/props/bell.vtf" )
	resource.AddFile( "materials/props/deathball_sheet.vtf" )
	resource.AddFile( "materials/props/metalceiling005a.vtf" )
	resource.AddFile( "materials/props/metalceiling005a_normal.vtf" )
	resource.AddFile( "materials/props/metalfilecabinet002a.vtf" )
	resource.AddFile( "materials/props/metalladder001.vtf" )
	resource.AddFile( "materials/props/paperposter001a.vtf" )
	resource.AddFile( "materials/props/paperposter001b.vtf" )
	resource.AddFile( "materials/props/paperposter002a.vtf" )
	resource.AddFile( "materials/props/paperposter002b.vtf" )
	resource.AddFile( "materials/props/paperposter003a.vtf" )
	resource.AddFile( "materials/props/paperposter003b.vtf" )
	resource.AddFile( "materials/props/paperposter005a.vtf" )
	resource.AddFile( "materials/sign/redsign.vtf" )
	resource.AddFile( "materials/sign/whitesign.vtf" )
	resource.AddFile( "materials/sprites/fire_greyscale.vtf" )
	resource.AddFile( "materials/sprites/flamefromabove.vtf" )
	resource.AddFile( "materials/sprites/glow.vtf" )
	resource.AddFile( "materials/temp/5446d717.vtf" )
	resource.AddFile( "materials/temp/7e52e0ac.vtf" )
	resource.AddFile( "materials/temp/ada7c148.vtf" )
	resource.AddFile( "materials/temp/e4e75983.vtf" )
	resource.AddFile( "materials/truckpic/truckpic (14).vtf" )
	resource.AddFile( "materials/truckpic/truckpic.vtf" )
	resource.AddFile( "materials/vgui/gfx/vgui/hl2mp_logo.vtf" )
	resource.AddFile( "materials/vgui/gfx/vgui/not_available.vtf" )
	resource.AddFile( "materials/vgui/gfx/vgui/round_corner_ne.vtf" )
	resource.AddFile( "materials/vgui/gfx/vgui/round_corner_nw.vtf" )
	resource.AddFile( "materials/vgui/gfx/vgui/round_corner_se.vtf" )
	resource.AddFile( "materials/vgui/gfx/vgui/round_corner_sw.vtf" )
	resource.AddFile( "materials/vgui/gfx/vgui/solid_background.vtf" )
	resource.AddFile( "materials/vgui/gfx/vgui/spray_bullseye.vtf" )
	resource.AddFile( "materials/vgui/gfx/vgui/trans_background.vtf" )
	resource.AddFile( "materials/vgui/loading.vtf" )
	resource.AddFile( "materials/vgui/logos/back.vtf" )
	resource.AddFile( "materials/vgui/logos/brainfork.vtf" )
	resource.AddFile( "materials/vgui/logos/cross.vtf" )
	resource.AddFile( "materials/vgui/logos/decomposing.vtf" )
	resource.AddFile( "materials/vgui/logos/eat.vtf" )
	resource.AddFile( "materials/vgui/logos/no.vtf" )
	resource.AddFile( "materials/vgui/logos/pent.vtf" )
	resource.AddFile( "materials/vgui/logos/pressure.vtf" )
	resource.AddFile( "materials/vgui/logos/repent.vtf" )
	resource.AddFile( "materials/vgui/logos/rip.vtf" )
	resource.AddFile( "materials/vgui/logos/skull.vtf" )
	resource.AddFile( "materials/vgui/logos/spray_canned.vtf" )
	resource.AddFile( "materials/vgui/logos/spray_combine.vtf" )
	resource.AddFile( "materials/vgui/logos/spray_cop.vtf" )
	resource.AddFile( "materials/vgui/logos/spray_dog.vtf" )
	resource.AddFile( "materials/vgui/logos/spray_freeman.vtf" )
	resource.AddFile( "materials/vgui/logos/spray_head.vtf" )
	resource.AddFile( "materials/vgui/logos/spray_lambda.vtf" )
	resource.AddFile( "materials/vgui/logos/spray_plumbed.vtf" )
	resource.AddFile( "materials/vgui/logos/spray_soldier.vtf" )
	resource.AddFile( "materials/vgui/logos/walk.vtf" )
	resource.AddFile( "materials/vgui/miniarrows.vtf" )
	resource.AddFile( "materials/vgui/miniceiling.vtf" )
	resource.AddFile( "materials/vgui/minicrosshair.vtf" )
	resource.AddFile( "materials/vgui/minideletezombies.vtf" )
	resource.AddFile( "materials/vgui/minieye.vtf" )
	resource.AddFile( "materials/vgui/minifigures.vtf" )
	resource.AddFile( "materials/vgui/minigroupadd.vtf" )
	resource.AddFile( "materials/vgui/minigroupselect.vtf" )
	resource.AddFile( "materials/vgui/miniselectall.vtf" )
	resource.AddFile( "materials/vgui/minishield.vtf" )
	resource.AddFile( "materials/vgui/minishockwave.vtf" )
	resource.AddFile( "materials/vgui/miniskull.vtf" )
	resource.AddFile( "materials/vgui/minispotcreate.vtf" )
	resource.AddFile( "materials/vgui/playermodels/humans/group02/female_01.vtf" )
	resource.AddFile( "materials/vgui/playermodels/humans/group02/female_02.vtf" )
	resource.AddFile( "materials/vgui/playermodels/humans/group02/female_03.vtf" )
	resource.AddFile( "materials/vgui/playermodels/humans/group02/female_04.vtf" )
	resource.AddFile( "materials/vgui/playermodels/humans/group02/female_06.vtf" )
	resource.AddFile( "materials/vgui/playermodels/humans/group02/female_07.vtf" )
	resource.AddFile( "materials/vgui/playermodels/humans/group02/male_01.vtf" )
	resource.AddFile( "materials/vgui/playermodels/humans/group02/male_02.vtf" )
	resource.AddFile( "materials/vgui/playermodels/humans/group02/male_03.vtf" )
	resource.AddFile( "materials/vgui/playermodels/humans/group02/male_04.vtf" )
	resource.AddFile( "materials/vgui/playermodels/humans/group02/male_05.vtf" )
	resource.AddFile( "materials/vgui/playermodels/humans/group02/male_06.vtf" )
	resource.AddFile( "materials/vgui/playermodels/humans/group02/male_07.vtf" )
	resource.AddFile( "materials/vgui/playermodels/humans/group02/male_08.vtf" )
	resource.AddFile( "materials/vgui/playermodels/humans/group02/male_09.vtf" )
	resource.AddFile( "materials/vgui/playermodels/male_lawyer.vtf" )
	resource.AddFile( "materials/vgui/playermodels/male_pi.vtf" )
	resource.AddFile( "materials/vgui/zombies/banshee.vtf" )
	resource.AddFile( "materials/vgui/zombies/banshee_small.vtf" )
	resource.AddFile( "materials/vgui/zombies/drifter.vtf" )
	resource.AddFile( "materials/vgui/zombies/drifter_small.vtf" )
	resource.AddFile( "materials/vgui/zombies/hulk.vtf" )
	resource.AddFile( "materials/vgui/zombies/hulk_small.vtf" )
	resource.AddFile( "materials/vgui/zombies/immolator.vtf" )
	resource.AddFile( "materials/vgui/zombies/immolator_small.vtf" )
	resource.AddFile( "materials/vgui/zombies/shambler.vtf" )
	resource.AddFile( "materials/vgui/zombies/shambler_small.vtf" )
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
	resource.AddFile( "models/weapons/c_improvised_zm.mdl" )
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
	resource.AddFile( "sound/npc/shamblie/growl_0.wav" )
	resource.AddFile( "sound/npc/shamblie/growl_1.wav" )
	resource.AddFile( "sound/npc/shamblie/growl_2.wav" )
	resource.AddFile( "sound/npc/shamblie/growl_3.wav" )
	resource.AddFile( "sound/npc/shamblie/growl_4.wav" )
	resource.AddFile( "sound/npc/shamblie/growl_5.wav" )
	resource.AddFile( "sound/npc/shamblie/growl_6.wav" )
	resource.AddFile( "sound/npc/shamblie/growl_7.wav" )
	resource.AddFile( "sound/npc/shamblie/growl_8.wav" )
	resource.AddFile( "sound/npc/shamblie/hit_0.wav" )
	resource.AddFile( "sound/npc/shamblie/hit_1.wav" )
	resource.AddFile( "sound/npc/shamblie/hit_2.wav" )
	resource.AddFile( "sound/npc/shamblie/hit_3.wav" )
	resource.AddFile( "sound/npc/shamblie/hit_4.wav" )
	resource.AddFile( "sound/npc/shamblie/hit_5.wav" )
	resource.AddFile( "sound/npc/shamblie/hit_6.wav" )
	resource.AddFile( "sound/npc/shamblie/hit_7.wav" )
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