AddCSLuaFile()
DEFINE_BASECLASS("player_zm")

local PLAYER = {}

PLAYER.WalkSpeed 			= 170
PLAYER.RunSpeed				= 170
PLAYER.CrouchedWalkSpeed	= 0.65

PLAYER.DropWeaponOnDie		= true
PLAYER.TeammateNoCollide	= false

function PLAYER:Spawn()
	BaseClass.Spawn(self)
	
	self.Player:SetMoveType(MOVETYPE_WALK)
	
	self.Player:StripWeapons()
	self.Player:SetColor(color_white)

	if self.Player:GetMaterial() ~= "" then
		self.Player:SetMaterial("")
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
function PLAYER:SetModel()
	local cl_playermodel = string.lower(self.Player:GetInfo("cl_playermodel"))
	local modelname = string.lower(player_manager.TranslatePlayerModel(#cl_playermodel == 0 and GAMEMODE.RandomPlayerModels[math.random(#GAMEMODE.RandomPlayerModels)] or cl_playermodel))
	if GAMEMODE.RestrictedPMs[cl_playermodel] then
		self.Player:SetModel(player_manager.TranslatePlayerModel(GAMEMODE.RandomPlayerModels[math.random(#GAMEMODE.RandomPlayerModels)]))
	else
		self.Player:SetModel(modelname)
	end
	
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

function PLAYER:Loadout()
	self.Player:Give("weapon_zm_fists")
end

function PLAYER:Think()
	if self.Player:WaterLevel() == 3 then
		if self.Player:IsOnFire() then
			self.Player:Extinguish()
		end

		if self.Player.drowning then
			if self.Player.drowning < CurTime() then
				local dmginfo = DamageInfo()
				dmginfo:SetDamage(15)
				dmginfo:SetDamageType(DMG_DROWN)
				dmginfo:SetAttacker(game.GetWorld())

				self.Player:TakeDamageInfo(dmginfo)

				self.Player.drowning = CurTime() + 1
			end
		else
			self.Player.drowning = CurTime() + 30
		end
	else
		self.Player.drowning = nil
	end
end

function PLAYER:AllowPickup(ent)
	if ent:IsPlayerHolding() then return false end
	
	local entclass = ent:GetClass()
	if (string.sub(entclass, 1, 12) == "prop_physics" or string.sub(entclass, 1, 12) == "func_physbox") and self.Player:Alive() and ent:GetMoveType() == MOVETYPE_VPHYSICS and ent:GetPhysicsObject():IsValid() and ent:GetPhysicsObject():GetMass() <= CARRY_MASS and ent:GetPhysicsObject():IsMoveable() and ent:OBBMins():Length() + ent:OBBMaxs():Length() <= CARRY_VOLUME then
		return true
	end
	
	return false
end

function PLAYER:CanPickupWeapon(ent)
	if self.Player.DelayPickup and self.Player.DelayPickup > CurTime() then 
		self.Player.DelayPickup = 0
		return false 
	end
	
	if self.Player:Alive() then
		if ent.ThrowTime and ent.ThrowTime > CurTime() then return false end

		if self.Player:HasWeapon(ent:GetClass()) then 
			if ent.WeaponIsAmmo then
				return hook.Call("PlayerCanPickupItem", GAMEMODE, self.Player, ent)
			end
			
			return false 
		end
		
		local weps = self.Player:GetWeapons()
		for index, wep in pairs(weps) do
			if wep:GetSlot() == ent:GetSlot() then
				return false
			end
		end
		
		if ent:CreatedByMap() or ent.Dropped then
			local class = ent:GetClass()
			
			self.Player:Give(class)
			
			local wep = self.Player:GetWeapon(class)
			if not wep.IsMelee and wep:GetClass() == class then
				wep:SetClip1(ent:Clip1())
				wep:SetClip2(ent:Clip2())
			end
			
			ent:Remove()
			return false
		end
		
		return true
	end
	
	self.Player.DelayPickup = CurTime() + 0.2
	
	return false
end

function PLAYER:CanPickupItem(item)
	if self.Player.DelayItemPickup and self.Player.DelayItemPickup > CurTime() then 
		self.Player.DelayItemPickup = 0
		return false 
	end
	
	if self.Player:Alive() and string.sub(item:GetClass(), 1, 10) == "item_ammo_" or item:GetClass() == "item_zm_ammo" or item:GetClass() == "weapon_zm_molotov" then
		if item.ThrowTime and item.ThrowTime > CurTime() then return false end
		
		for _, wep in pairs(self.Player:GetWeapons()) do
			local primaryammo = wep.Primary and wep.Primary.Ammo or ""
			local secondaryammo = wep.Secondary and wep.Secondary.Ammo or ""
			local ammotype = GAMEMODE.AmmoClass[item.ClassName] or ""
			
			if string.find(string.lower(primaryammo), string.lower(ammotype)) or string.find(string.lower(secondaryammo), string.lower(ammotype)) then
				local ammoid = game.GetAmmoID(ammotype)
				if self.Player:GetAmmoCount(ammotype) < game.GetAmmoMax(ammoid) then
					return true
				end
			end
		end
		
		return false
	end
	
	self.Player.DelayItemPickup = CurTime() + 0.2
	
	return false
end

function PLAYER:BindPress(bind, pressed)
	if bind == "+menu" and pressed then
		RunConsoleCommand("zm_dropweapon")
		return true
	elseif bind == "+menu_context" and pressed then
		RunConsoleCommand("zm_dropammo")
		return true
	end
end

function PLAYER:PreDeath(inflictor, attacker)
	if string.find(attacker:GetClass(), "npc_") or string.find(inflictor:GetClass(), "npc_") then
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
		
		return true
	end
end

function PLAYER:OnDeath(attacker, dmginfo)
	BaseClass.OnDeath(self, attacker, dmginfo)
	
	self.Player:Flashlight(false)
	
	local pZM = GAMEMODE:FindZM()
	if IsValid(pZM) then
		local income = math.random(GetConVar("zm_resourcegainperplayerdeathmin"):GetInt(), GetConVar("zm_resourcegainperplayerdeathmax"):GetInt())
		
		pZM:AddZMPoints(income)
		pZM:SetZMPointIncome(pZM:GetZMPointIncome() + 10)
	end
end

function PLAYER:OnHurt(attacker, healthremaining, damage)
	if 0 < healthremaining then
		self.Player:PlayPainSound()
	end
end

function PLAYER:ShouldTakeDamage(attacker)
	if attacker.PBAttacker and attacker.PBAttacker:IsValid() and CurTime() < attacker.NPBAttacker then -- Protection against prop_physbox team killing. physboxes don't respond to SetPhysicsAttacker()
		attacker = attacker.PBAttacker
	end
	
	if IsValid(attacker) then
		local attowner = attacker.Team
		if type(attowner) ~= "function" and IsValid(attowner) then
			if attacker:GetClass() == "env_fire" and attowner and self.Player:Team() == attowner then
				return false
			end
		end
	end

	if attacker:IsPlayer() and attacker ~= self.Player and not attacker.AllowTeamDamage and not self.Player.AllowTeamDamage and attacker:Team() == pl:Team() then return false end
	
	local entclass = attacker:GetClass()
	if string.find(entclass, "item_") then
		return false
	end

	return true
end

player_manager.RegisterClass("player_survivor", PLAYER, "player_zm")