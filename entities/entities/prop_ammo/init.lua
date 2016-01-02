AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

ENT.CleanupPriority = 2

function ENT:Initialize()
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
	
	self:SetTrigger(true)

	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:SetMaterial("material")
		phys:EnableMotion(true)
		phys:Wake()
	end
end

function ENT:SetAmmoType(ammotype)
	self:SetModel(GAMEMODE.AmmoModels[string.lower(ammotype)] or "models/Items/BoxMRounds.mdl")
	self.m_AmmoType = ammotype
end

function ENT:GetAmmoType()
	return self.m_AmmoType or "pistol"
end

function ENT:SetAmmo(ammo)
	self.m_Ammo = tonumber(ammo) or self:GetAmmo()
end

function ENT:GetAmmo()
	return self.m_Ammo or 0
end

function ENT:StartTouch(ent)
end

function ENT:Touch(ent)
	if ent:IsPlayer() and ent:Alive() and ent:Team() == TEAM_SURVIVOR and not self.Removing then
		for _, wep in pairs(ent:GetWeapons()) do
			if wep.Primary and wep.Primary.Ammo and string.lower(wep.Primary.Ammo) == string.lower(self:GetAmmoType()) or wep.Secondary and wep.Secondary.Ammo and string.lower(wep.Secondary.Ammo) == string.lower(self:GetAmmoType()) then
				local ammoid = game.GetAmmoID(self:GetAmmoType())
				if ent:GetAmmoCount(self:GetAmmoType()) < game.GetAmmoMax(ammoid) then
					ent:GiveAmmo(self:GetAmmo(), self:GetAmmoType())
					self:RemoveNextFrame(0)
				end
			end
		end
	end
end

function ENT:EndTouch(ent)
end

function ENT:KeyValue(key, value)
	key = string.lower(key)
	if key == "ammotype" then
		self:SetAmmoType(value)
	end
end

function ENT:OnTakeDamage(dmginfo)
	if dmginfo:GetDamageType() == bit.bor(DMG_BLAST_SURFACE, DMG_BLAST) or dmginfo:GetDamageType() == DMG_BLAST or dmginfo:GetDamageType() == DMG_BLAST_SURFACE then
		dmginfo:SetDamageForce(dmginfo:GetDamageForce() * 0.1)
	elseif dmginfo:GetDamageType() == DMG_BURN then
		dmginfo:SetDamageType(DMG_BULLET)	
		dmginfo:SetDamageForce(Vector(0, 0, 0))
	else
		dmginfo:SetDamageForce(dmginfo:GetDamageForce() * 0.5)
	end
	
	self:TakePhysicsDamage(dmginfo)
end
