AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/weapons/molotov3rd_zm.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	
	self:GetPhysicsObject():Wake()
	self:SetAngles(Angle(math.random(0, 360), math.random(0, 360), math.random(0, 360)))
	
	local fireTrail = ents.Create("env_fire_trail")
	fireTrail:SetPos(self:GetPos())
	fireTrail:SetParent(self)
	fireTrail:Spawn()
	fireTrail:Activate()
end;

function ENT:PhysicsCollide(data, physObject)
	self:EmitSound("ambient/fire/ignite.wav")
	self:EmitSound("physics/glass/glass_cup_break" .. math.random(1, 2) .. ".wav")

	for i = 1, 10 do
		local fire = ents.Create("env_fire")
		fire:SetPos(self:GetPos() +Vector(math.random(-80, 80), math.random(-80, 80), 0))
		fire:SetKeyValue("health", 25)
		fire:SetKeyValue("firesize", "60")
		fire:SetKeyValue("fireattack", "2")
		fire:SetKeyValue("damagescale", "4.0")
		fire:SetKeyValue("StartDisabled", "0")
		fire:SetKeyValue("firetype", "0" )
		fire:SetKeyValue("spawnflags", "132")
		fire:Spawn()
		fire:Fire("StartFire", "", 0)
	end
	
	self:Remove()
end