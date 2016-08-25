-- VST base from Vestige

AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

ENT.clawHitSounds = {
	"npc/zombie/claw_strike1.wav",
	"npc/zombie/claw_strike2.wav",
	"npc/zombie/claw_strike3.wav"
}

ENT.clawMissSounds = {
	"npc/zombie/claw_miss1.wav",
	"npc/zombie/claw_miss2.wav"
}

ENT.doorHitSound	= "npc/zombie/zombie_hit.wav"
ENT.nextIdle 	= 0
--ENT.DoorTime 	= 0
--ENT.VoiceTime 	= 0
ENT.moveTime 	= 0
ENT.sRagdoll 	= true
ENT.isZombie	= true
ENT.attackTime = CurTime()
--ENT.damagers = {}

ENT.moveSounds = {
	"npc/zombie/foot1.wav",
	"npc/zombie/foot2.wav",
	"npc/zombie/foot3.wav"
}

function ENT:Initialize()
	self:SetModel("models/zombie/zm_classic.mdl")
	
	self:SetHullSizeNormal()
	self:SetHullType(HULL_HUMAN)
	
	self:SetSolid(SOLID_BBOX)
	self:SetMoveType(MOVETYPE_STEP)
	self:CapabilitiesAdd(bit.bor(CAP_MOVE_GROUND, CAP_INNATE_MELEE_ATTACK1))
	
	self:SetMaxYawSpeed(5000)
	self:SetHealth(100)
	
	self:SetDamageForce(0)
	
	self:DropToFloor()

	self:UpdateEnemy(self:FindEnemy())
	self:SetSchedule(SCHED_IDLE_STAND)
end

function ENT:PlayVoiceSound(sounds)
	local output
	local soundType = type(sounds)
	
	if soundType == "table" then
		local random = table.Random(sounds)
	
		output = random
		self:EmitSound(random, 100, math.random(90, 100))
	elseif (soundType == "string") then
		output = sounds
		self:EmitSound(sounds, 100, math.random(90, 100))
	end
	
	return output
end

function ENT:Death(killer)
	gamemode.Call("OnNPCKilled", self, killer, killer)
	self:PlayVoiceSound(self.deathSounds)
	
	self:SetSchedule(SCHED_FALL_TO_GROUND)
	self:Remove()
end

function ENT:OnTakeDamage(dmginfo)
	local attacker, inflictor = dmginfo:GetAttacker(), dmginfo:GetInflictor()
	if GAMEMODE:CallZombieFunction(self:GetClass(), "OnTakeDamage", self, attacker, inflictor, dmginfo) then return true end
	
	local damage = dmginfo:GetDamage()
	local position = dmginfo:GetDamagePosition()
	
	if not position then
		position = self:GetPos() + Vector(0, 0, 50)
	end
	
	local effect = EffectData()
		effect:SetOrigin(position)
		effect:SetScale(4)
	util.Effect("BloodImpact", effect, true, true)
	
	self:SetHealth(math.Clamp(self:Health() - damage, 0, 100))

	if self:Health() <= 0 then
		local killer = dmginfo:GetAttacker()	
		if killer:IsPlayer() and killer:IsSurvivor() then
			self:SetDamageForce((self:NearestPoint(killer:EyePos()) - killer:EyePos():GetNormalized()) * math.Clamp(damage * 3, 40, 300))
		end
		
		timer.Simple(0, function() self:Death(killer) end)
	end
	
	if damage > 0 then
		self:PlayVoiceSound(self.painSounds)
	end

	return true
end

function ENT:FindEnemy()
	if team.NumPlayers(TEAM_SURVIVOR) < 1 then
		return NULL
	else
		local players = team.GetPlayers(TEAM_SURVIVOR)
		local enemy = table.Random(players)
		local distance = 2048
		
		for k, v in pairs(players) do
			local compare = v:GetPos():Distance(self:GetPos())
			
			if (compare < distance and v:Alive()) then
				enemy = v
				distance = compare
			end
		end
		
		return enemy
	end
end

function ENT:UpdateEnemy(enemy)
	if enemy and enemy:IsValid() and enemy:Alive() and enemy:IsSurvivor() then
		self:SetEnemy(enemy, true)
		self:UpdateEnemyMemory(enemy, enemy:GetPos())
	else
		self:SetEnemy(NULL)
	end
end

function ENT:Think()
	if self.nextIdle < CurTime() then
		self:PlayVoiceSound(self.tauntSounds)
		self.nextIdle = CurTime() + math.random(15, 25)
	end
	
	if not self.attack and self.nextPhysics and self.nextPhysics < CurTime() then
		local entity = NULL
		local entities = ents.GetAll()
		
		for k, v in pairs(entities) do
			local class = v:GetClass()
			
			if (string.find(class, "prop_physics*") or class == "func_breakable") then
				if (self:GetPos() + Vector(0, 0, 25)):Distance(v:GetPos()) < 70 then
					entity = v
					break
				end
			end
		end

		if IsValid(entity) then
			local trace = {}
			trace.start = self:GetPos()
			trace.endpos = entity:GetPos()
			trace.filter = {self}
			
			local tr = util.TraceLine(trace)
			
			if not tr.HitWorld then
				local angles = (entity:GetPos() - self:GetPos()):Angle()
				
				self:ResetSequence(8)
				self:SetAngles(Angle(0, angles.y, 0))

				self.isMoving = false
				
				local class = entity:GetClass()
				
				if string.find(class, "prop_physics*") then
					local normal = (entity:GetPos() - self:GetPos()):GetNormalized()
					local velocity = 10000 * normal
					local physics = entity:GetPhysicsObject()
					
					if IsValid(physics) then
						physics:ApplyForceOffset(velocity, entity:GetPos())
					else
						physics:SetVelocity(velocity)
					end
				elseif class == "func_breakable" then
					entity:Fire("Break", "", 0.1)
				end
				
				self:PlayVoiceSound(self.doorHitSound)
			end
		end
		
		self.nextPhysics = CurTime() + 5
	end
	
	if self.attack and self.attackTime + self.nextAttack < CurTime() then
		local enemy = self:GetEnemy()
		local distance = self.hitDistance or 70
		
		if IsValid(enemy) and enemy:GetPos():Distance(self:GetPos()) < distance then
			local effect = EffectData()
				effect:SetOrigin(enemy:GetPos() + Vector(0, 0, 40))
				effect:SetScale(2)
			util.Effect("BloodImpact", effect, true, true)
		
			enemy:TakeDamage(self.damage, self)
			
			self:PlayVoiceSound(self.clawHitSounds)
		else
			self:PlayVoiceSound(self.clawMissSounds)
		end
		
		self.attack = false
		self.attackTime = CurTime()
	end
	
	if self.isMoving and self.moveTime < CurTime() then
		local sound = self:PlayVoiceSound(self.moveSounds)
		self.moveTime = CurTime() + SoundDuration(sound) + math.random(0.5, 1)
	end
	
	if self.CustomThink then
		self:CustomThink()
	end
end

function ENT:GetRelationship(entity)
	if entity:IsValid() and entity:IsPlayer() and entity:IsSurvivor() then
		return D_HT
	end
	
	return D_LI
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
			
			if self.attackSounds then
				self:PlayVoiceSound(self.attackSounds)
			end
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

function ENT:Classify()
	return CLASS_ZOMBIE
end