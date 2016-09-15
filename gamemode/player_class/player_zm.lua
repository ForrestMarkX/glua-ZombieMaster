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
end

function PLAYER:ShouldDrawLocal() 
	if self.TauntCam:ShouldDrawLocalPlayer(self.Player, self.Player:IsPlayingTaunt()) then return true end
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
	
	hook.Call("PlayerSpawnAsSpectator", GAMEMODE, self.Player)
end

function PLAYER:PostOnDeath(inflictor, attacker)
	self.Player:Spectate(OBS_MODE_ROAMING)
	if not GAMEMODE:GetRoundEnd() and GAMEMODE:GetRoundActive() then
		if team.NumPlayers(TEAM_SURVIVOR) == 0 then
			hook.Call("TeamVictorious", GAMEMODE, false, "undead_has_won")
		end
	end
end

function PLAYER:OnHurt(attacker, healthremaining, damage)
end

function PLAYER:Think()
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
	return true
end

function PLAYER:BindPress(bind, pressed)
end

function PLAYER:ShouldTakeDamage(attacker)
	return false
end

player_manager.RegisterClass("player_zm", PLAYER, "player_default")