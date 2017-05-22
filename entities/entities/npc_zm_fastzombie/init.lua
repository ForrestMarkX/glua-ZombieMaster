AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

ENT.NextLeap = CurTime()
ENT.LeapSound = "NPC_FastZombie.Scream"
ENT.AttackDamage = 6
ENT.CanSwatPhysicsObjects = false
ENT.FootStepTime = 0.15

ENT.AttackSounds = "NPC_FastZombie.Attack"
ENT.DeathSounds = "NPC_FastZombie.Die"
ENT.PainSounds = "NPC_FastZombie.Pain"
ENT.MoanSounds = "NPC_FastZombie.Idle"
ENT.ClawHitSounds = "NPC_FastZombie.AttackHit"
ENT.ClawMissSounds = "NPC_FastZombie.AttackMiss"
ENT.AlertSounds	= "NPC_FastZombie.AlertNear"
ENT.MoveSounds = {
	"NPC_FastZombie.FootstepRight",
	"NPC_FastZombie.FootstepLeft"
}

local zcheckceiling_sched = ai_schedule.New("SCHED_FASTZOMBIE_CEILING_JUMP")
zcheckceiling_sched:EngTask("TASK_SET_ACTIVITY", ACT_IDLE)
zcheckceiling_sched:AddTask("CheckCeiling", 0)
zcheckceiling_sched:AddTask("JumpToCeiling", 0)
zcheckceiling_sched:EngTask("TASK_SET_ACTIVITY", ACT_HOP)

local zclingceiling_sched = ai_schedule.New("SCHED_FASTZOMBIE_CEILING_CLING")
zclingceiling_sched:EngTask("TASK_SET_ACTIVITY", ACT_IDLE)
zclingceiling_sched:AddTask("ClingCeiling", {Value = 99999})
zclingceiling_sched:EngTask("TASK_WAIT", 0.2)
zclingceiling_sched:EngTask("TASK_PLAY_SEQUENCE", ACT_RANGE_ATTACK1)
zclingceiling_sched:EngTask("TASK_RANGE_ATTACK1", 0)
zclingceiling_sched:EngTask("TASK_WAIT", 0.1)
zclingceiling_sched:EngTask("TASK_FACE_ENEMY", 0)

local schdfrenzy = ai_schedule.New("SCHED_FASTZOMBIE_FRENZY")
schdfrenzy:AddTask("PlaySequence", {Name = "BR2_Roar", Wait = true})

local schdrangeattack = ai_schedule.New("SCHED_FASTZOMBIE_RANGE_ATTACK1")
schdrangeattack:AddTask("PlaySequence", {Name = "LeapStrike", Loop = true})

local schdlandright = ai_schedule.New("SCHED_FASTZOMBIE_LAND_RIGHT")
schdlandright:AddTask("PlaySequence", {Name = "LandRight"})

local schdlandleft = ai_schedule.New("SCHED_FASTZOMBIE_LAND_LEFT")
schdlandleft:AddTask("PlaySequence", {Name = "LandLeft"})

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	self:CapabilitiesAdd(bit.bor(CAP_MOVE_JUMP, CAP_MOVE_CLIMB))
	
	local maxs = self:OBBMaxs()
	maxs.z = maxs.z - 20.0
	self:SetCollisionBounds(self:OBBMins(), maxs)
	
	self:DefineCustomSchedule(zcheckceiling_sched)
	self:DefineCustomSchedule(zclingceiling_sched)
	self:DefineCustomSchedule(schdfrenzy)
	self:DefineCustomSchedule(schdrangeattack)
	self:DefineCustomSchedule(schdlandright)
	self:DefineCustomSchedule(schdlandleft)
end

function ENT:PerformLeapAttack()
	self.LeapAttack = false
	self.bWasLeaping = true
	self:EmitSound(self.LeapSound)
	self.NextLeap = CurTime()
	
	self.inAir = (self:GetGroundEntity() == NULL)
	
	self:SetGroundEntity(NULL)
	self:SetTrigger(true)
	self.Touch = self.TouchLeap

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
			jumpDirection.z = jumpDirection.z + 25
		else
			jumpDirection.z = math.abs(speed)
			
			local distance = jumpDirection:Length()
			
			if distance > 900 then
				jumpDirection = jumpDirection * (900 / distance)
			end
			
			jumpDirection.z = jumpDirection.z + enemy:EyePos().z
			self:SetLocalVelocity(jumpDirection)
		end
	end
end

function ENT:TouchLeap(ent)
	if ent:IsPlayer() and ent:IsSurvivor() then
		local forward = self:GetAngles():Forward()
		local qaPunch = Angle(5, math.random(-2,2), math.random(-2,2))
		
		forward = forward * 40
		
		self:ClawAttack(6, math.floor(self.AttackDamage * 0.25), qaPunch, forward)
	end
end

