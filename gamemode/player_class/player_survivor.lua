AddCSLuaFile()
DEFINE_BASECLASS("player_zm")

local PLAYER = {}

PLAYER.WalkSpeed 			= 170
PLAYER.RunSpeed				= 170
PLAYER.CrouchedWalkSpeed	= 0.65

PLAYER.AvoidPlayers			= false
PLAYER.TeammateNoCollide	= false

function PLAYER:Spawn()
	BaseClass.Spawn(self)
	
	self.Player:CrosshairEnable()
	self.Player:SetMoveType(MOVETYPE_WALK)
	self.Player:SetCollisionGroup(COLLISION_GROUP_PLAYER)
	self.Player:ResetHull()
	self.Player:UnSpectate()
	
	self.Player:StripWeapons()
	self.Player:SetColor(color_white)

	if self.Player:GetMaterial() ~= "" then
		self.Player:SetMaterial("")
	end
end

function PLAYER:Loadout()
	self.Player:Give("weapon_zm_fists")
end

function PLAYER:Think()
	BaseClass.Think(self)
	
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
	if not ent:IsValid() or ent:IsPlayerHolding() or not self.Player:Alive() then return false end
	
	local phys = ent:GetPhysicsObject()
	local objectMass = 0
	if IsValid(phys) then
		objectMass = phys:GetMass()
		if phys:HasGameFlag(FVPHYSICS_NO_PLAYER_PICKUP) then
			return false
		end
	else
		return false
	end
	
	if ent.AllowPickup and not ent:AllowPickup(self.Player) then 
		return false 
	end
	
	if CARRY_MASS > 0 and objectMass > CARRY_MASS then
		return false
	end

	--[[
	if sizeLimit > 0 then
		local size = ent:OBBMaxs() - ent:OBBMins()
		if size.x > sizeLimit or size.y > sizeLimit or size.z > sizeLimit then
			return false
		end
	end
	--]]
	
	return true
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
			
			if string.lower(primaryammo) == string.lower(ammotype) or string.lower(secondaryammo) == string.lower(ammotype) then
				local ammoid = game.GetAmmoID(ammotype)
				local ammovar = GetConVar("zm_maxammo_"..primaryammo or secondaryammo)
				
				if ammovar == nil then return end
				
				if self.Player:GetAmmoCount(ammotype) < ammovar:GetInt() then
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
	if input.IsKeyDown(GetConVar("zm_dropweaponkey"):GetInt()) and pressed then
		RunConsoleCommand("zm_dropweapon")
		return true
	elseif input.IsKeyDown(GetConVar("zm_dropammokey"):GetInt()) and pressed then
		RunConsoleCommand("zm_dropammo")
		return true
	end
end

function PLAYER:PreDeath(inflictor, attacker)
	BaseClass.PreDeath(self, inflictor, attacker)
	
	self.Player:Flashlight(false)
	self.Player:CrosshairDisable()
	
	for _, wep in pairs(self.Player:GetWeapons()) do
		if IsValid(wep) and not wep.Undroppable then
			self.Player:DropWeapon(wep)
		end
	end
end

function PLAYER:OnDeath(attacker, dmginfo)
	BaseClass.OnDeath(self, attacker, dmginfo)
	
	local pZM = GAMEMODE:FindZM()
	if IsValid(pZM) then
		local income = math.random(GetConVar("zm_resourcegainperplayerdeathmin"):GetInt(), GetConVar("zm_resourcegainperplayerdeathmax"):GetInt())
		
		pZM:AddZMPoints(income)
		pZM:SetZMPointIncome(pZM:GetZMPointIncome() + 10)
	end
end

function PLAYER:PostOnDeath(inflictor, attacker)
	timer.Simple(0.15, function()
		if team.NumPlayers(TEAM_SURVIVOR) == 0 then
			hook.Call("TeamVictorious", GAMEMODE, false, "undead_has_won")
		end
	end)
end

function PLAYER:OnHurt(attacker, healthremaining, damage)
	if 0 < healthremaining then
		self.Player:PlayPainSound()
	end
end

function PLAYER:OnTakeDamage(attacker, dmginfo)
	local inflictor = dmginfo:GetInflictor()
	if IsValid(attacker) then
		if attacker:GetClass() == "projectile_molotov" then
			return true
		elseif attacker:IsNPC() and attacker.Dead then
			return true
		end
	end
	
	if IsValid(inflictor) then
		if inflictor:GetClass() == "projectile_molotov" then
			return true
		elseif inflictor:IsNPC() and inflictor.Dead then
			return true
		end
	end
end

function PLAYER:ShouldTakeDamage(attacker)
	if attacker.PBAttacker and attacker.PBAttacker:IsValid() and CurTime() < attacker.NPBAttacker then -- Protection against prop_physbox team killing. physboxes don't respond to SetPhysicsAttacker()
		attacker = attacker.PBAttacker
	end
	
	if IsValid(attacker) then
		local attowner = attacker:GetOwner()
		if attacker:GetClass() == "env_fire" and IsValid(attowner) and attowner:IsPlayer() and attowner:Team() == self.Player:Team() and attowner ~= self.Player then
			return false
		end
	end

	if attacker:IsPlayer() and attacker ~= self.Player and not attacker.AllowTeamDamage and not self.Player.AllowTeamDamage and attacker:Team() == self.Player:Team() then return false end
	
	local entclass = attacker:GetClass()
	if string.find(entclass, "item_") then
		return false
	end

	return true
end

player_manager.RegisterClass("player_survivor", PLAYER, "player_zm")