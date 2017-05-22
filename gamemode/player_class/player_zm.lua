AddCSLuaFile()
DEFINE_BASECLASS( "player_default" )

if CLIENT then
	CreateConVar( "cl_playercolor", "0.24 0.34 0.41", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD }, "The value is a Vector - so between 0-1 - not between 0-255" )
	CreateConVar( "cl_weaponcolor", "0.30 1.80 2.10", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD }, "The value is a Vector - so between 0-1 - not between 0-255" )
	CreateConVar( "cl_playerskin", "0", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD }, "The skin to use, if the model has any" )
	CreateConVar( "cl_playerbodygroups", "0", { FCVAR_ARCHIVE, FCVAR_USERINFO, FCVAR_DONTRECORD }, "The bodygroups to use, if the model has any" )
end

local PLAYER = {}

PLAYER.TauntCam = TauntCamera()

function PLAYER:SetupDataTables()
	BaseClass.SetupDataTables(self)
end

function PLAYER:Spawn()
	BaseClass.Spawn(self)

	local col = self.Player:GetInfo("cl_playercolor")
	self.Player:SetPlayerColor(Vector(col))

	local col = Vector(self.Player:GetInfo("cl_weaponcolor"))
	if col:Length() == 0 then
		col = Vector(0.001, 0.001, 0.001)
	end
	self.Player:SetWeaponColor(col)
	self.Player:Flashlight(false)
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
function PLAYER:SetModel()
	local cl_playermodel = self.Player:GetInfo("cl_playermodel")
	local modelname = player_manager.TranslatePlayerModel(cl_playermodel)
	if #cl_playermodel == 0 then
		modelname = "models/player/kleiner.mdl"
	end
	
	util.PrecacheModel(modelname)
	self.Player:SetModel(modelname)
	
	local skin = self.Player:GetInfoNum("cl_playerskin", 0)
	self.Player:SetSkin(skin)

	local groups = self.Player:GetInfo("cl_playerbodygroups")
	if groups == nil then groups = "" end
	local groups = string.Explode(" ", groups)
	for k = 0, self.Player:GetNumBodyGroups() - 1 do
		self.Player:SetBodygroup(k, tonumber(groups[ k + 1 ]) or 0)
	end
	
	if VoiceSetTranslate[modelname] then
		self.Player.VoiceSet = VoiceSetTranslate[modelname]
	elseif string.find(modelname, "female", 1, true) then
		self.Player.VoiceSet = "female"
	else
		self.Player.VoiceSet = "male"
	end
end

function PLAYER:ShouldDrawLocal() 
	if self.TauntCam:ShouldDrawLocalPlayer(self.Player, self.Player:IsPlayingTaunt()) then return true end
end

function PLAYER:SetupMove(mv, cmd)
end

function PLAYER:CreateMove( cmd )
	if self.TauntCam:CreateMove(cmd, self.Player, self.Player:IsPlayingTaunt()) then return true end
end

function PLAYER:CalcView( view )
	if self.TauntCam:CalcView(view, self.Player, self.Player:IsPlayingTaunt()) then return true end
end

function PLAYER:GetHandsModel()
	local cl_playermodel = self.Player:GetInfo( "cl_playermodel" )
	return player_manager.TranslatePlayerHands( cl_playermodel )
end

function PLAYER:OnTakeDamage(attacker, dmginfo)
end

