AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_animations.lua")

include("shared.lua")

ENT.CleanupPriority = 1

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_BBOX)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

	self:SetTrigger(true)

	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:SetMaterial("material")
		phys:EnableMotion(true)
		phys:Wake()
	end
end

function ENT:SetClip1(ammo)
	self.m_Clip1 = tonumber(ammo) or self:GetClip1()
end

function ENT:GetClip1()
	return self.m_Clip1 or 0
end

function ENT:SetClip2(ammo)
	self.m_Clip2 = tonumber(ammo) or self:GetClip2()
end

function ENT:GetClip2()
	return self.m_Clip2 or 0
end

function ENT:SetShouldRemoveAmmo(bool)
	self.m_DontRemoveAmmo = not bool
end

function ENT:GetShouldRemoveAmmo()
	return not self.m_DontRemoveAmmo
end

function ENT:StartTouch(ent)
end

function ENT:Touch(ent)
	local activator = ent
	if not activator:IsPlayer() or not activator:Alive() or activator:Team() == TEAM_ZOMBIEMASTER or self.Removing then return end

	local weptype = self:GetWeaponType()
	if not weptype then return end

	local hasweapon = false
	local stored = weapons.GetStored(weptype)
	if not activator:HasWeapon(weptype) then
		for _, wep in pairs(ent:GetWeapons()) do
			if stored.Slot == wep:GetSlot() then
				hasweapon = true
				break
			end
		end
				
		if not hasweapon then
			local wepclass = activator:Give(weptype)
			if wepclass and wepclass:IsValid() and wepclass:GetOwner():IsValid() then
				if self:GetShouldRemoveAmmo() then
					wepclass:SetClip1(self:GetClip1())
					wepclass:SetClip2(self:GetClip2())
				end
				activator:SendLua("surface.PlaySound('items/ammo_pickup.wav')")
				self:RemoveNextFrame()
			end
		end
	elseif stored.WeaponIsAmmo then
		local ammoid = game.GetAmmoID(stored.Primary.Ammo)
		if activator:GetAmmoCount(stored.Primary.Ammo) < game.GetAmmoMax(ammoid) then
			activator:GiveAmmo(1, stored.Primary.Ammo)
			self:RemoveNextFrame()
		end
	end
end

function ENT:EndTouch(ent)
end

function ENT:KeyValue(key, value)
	key = string.lower(key)
	if key == "weapontype" then
		self:SetWeaponType(value)
	end
end

function ENT:OnTakeDamage(dmginfo)
	if dmginfo:GetDamageType() == bit.bor(DMG_BLAST_SURFACE, DMG_BLAST) then
		dmginfo:SetDamageForce(dmginfo:GetDamageForce() * 0.2)
	elseif dmginfo:GetDamageType() == DMG_BURN then
		dmginfo:SetDamageType(DMG_BULLET)	
		dmginfo:SetDamageForce(Vector(0, 0, 0))
	else
		dmginfo:SetDamageForce(dmginfo:GetDamageForce() * 0.5)
	end
	
	self:TakePhysicsDamage(dmginfo)
end