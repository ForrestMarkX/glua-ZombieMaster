AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/zombie/zm_fast.mdl")
	
	self:SetHullSizeNormal()
	self:SetHullType(HULL_HUMAN)
	
	self:SetSolid(SOLID_BBOX)
	self:SetMoveType(MOVETYPE_STEP)
	self:CapabilitiesAdd(bit.bor(CAP_MOVE_GROUND, CAP_INNATE_MELEE_ATTACK1, CAP_MOVE_JUMP, CAP_MOVE_CLIMB))
	
	self:SetMaxYawSpeed(5000)
	self:SetHealth(35)
	
	self:ClearSchedule()
	--self:DropToFloor()
	
	self:UpdateEnemy(self:FindEnemy())
	self:SetSchedule(SCHED_IDLE_STAND)
	
	self:SetAutomaticFrameAdvance(true)
	
	self.damage = 12
	self.nextAttack = 0.5
	self.nextLeap = CurTime()
	self.nextPhysics = CurTime() + 1
	self.leapSound = Sound("npc/banshee/leap1.wav")
	
	self.attackSounds = {
		"npc/banshee/wake1.wav",
		"npc/banshee/leap_begin.wav"
	}
	
	self.deathSounds = {
		"npc/banshee/fz_scream1.wav"
	}
	
	self.painSounds = {
		"npc/banshee/leap1.wav",
		"npc/banshee/leap3_long.wav"
	}
	
	self.tauntSounds = {
		"npc/banshee/fz_frenzy1.wav",
		"npc/banshee/fz_frenzy2.wav",
		"npc/banshee/fz_frenzy3.wav",
		"npc/banshee/fz_frenzy4.wav",
		"npc/banshee/fz_frenzy5.wav",
		"npc/banshee/fz_frenzy6.wav",
		"npc/banshee/fz_frenzy7.wav"
	}
	
	self.clawHitSounds = {
		"npc/banshee/claw_strike1.wav",
		"npc/banshee/claw_strike2.wav",
		"npc/banshee/claw_strike3.wav"
	}

	self.clawMissSounds = {
		"npc/banshee/claw_miss1.wav",
		"npc/banshee/claw_miss2.wav"
	}
	
	self.moveSounds = {
		"npc/banshee/foot1.wav",
		"npc/banshee/foot2.wav",
		"npc/banshee/foot3.wav",
		"npc/banshee/foot4.wav"
	}
end

-- From zombie master.
function ENT:LeapAttack()
	self.inAir = (self:GetGroundEntity() == NULL)
	
	self:SetGroundEntity(NULL)
	self:EmitSound(self.leapSound)

	local jumpDirection
	local enemy = self:GetEnemy()
	
	if IsValid(enemy) then
		local enemyPosition = enemy:GetPos()
		local gravity = GetConVar("sv_gravity"):GetFloat()
		
		if gravity <= 1 then
			gravity = 1
		end
		
		local height = (enemyPosition.z - self:GetPos().z)
		
		if height < 24 then
			height = 32
		elseif height > 120 then
			height = 120
		end
		
		local speed = math.sqrt(2 * gravity * height);
		local time = speed /gravity;
		
		jumpDirection = enemyPosition - self:GetPos()
		jumpDirection = jumpDirection / time
		
		if self.inAir then
			jumpDirection.z = math.random(-32, 32)
		else
			jumpDirection.z = speed
			
			local distance = jumpDirection:Length()
			
			if distance > 900 then
				jumpDirection = jumpDirection * (900 / distance)
			end
			
			self:SetVelocity(jumpDirection)
		end
	end

	self.leapAttack = false
	self.nextLeap = CurTime()
end

function ENT:CustomThink()
	local enemy = self:GetEnemy()
	
	if IsValid(enemy) and self:Visible(enemy) and self:GetPos():Distance(enemy:GetPos()) < 360 and not self.attack and self.nextLeap + 4 < CurTime() then	
		self.leapAttack = true
		
		self:SetSchedule(SCHED_RANGE_ATTACK1)
		self:ResetSequence(ACT_RANGE_ATTACK1)
		self:LeapAttack()
	end
end

function ENT:SelectSchedule()
	local enemy = self:GetEnemy()
	local sched = SCHED_IDLE_STAND
	
	if enemy and enemy:IsValid() then
		local melee = self:HasCondition(23)
		
		if melee and not self.attack then
			sched = SCHED_MELEE_ATTACK1
		
			self.attack = true
			self.isMoving = false
			self:PlayVoiceSound(self.attackSounds)
		else
			if not self.leapAttack then
				sched = SCHED_CHASE_ENEMY
				
				self.isMoving = true
				self.attack = false
			end
		end
	else
		self:UpdateEnemy(self:FindEnemy())
	end

	self:SetSchedule(sched)
end