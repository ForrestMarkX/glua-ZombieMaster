AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

ENT.m_flDamage = 40
ENT.m_DmgRadius = 128

function ENT:Initialize()
	self:SetModel("models/weapons/molotov3rd_zm.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
	
	self:GetPhysicsObject():Wake()
	self:SetAngles(Angle(math.random(0, 360), math.random(0, 360), math.random(0, 360)))
	
	self:SetGravity(1.0)
	self:SetFriction(0.8)
	self:SetSequence(1)
	
	local fireTrail = ents.Create("env_fire_trail")
	if IsValid(fireTrail) then
		fireTrail:SetPos(self:GetPos())
		fireTrail:SetParent(self)
		fireTrail:Spawn()
		fireTrail:Activate()
	end
end

function ENT:Think()
	if self.PhysicsData then
		if self.HitWater then
			self:Remove()
		else
			self:Detonate(self.PhysicsData.HitPos, self.PhysicsData.HitNormal)
		end
	end
end

function ENT:PhysicsCollide(data, phys)
	self.PhysicsData = data
	local contents = util.PointContents(self:GetPos())
	if bit.band(contents, MASK_WATER) ~= 0 then
		self.HitWater = true
	end
	self:NextThink(CurTime())
end

function ENT:Detonate(hitpos, hitnormal) 
	self:SetNoDraw(true)
	self:AddSolidFlags(FSOLID_NOT_SOLID)

	local contents = util.PointContents(self:GetPos())
	if bit.band(contents, MASK_WATER) ~= 0 then
		self:Remove()
		return
	end
	
	local dmginfo = DamageInfo()
		dmginfo:SetAttacker(self.Owner)
		dmginfo:SetInflictor(self)
		dmginfo:SetDamage(self.m_flDamage)
		dmginfo:SetDamagePosition(hitpos)
		dmginfo:SetDamageType(DMG_BURN)
	util.BlastDamageInfo(dmginfo, hitpos, self.m_DmgRadius)
	
	local effectdata = EffectData()
		effectdata:SetOrigin(hitpos)
	util.Effect("HelicopterMegaBomb", effectdata)
	
	util.Decal("Scorch", self:GetPos(), hitpos - hitnormal)

	self:EmitSound("Grenade_Molotov.Detonate")
	self:EmitSound("Grenade_Molotov.Detonate2")
	
	local owner = self:GetOwner()
    for _, v in pairs(ents.FindInSphere(hitpos, self.m_DmgRadius)) do
		if v:IsNPC() then
			v:Ignite(100)
		elseif v == owner then
			v:Ignite(3)
		end
    end
	
	for i = 1, 10 do
		local fire = ents.Create("env_fire")
		fire:SetPos(hitpos + Vector(math.random(-80, 80), math.random(-80, 80), 0))
		fire:SetKeyValue("health", 25)
		fire:SetKeyValue("firesize", "60")
		fire:SetKeyValue("fireattack", "2")
		fire:SetKeyValue("damagescale", "4.0")
		fire:SetKeyValue("StartDisabled", "0")
		fire:SetKeyValue("firetype", "0" )
		fire:SetKeyValue("spawnflags", "132")
		fire:Spawn()
		fire:Fire("StartFire", "", 0)
		fire:SetOwner(owner)
		
		if owner:IsPlayer() then
			fire.OwnerTeam = owner:Team()
		else
			fire.OwnerTeam = TEAM_SURVIVOR
		end
	end
	
	for i=1, 8 do
		local sparks = ents.Create( "env_spark" )
		sparks:SetPos( hitpos + Vector( math.random( -40, 40 ), math.random( -40, 40 ), math.random( -40, 40 ) ) )
		sparks:SetKeyValue( "MaxDelay", "0" )
 		sparks:SetKeyValue( "Magnitude", "2" )
		sparks:SetKeyValue( "TrailLength", "3" )
		sparks:SetKeyValue( "spawnflags", "0" )
		sparks:Spawn()
		sparks:Fire( "SparkOnce", "", 0 )
	end	
	
	self:Remove()
end