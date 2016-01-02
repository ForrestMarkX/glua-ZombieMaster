AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

function ENT:Initialize()
	self:SetModel("models/weapons/molotov3rd_zm.mdl")
	
	util.PrecacheSound( "mtov_break1" )
	util.PrecacheSound( "mtov_break2" )
	util.PrecacheSound( "mtov_flame1" )
	util.PrecacheSound( "mtov_flame2" )
	util.PrecacheSound( "mtov_flame3" )
	
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	local phys = self:GetPhysicsObject()
	
	if (phys:IsValid()) then
		phys:Wake()
	end
	
	local zfire = ents.Create( "env_fire_trail" )
	zfire:SetPos( self:GetPos() )
	zfire:SetParent( self )
	zfire:Spawn()
	zfire:Activate()
end

function ENT:Think()
end

function ENT:Explosion()
 	util.BlastDamageEx( self, self:GetOwner(), self:GetPos(), 100, 150, DMG_BURN )
	local effectdata = EffectData()
		effectdata:SetOrigin( self:GetPos() )
	util.Effect( "HelicopterMegaBomb", effectdata )	 -- Big flame	
	
	for i=1, 12 do
		local fire = ents.Create( "env_fire" )
		fire:SetPos( self:GetPos() + Vector( math.random( -100, 100 ), math.random( -100, 100 ), 0 ) )
		fire:SetKeyValue( "health", math.random( 10, 15 ) )
		fire:SetKeyValue( "firesize", "15" )
		fire:SetKeyValue( "fireattack", "2" )
		fire:SetKeyValue( "damagescale", "1.0" )
		fire:SetKeyValue( "StartDisabled", "0" )
		fire:SetKeyValue( "firetype", "0" )
		fire:SetKeyValue( "spawnflags", "132" )
		fire:Spawn()
		fire:Fire( "StartFire", "", 0.2 )
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
	
	for _, v in pairs(ents.FindInSphere(self.Entity:GetPos(), 100)) do
		if v:IsPlayer() or v:IsWorld() or v:IsWeapon() or not v:IsValid() then return end
		
		if string.find(v:GetClass(), "prop_") then
			local phys = v:GetPhysicsObject()
			if string.find(phys:GetMaterial(), "metal") then
				return
			end
		end
		
		v:Ignite(60, 100)
	end
end

function ENT:PhysicsCollide( data, physobj ) 
	util.Decal("Scorch", data.HitPos + data.HitNormal , data.HitPos - data.HitNormal) 
	self:EmitSound("weapons/1molotov/mtov_break" .. math.random( 1,2 ) .. ".wav")
	self:EmitSound("weapons/1molotov/mtov_flame" .. math.random( 2,3 ) .. ".wav")
	self:Explosion()
	self:Remove()
end