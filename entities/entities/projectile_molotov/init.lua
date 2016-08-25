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
end

function ENT:PhysicsCollide(data, physObject)
	local contents = util.PointContents(self:GetPos())
	if bit.band(contents, MASK_WATER) ~= 0 then
		self:Remove()
		return
	end
	
	util.BlastDamageEx(self, self.Owner, self:GetPos(), 128, 40, DMG_BURN)
	
	local effectdata = EffectData()
		effectdata:SetOrigin(self:GetPos())
	util.Effect("HelicopterMegaBomb", effectdata)
	
	self:EmitSound("Grenade_Molotov.Detonate")
	self:EmitSound("Grenade_Molotov.Detonate2")
	
	self:Remove()
end

function ENT:OnRemove()
    for _, v in pairs(ents.FindInSphere(self:GetPos(), 128)) do
        if v:IsWorld() or v:IsWeapon() or not IsValid(v) then return end
		if IsValid(v) and v:IsPlayer() and v ~= self.Owner then return end
        
        if string.find(v:GetClass(), "prop_") then
            local phys = v:GetPhysicsObject()
            if string.find(phys:GetMaterial(), "metal") then
                return
            end
        end
        
        if string.find(v:GetClass(), "info_") then return end
		if v:IsPlayer() and v:IsZM() then return end
        
		v:Ignite(100)
    end
	
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
		fire.Team = TEAM_SURVIVOR
		fire:Fire("StartFire", "", 0)
	end
	
	for i=1, 8 do
		local sparks = ents.Create( "env_spark" )
		sparks:SetPos( self:GetPos() + Vector( math.random( -40, 40 ), math.random( -40, 40 ), math.random( -40, 40 ) ) )
		sparks:SetKeyValue( "MaxDelay", "0" )
 		sparks:SetKeyValue( "Magnitude", "2" )
		sparks:SetKeyValue( "TrailLength", "3" )
		sparks:SetKeyValue( "spawnflags", "0" )
		sparks:Spawn()
		sparks:Fire( "SparkOnce", "", 0 )
	end	
end