function PLAYER:PreDeath(inflictor, attacker)
	-- Don't spawn for at least 2 seconds
	self.Player.NextSpawnTime = CurTime() + 2
	self.Player.DeathTime = CurTime()
	
	if IsValid(attacker) and attacker:GetClass() == "trigger_hurt" then attacker = self.Player end
	
	if IsValid(attacker) and attacker:IsVehicle() and IsValid(attacker:GetDriver()) then
		attacker = attacker:GetDriver()
	end

	if not IsValid(inflictor) and IsValid(attacker) then
		inflictor = attacker
	end

	-- Convert the inflictor to the weapon that they're holding if we can.
	-- This can be right or wrong with NPCs since combine can be holding a
	-- pistol but kill you by hitting you with their arm.
	if IsValid( inflictor ) and inflictor == attacker and (inflictor:IsPlayer() or inflictor:IsNPC()) then
		inflictor = inflictor:GetActiveWeapon()
		if ( !IsValid( inflictor ) ) then inflictor = attacker end
	end

	if attacker == self.Player then
		net.Start("PlayerKilledSelf")
			net.WriteEntity(self.Player)
		net.Broadcast()
		
		MsgAll(attacker:Nick() .. " suicided!\n")
	return end

	if attacker:IsPlayer() then
		net.Start("PlayerKilledByPlayer")
			net.WriteEntity(self.Player)
			net.WriteString(inflictor:GetClass())
			net.WriteEntity(attacker)
		net.Broadcast()
		
		MsgAll(attacker:Nick() .. " killed " .. self.Player:Nick() .. " using " .. inflictor:GetClass() .. "\n")
	return end
	
	if attacker:IsNPC() or inflictor:IsNPC() then
		local attackername = ""
		
		local pZM = GAMEMODE:FindZM()
		if IsValid(pZM) then
			pZM:AddFrags(1)
		end
		
		for _, zombie in pairs(GAMEMODE:GetZombieTable()) do
			if zombie.Class == attacker:GetClass() then
				attackername = zombie.Name
				break
			end
		end
		
		net.Start("PlayerKilledByNPC")
			net.WriteEntity(self.Player)
			net.WriteString(inflictor:GetClass())
			net.WriteString(attackername)
		net.Broadcast()
		
		MsgAll(self.Player:Nick() .. " was killed by " .. attackername .. "\n")
	return end
	
	net.Start("PlayerKilled")
		net.WriteEntity(self.Player)
		net.WriteString(inflictor:GetClass())
		net.WriteString(attacker:GetClass())
	net.Broadcast()
	
	MsgAll(self.Player:Nick() .. " was killed by " .. attacker:GetClass() .. "\n")
end

function PLAYER:OnDeath(attacker, dmginfo)
	self.Player:Freeze(false)
	self.Player:DropAllAmmo()
	
	GAMEMODE.DeadPlayers[self.Player:SteamID()] = true
	
	if IsValid(attacker) and attacker:IsPlayer() then
		if attacker == self.Player then
			attacker:AddFrags(-1)
		else
			attacker:AddFrags(1)
		end
	end
	
	if self.Player:Health() <= -70 and not dmginfo:IsDamageType(DMG_DISSOLVE) then
		self.Player:Gib(dmginfo)
	else
		self.Player:CreateRagdoll()
	end
	
	local hands = self.Player:GetHands()
	if IsValid(hands) then
		hands:Remove()
	end
	
	self.Player:PlayDeathSound()
	
	timer.Simple(0.1, function() 
		if not IsValid(self.Player) then return end
		hook.Call("PlayerSpawnAsSpectator", GAMEMODE, self.Player) 
	end)
end

function PLAYER:PostOnDeath(inflictor, attacker)
	self.Player:Spectate(OBS_MODE_ROAMING)
end

function PLAYER:OnHurt(attacker, healthremaining, damage)
end

local NextThink = 0
function PLAYER:Think()
	if NextThink <= CurTime() then
		NextThink = CurTime() + 0.25
		
		local heldprop = self.Player.HeldObject
		if IsValid(heldprop) and not heldprop:IsPlayerHolding() then
			heldprop:SetCollisionGroup(heldprop._OldCG or COLLISION_GROUP_NONE)
			heldprop._OldCG = nil
			self.Player.HeldObject = nil
		end
	end
end

function PLAYER:PostThink()
end

function PLAYER:DeathThink()
	return true
end

function PLAYER:AllowPickup(ent)
	return false
end

function PLAYER:CanPickupWeapon(ent)
	return false
end

function PLAYER:CanPickupItem(item)
	return false
end

function PLAYER:PreDraw(ply)
	return true
end

function PLAYER:PostDraw(ply)
	return true
end

function PLAYER:ShouldTaunt(act)
	return true
end

function PLAYER:CanSuicide()
	return not GAMEMODE:GetRoundEnd()
end

function PLAYER:BindPress(bind, pressed)
end

function PLAYER:ShouldTakeDamage(attacker)
	return false
end

player_manager.RegisterClass("player_zm", PLAYER, "player_default")