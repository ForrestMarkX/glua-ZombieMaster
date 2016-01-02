AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/zombie/burnzie.mdl")
	
	self:SetHullSizeNormal()
	self:SetHullType(HULL_HUMAN)
	
	self:SetSolid(SOLID_BBOX)
	self:SetMoveType(MOVETYPE_STEP)
	self:CapabilitiesAdd(CAP_MOVE_GROUND)
	
	self:SetMaxYawSpeed(5000)
	self:SetHealth(100)
	
	self:ClearSchedule()
	--self:DropToFloor()
	
	self:UpdateEnemy(self:FindEnemy())
	self:SetSchedule(SCHED_IDLE_STAND)
	
	self:SetAutomaticFrameAdvance(true)

	self.damage = 8

	self.attackSounds = "npc/stalker/go_alert2.wav"
	self.deathSounds = "npc/barnacle/neck_snap2.wav"
	self.painSounds = "npc/barnacle/neck_snap1.wav"
	self.tauntSounds = "npc/stalker/breathing3.wav"
end

function ENT:Think()
	if self.nextIdle < CurTime() then
		self:PlayVoiceSound(self.tauntSounds)
		self.nextIdle = CurTime() + math.random(15, 25)
	end
	
	local enemy = self:GetEnemy()
	
 	if IsValid(enemy) and not self.onFire and enemy:GetPos():Distance(self:GetPos()) < 250 then
		for i = 1, 2 do
			local fire = ents.Create("env_fire")
			fire:SetParent(self)
			fire:SetPos(self:GetPos())
			fire:SetKeyValue("health", 100)
			fire:SetKeyValue("firesize", "60")
			fire:SetKeyValue("fireattack", "2")
			fire:SetKeyValue("damagescale", "4.0")
			fire:SetKeyValue("StartDisabled", "0")
			fire:SetKeyValue("firetype", "0" )
			fire:SetKeyValue("spawnflags", "132")
			fire:Spawn()
			fire:Fire("StartFire", "", 0)
		end
		
		timer.Simple(3, function()
			if IsValid(self) then
				util.BlastDamage(self, enemy, self:GetPos(), 128, math.random(10, 20))
				
				local effect = EffectData()
					effect:SetOrigin(self:GetPos())
					effect:SetScale(2)
				util.Effect("Explosion", effect, true, true)
			
				self:Death()
			end
		end)

		self:PlayVoiceSound(self.attackSounds)
		self.onFire = true
	end

	if self.isMoving and self.moveTime < CurTime() then
		local sound = self:PlayVoiceSound(self.moveSounds)
		self.moveTime = CurTime() + SoundDuration(sound)
	end
end

function ENT:OnRemove()
	self:SpawnRagdoll()
	
	for i = 1, 5 do
		local fire = ents.Create("env_fire")
		fire:SetPos(self:GetPos() + Vector(math.random(-40, 40), math.random(-40, 40), 0))
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
end

function ENT:SelectSchedule()
	local enemy = self:GetEnemy()
	local sched = SCHED_IDLE_STAND
	
	if enemy and enemy:IsValid() then
		sched = SCHED_CHASE_ENEMY
		self.isMoving = true
	else
		self:UpdateEnemy(self:FindEnemy())
	end
	
	self:SetSchedule(sched)
end