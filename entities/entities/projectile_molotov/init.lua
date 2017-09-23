AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

ENT.m_flDamage = 40
ENT.m_DmgRadius = 128

function ENT:Initialize()
	self:SetMoveType(MOVETYPE_FLYGRAVITY)
	self:SetMoveCollide(MOVECOLLIDE_FLY_BOUNCE)
	self:SetSolid(SOLID_BBOX)
	self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
	self:RemoveEffects(EF_NOINTERP)
	
	self:SetModel("models/weapons/molotov3rd_zm.mdl")
	
	self:SetGravity(1.0)
	self:SetFriction(0.8)
	self:SetSequence(1)
	
	local fireTrail = ents.Create("env_fire_trail")
	fireTrail:FollowBone(self, self:LookupBone("flame"))
	fireTrail:Spawn()
	fireTrail:Activate()
	
	self:SetTrigger(true)
end

function ENT:Touch(pOther)
	if (bit.band(pOther:GetSolidFlags(), FSOLID_TRIGGER) == 0 or bit.band(pOther:GetSolidFlags(), FSOLID_VOLUME_CONTENTS) == 0) and pOther:GetCollisionGroup() ~= COLLISION_GROUP_WEAPON then
		return
	end

	self:Detonate()
end

function ENT:Detonate() 
	self:SetNoDraw(true)
	self:AddSolidFlags(FSOLID_NOT_SOLID)
	
	local trace = self:GetTouchTrace()
	if trace.Fraction ~= 1.0 then
		self:SetLocalPos(trace.HitPos + (trace.HitNormal * (self.m_flDamage - 24) * 0.6))
	end

	local contents = util.PointContents(self:GetPos())
	if bit.band(contents, MASK_WATER) ~= 0 then
		self:Remove()
		return
	end
	
	local dmginfo = DamageInfo()
		dmginfo:SetAttacker(self.Owner)
		dmginfo:SetInflictor(self)
		dmginfo:SetDamage(self.m_flDamage)
		dmginfo:SetDamagePosition(trace.HitPos)
		dmginfo:SetDamageType(DMG_BURN)
	util.BlastDamageInfo(dmginfo, trace.HitPos, self.m_DmgRadius)
	
	local effectdata = EffectData()
		effectdata:SetOrigin(trace.HitPos)
	util.Effect("HelicopterMegaBomb", effectdata)
	
	util.Decal("Scorch", self:GetPos(), trace.HitPos - trace.HitNormal)

	self:EmitSound("Grenade_Molotov.Detonate")
	self:EmitSound("Grenade_Molotov.Detonate2")
	
	local owner = self:GetOwner()
    for _, v in pairs(ents.FindInSphere(trace.HitPos, self.m_DmgRadius)) do
		if v:IsNPC() then
			v:Ignite(100)
		elseif v == owner then
			v:Ignite(3)
		end
    end
	
	for i = 1, 10 do
		local fire = ents.Create("env_fire")
		fire:SetPos(trace.HitPos + Vector(math.random(-80, 80), math.random(-80, 80), 0))
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
		sparks:SetPos( trace.HitPos + Vector( math.random( -40, 40 ), math.random( -40, 40 ), math.random( -40, 40 ) ) )
		sparks:SetKeyValue( "MaxDelay", "0" )
 		sparks:SetKeyValue( "Magnitude", "2" )
		sparks:SetKeyValue( "TrailLength", "3" )
		sparks:SetKeyValue( "spawnflags", "0" )
		sparks:Spawn()
		sparks:Fire( "SparkOnce", "", 0 )
	end	
end