AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
    self:SetModel(self.Model)
    
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON)
    
    self:SetTrigger(true)
    self:SetCollisionBounds(self:OBBMins() * 4, self:OBBMaxs() * 4)
    
    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:Wake()
    end
end

function ENT:Touch(ent)
    if not IsValid(ent) or not IsValid(self) then return end
    if not ent:IsPlayer() then return end
    if ent.PickupCooldown and ent.PickupCooldown > CurTime() then return end
    if not gamemode.Call("PlayerCanPickupItem", ent, self) then return end
    
    local amount = self.AmmoAmount
    local ammocount = ent:GetAmmoCount(self.AmmoType)
    local ammovar = GetConVar("zm_maxammo_"..self.AmmoType)
    if ammovar == nil then return end
    
    local maxammo = ammovar:GetInt()
    
    if (ammocount + amount) > maxammo then
        amount = maxammo - ammocount
    end
    
    ent:GiveAmmo(amount, self.AmmoType)
    
    self.AmmoAmount = self.AmmoAmount - amount
    
    if self.AmmoAmount <= 0 then
        self:Remove()
    end
end

function ENT:EndTouch(ent)
    ent.PickupCooldown = CurTime() + 0.1
end

function ENT:OnTakeDamage(dmginfo)
    self:TakePhysicsDamage(dmginfo)
end

function ENT:AllowPickup(ply)
    return false
end