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
	
	self:SetupAmmo()
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

local ShamblerModels = {
	"models/zombie/zm_classic.mdl",
	"models/zombie/zm_classic_01.mdl",
	"models/zombie/zm_classic_02.mdl",
	"models/zombie/zm_classic_03.mdl",
	"models/zombie/zm_classic_04.mdl",
	"models/zombie/zm_classic_05.mdl",
	"models/zombie/zm_classic_06.mdl",
	"models/zombie/zm_classic_07.mdl",
	"models/zombie/zm_classic_08.mdl",
	"models/zombie/zm_classic_09.mdl"
}
function GM:OnEntityCreated(ent)
	if ent:IsNPC() then
		if string.sub(ent:GetClass(), 1, 12) == "npc_headcrab" then
			ent:SetNoDraw(true)
			ent:Remove() 
		end
	
		if ent.GetNumBodyGroups and ent.SetBodyGroup then
			for k = 0, ent:GetNumBodyGroups() - 1 do
				ent:SetBodyGroup(k, 0)
			end
		end
		
		local entname = ent:GetClass()
		if string.lower(entname) == "npc_zombie" then
			timer.Simple(0, function() if IsValid(ent) then ent:SetModel(ShamblerModels[math.random(#ShamblerModels)]) end end)
		elseif string.lower(entname) == "npc_poisonzombie" then
			timer.Simple(0, function() if IsValid(ent) then ent:SetModel("models/zombie/hulk.mdl") end end)
		elseif string.lower(entname) == "npc_fastzombie" then
			timer.Simple(0, function() if IsValid(ent) then ent:SetModel("models/zombie/zm_fast.mdl") end end)
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
	if ply:Team() == TEAM_ZOMBIEMASTER and not self:GetRoundEnd() then	
		gamemode.Call("TeamVictorious", true, "The Zombie Master has submitted.\n")
	end
	
	return ply:Team() == TEAM_SURVIVOR
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
	
	if ply:Team() == TEAM_SURVIVOR then
		ply:StripWeapons()
		ply:SetColor(color_white)

		if ply:GetMaterial() ~= "" then
			ply:SetMaterial("")
		end
		
		ply:ShouldDropWeapon(false)
		
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
		if victim:Team() == TEAM_SURVIVOR then
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
		
	ply:ResetHull()
	ply:SetCanWalk(false)
	ply:SetCanZoom(false)
	ply:AllowFlashlight(true)
	
	if GetConVar("zm_nocollideplayers"):GetBool() then
		ply:SetNoCollideWithTeammates(true)
		ply:SetCustomCollisionCheck(true)
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
	local numplayers = #player.GetAll()
	
	if #self.ConnectingPlayers > 0 and CurTime() >= self.ReadyTimer then
		table.Empty(self.ConnectingPlayers)
	end
	
	local humans = team.GetPlayers(TEAM_SURVIVOR)
	for _, pl in pairs(humans) do
		if pl:Alive() then
			if pl:WaterLevel() >= 3 and not (pl.status_drown and pl.status_drown:IsValid()) then
				pl:GiveStatus("drown")
			end
		end
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
		
		if numplayers > 20 then
			for _, ply in pairs(players) do
				if not ply:GetNoCollideWithTeammates() then ply:SetNoCollideWithTeammates(true) end
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
			ply.m_iZMPriority = ply.m_iZMPriority + 10
		end
	end
	
	game.CleanUpMap(false)
	
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
		if string.sub(entclass, 1 , 10) == "weapon_zm_" then
			if not gamemode.Call("PlayerCanPickupWeapon", pl, ent) then
				local phys = ent:GetPhysicsObject()
				if IsValid(phys) then
					local mass = phys:GetMass()
					phys:ApplyForceCenter(Vector(math.random(-mass, mass), math.random(-mass, mass), math.random(-mass, mass)) * 50)
				end
				
				return false
			end
			
			pl:EmitSound("items/ammo_pickup.wav")
			pl:Give(entclass)
			
			local wep = pl:GetWeapon(entclass)
			wep:SetClip1(ent:Clip1())
			wep:SetClip2(ent:Clip2())
			
			ent:Remove()
		end
	end

	return true
end

function GM:PlayerSwitchFlashlight(pl, newstate)
	return pl:IsSurvivor()
end

function GM:PlayerCanPickupWeapon(pl, ent)
	if pl:IsSurvivor() and pl:Alive() then
		if ent.ThrowTime and ent.ThrowTime > CurTime() then return false end
		if pl:HasWeapon(ent:GetClass()) and ent.WeaponIsAmmo then return gamemode.Call("PlayerCanPickupItem", pl, ent) end
		
		if pl:HasWeapon(ent:GetClass()) then return false end
		
		local weps = pl:GetWeapons()
		for index, wep in pairs(weps) do
			if wep:GetClass() ~= "weapon_zm_fists" and wep:GetSlot() == ent:GetSlot() then
				return false
			end
		end
		
		return true
	end
	
	return false
end

function GM:PlayerCanPickupItem(pl, item)
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
		
		angles.x = 0.0
		angles.z = 0.0
		pZombie:SetAngles(angles)

		pZombie:Spawn()
		pZombie:Activate()
		
		pZM:TakeZMPoints(cost)
		gamemode.Call("SetCurZombiePop", GAMEMODE:GetCurZombiePop() + popcost)
		
		if entname == "npc_burnzombie" or entname "npc_dragzombie" then
			pZombie:DropToFloor()
			pZombie:SetPos(pZombie:GetPos() + Vector(0, 0, 5))
		end

		return pZombie
	end
	
	return NULL
end

function GM:AddResources()
	resource.AddWorkshop("591300663")
end