function ENT:CustomThink()
	local enemy = self:GetEnemy()
	if self.bWasLeaping and self:IsOnGround() then
		self:TaskComplete()
		self:SetNPCState(NPC_STATE_COMBAT)
		self:SetTrigger(false)
		self:SetSequence(self:SelectWeightedSequence(ACT_IDLE))
		self.Touch = nil
		
		self.bWasLeaping = false
	end
	
	if IsValid(enemy) then
		local distance = self:GetPos():Distance(enemy:GetPos())
		if self:VisibleVec(enemy:WorldSpaceCenter()) and (distance < 360 and distance > self:GetClawAttackRange()) and not self.IsAttacking and self.NextLeap + 4 < CurTime() then	
			self.LeapAttack = true
			
			self:SetSchedule(SCHED_RANGE_ATTACK1)
			
			local seq = self:SelectWeightedSequence(ACT_RANGE_ATTACK1)
			local len = self:SequenceDuration(seq)
			timer.Simple(len, function()
				if not self.LeapAttack then return end
				
				self:StartSchedule(schdrangeattack)
				self:PerformLeapAttack()
			end)
		end
	end
end

--[[
function ENT:PerformAttackEnd()
	self.BaseClass.PerformAttackEnd(self)
	self:StartSchedule(schdfrenzy)
	
	local seq, len = self:LookupSequence("BR2_Roar")
	timer.Simple(len, function()
		self:EmitSound("NPC_FastZombie.Frenzy")
		self:SetSequence(self:SelectWeightedSequence(ACT_IDLE))
		self:TaskComplete()
		self:SetNPCState(NPC_STATE_COMBAT)
		self.FrenzyTime = nil
	end)
end
--]]

function ENT:PlayAttackSequence()
	self:SetSchedule(SCHED_MELEE_ATTACK1)
	
	if self.AttackSounds then
		self:PlayVoiceSound(self.AttackSounds)
	end
	
	local seq = self:SelectWeightedSequence(ACT_MELEE_ATTACK1)
	local len = self:SequenceDuration(seq)
	self.AttackEnd = CurTime() + len
	self.AttackTime = CurTime()
end

function ENT:SelectSchedule()
	if self.FrenzyTime then return end
	
	local enemy = self:GetEnemy()
	if IsValid(enemy) then
		local melee = self:MeleeAttack1Conditions(self:GetPos():Dot(enemy:GetPos()), self:GetPos():Distance(enemy:GetPos()))
		if melee and not self.IsAttacking then 
			self.IsAttacking = true
			self:PlayAttackSequence()
		else
			if not self.LeapAttack then
				self:SetSchedule(SCHED_CHASE_ENEMY)
				self.IsAttacking = false
			end
		end
	else
		self:UpdateEnemy(self:FindEnemy())
	end
end

function ENT:MeleeAttack1Conditions(flDot, flDist)
	if not IsValid(self:GetEnemy()) or bit.band(self:GetFlags(), FL_ONGROUND) == 0 then
		return false
	end

	return self.BaseClass.MeleeAttack1Conditions(self, flDot, flDist);
end

function ENT:IsCeilingFlat(plane_normal)
	local flat = Vector(0, 0, -1)
	local roofdot = math.abs(plane_normal:Dot(flat))

	if roofdot > 0.95 then
		return true
	end

	return false
end

function ENT:GetClingAmbushTarget()
	local count = ents.FindInSphere(self:GetPos(), 64)
	
	local nearest = NULL
	local nearest_dist = 0
	for _, ent in pairs(count) do
		if not ent:IsPlayer() or not ent:IsSurvivor() then continue end

		local current_dist = self:GetPos():Distance(ent:GetPos())
		if not IsValid(nearest) or nearest_dist > current_dist then
			nearest = ent
			nearest_dist = current_dist
		end
	end

	return nearest
end

function ENT:CeilingDetach()
	self:SetMoveType(MOVETYPE_STEP)
	self:SetGroundEntity(NULL)
	self.m_bClinging = false
end

function ENT:TaskStart_CheckCeiling(data)
	local upwards = Vector(0, 0, FASTZOMBIE_CLING_MAXHEIGHT);
	local trace = {start = self:GetPos(), endpos = self:GetPos() + upwards, filter = ent, mask = MASK_SOLID}
	local tr = util.TraceEntity(trace, ent)

	if tr.Fraction ~= 1.0 and tr.HitWorld and not tr.HitSky then
		if self:IsCeilingFlat(tr.HitNormal) then
			self:TaskComplete()
		end
	end

	local pZM = GAMEMODE:FindZM()
	if IsValid(pZM) then
		pZM:PrintMessage(HUD_PRINTTALK, "Banshee was unable to find a solid ceiling within range above it!\n")
	end

	self:TaskFail("")
end

function ENT:Task_CheckCeiling(data)
	self:TaskComplete()
end	

function ENT:TaskStart_ClingCeiling(data)
end

function ENT:Task_ClingCeiling(data)
	if self:HasCondition(COND_LIGHT_DAMAGE) or self:HasCondition(COND_RECEIVED_ORDERS) then
		self:CeilingDetach()
		self:SetVelocity(Vector(0, 0, -100))
		self:TaskComplete()
		return
	end
	
	if self.m_flLastClingCheck < CurTime() then
		local nearest = self:GetClingAmbushTarget()
		
		if IsValid(nearest) then
			self:CeilingDetach()
			self:SetEnemy(nearest)
			self:TaskComplete()
			self.m_flClingLeapStart = CurTime()
			return
		end
		
		self.m_flLastClingCheck = CurTime() + 1.0
	end
end