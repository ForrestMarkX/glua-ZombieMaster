AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/humans/zm_draggy.mdl")
	
	self:SetHullSizeNormal()
	self:SetHullType(HULL_HUMAN)
	
	self:SetSolid(SOLID_BBOX)
	self:SetMoveType(MOVETYPE_STEP)
	self:CapabilitiesAdd(bit.bor(CAP_MOVE_GROUND, CAP_INNATE_MELEE_ATTACK1))
	
	self:SetMaxYawSpeed(5000)
	self:SetHealth(100)
	
	self:ClearSchedule()
	--self:DropToFloor()
	
	self:UpdateEnemy(self:FindEnemy())
	self:SetSchedule(SCHED_IDLE_STAND)
	
	self:SetAutomaticFrameAdvance(true)

	self.damage = 10
	self.nextAttack = 0.8
	self.nextDoorFind = CurTime()
	
	self.deathSounds = {
		"npc/barnacle/barnacle_tongue_pull1.wav",
		"npc/barnacle/barnacle_tongue_pull2.wav",
		"npc/barnacle/barnacle_tongue_pull3.wav"
	}
	
	self.painSounds = {
		"npc/barnacle/barnacle_pull1.wav",
		"npc/barnacle/barnacle_pull2.wav",
		"npc/barnacle/barnacle_pull3.wav",
		"npc/barnacle/barnacle_pull4.wav"
	}
	
	self.tauntSounds = {
		"npc/barnacle/barnacle_digesting1.wav",
		"npc/barnacle/barnacle_digesting2.wav"
	}
	
	self.attackSounds = {
		"npc/barnacle/barnacle_pull1.wav",
		"npc/barnacle/barnacle_pull2.wav",
		"npc/barnacle/barnacle_pull3.wav",
		"npc/barnacle/barnacle_pull4.wav"
	}
end

function ENT:FindDoor()
	local position = self:GetPos() + Vector(0, 0, 25)
	local doors = {}
	doors = table.Add(doors, ents.FindByClass("func_door"))
	doors = table.Add(doors, ents.FindByClass("func_door_rotating"))
	doors = table.Add(doors, ents.FindByClass("prop_door_rotating"))
	
	for k, v in pairs(doors) do
		if v:GetPos():Distance(position) < 80 then
			return v
		end
	end
	
	return NULL
end

function ENT:Think()
	if self.nextIdle < CurTime() then
		self:PlayVoiceSound(self.tauntSounds)
		self.nextIdle = CurTime() + math.random(15, 25)
	end
	
	if not self.attack and self.nextDoorFind + 4 < CurTime() then
		local door = self:FindDoor()
		
		if IsValid(door) then
			door:Fire("open", "", 0.1)
			
			-- YARRRR.
			self:PlayVoiceSound(self.tauntSounds)
			self.nextIdle = CurTime() + math.random(15, 25)
		end
		
		self.nextDoorFind = CurTime()
	end
	
	if self.attack and self.attackTime + self.nextAttack < CurTime() then
		local enemy = self:GetEnemy()

		if enemy and enemy:IsValid() and enemy:GetPos():Distance(self:GetPos()) < 64 then
			local effect = EffectData()
				effect:SetOrigin(enemy:GetPos() +Vector(0, 0, 40))
				effect:SetScale(4)
			util.Effect("BloodImpact", effect, true, true)
		
			enemy:TakeDamage(self.damage, self)
			self:EmitSound(Sound("npc/antlion_grub/squashed.wav"), 100, math.random(90, 110))
		end
		
		self.attack = false
		self.attackTime = CurTime()
	end
	
	if self.isMoving and self.moveTime < CurTime() then
		local sound = self:PlayVoiceSound(self.moveSounds)
		self.moveTime = CurTime() +SoundDuration(sound) +math.random(0.5, 1)
	end
end

function ENT:SelectSchedule()
	local enemy = self:GetEnemy()
	local sched = SCHED_IDLE_STAND
	
	if enemy and enemy:IsValid() then
		local melee = self:HasCondition(23)
		
		if melee and not self.attack then 
			sched = SCHED_MELEE_ATTACK1
			
			self.isMoving = false
			self.attack = true
		else
			sched = SCHED_CHASE_ENEMY
			
			self.isMoving = true
			self.attack = false
		end
	else
		self:UpdateEnemy(self:FindEnemy())
	end
	
	self:SetSchedule(sched)
end