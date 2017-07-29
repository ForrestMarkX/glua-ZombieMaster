AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

ENT.m_iClass 		= CLASS_ZOMBIE
ENT.m_fMaxYawSpeed  = 20
ENT.ClawHitSounds 	= "Zombie.AttackHit"
ENT.ClawMissSounds 	= "Zombie.AttackMiss"
ENT.AlertSounds		= "Zombie.Alert"
ENT.DoorHitSound	= "npc/zombie/zombie_hit.wav"
ENT.NextIdleMoan 	= CurTime()
ENT.MoveSounds 		= {
	"Zombie.FootstepRight",
	"Zombie.ScuffRight"
}
ENT.AttackDamage	= 13
ENT.AttackRange		= 70
ENT.NextSwatScan 	= CurTime()
ENT.CanSwatPhysicsObjects = true
ENT.FootStepTime 	= 0.3
ENT.MoveTime		= CurTime()
ENT.NextBreakableScan = CurTime()
ENT.DamageType      = DMG_SLASH

CreateConVar("zm_zombieswatforcemin", "20000", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Specifies the min force that a zombie can apply to a prop when swatting it.")
CreateConVar("zm_zombieswatforcemax", "70000", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Specifies the max force that a zombie can apply to a prop when swatting it.")
CreateConVar("zm_zombieswatlift", "20000", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Specifies the amount of lift that is applied to swatted props.")

function ENT:MeleeAttack1Conditions(flDot, flDist)
	if flDist > self:GetClawAttackRange() then
		self:SetCondition(COND_TOO_FAR_TO_ATTACK)
		return false
	end

	if flDot < 0.7 then
		self:SetCondition(COND_NOT_FACING_ATTACK)
		return false
	end

	local vecMins = self:OBBMins()
	local vecMaxs = self:OBBMaxs()
	vecMins.z = vecMins.x
	vecMaxs.z = vecMaxs.x

	local forward = self:GetAngles():Forward()
	local tr = util.TraceHull({
		start = self:WorldSpaceCenter(),
		endpos = self:WorldSpaceCenter() + forward * self:GetClawAttackRange(),
		filter = self,
		mins = vecMins,
		maxs = vecMaxs,
		mask = MASK_NPCSOLID
	})
	if tr.fraction == 1.0 or not IsValid(tr.Entity) then
		self:SetCondition(COND_TOO_FAR_TO_ATTACK)
		return false
	end

	if tr.Entity == self:GetEnemy() or tr.Entity:IsNPC() then
		self:SetCondition(COND_CAN_MELEE_ATTACK1)
		return true
	end

	if tr.Entity:IsWorld() then
		local vecToEnemy = self:GetEnemy():WorldSpaceCenter() - self:WorldSpaceCenter()
		local vecTrace = tr.endpos - tr.startpos

		if vecTrace:Length2DSqr() < vecToEnemy:Length2DSqr() then
			//self:SetCondition(COND_ZOMBIE_LOCAL_MELEE_OBSTRUCTION)
			return true
		end
	end

	self:SetCondition(COND_TOO_FAR_TO_ATTACK)
	return false
end

function ENT:PlayVoiceSound(sounds)
	local output
	local soundType = type(sounds)
	
	if soundType == "table" then
		local random = sounds[math.random(#sounds)]
	
		output = random
		self:EmitSound(random)
	elseif (soundType == "string") then
		output = sounds
		self:EmitSound(sounds)
	end
	
	return output
end

function ENT:GetRelationship(ent)
	if self.PendingRemove then
		return D_LI
	elseif ent:IsNPC() and ent:Classify() == self.m_iClass then
		return D_LI
	elseif ent:IsPlayer() and ent:IsSurvivor() then
		return D_HT
	end
	
	return D_NU
end

function ENT:OnDeath(killer, inflictor)
	gamemode.Call("OnNPCKilled", self, killer, inflictor)
	self:PlayVoiceSound(self.DeathSounds)
	
	self:SetSchedule(SCHED_FALL_TO_GROUND)
	self:Remove()
end

function ENT:OnTakeDamage(dmginfo)
	local attacker, inflictor = dmginfo:GetAttacker() or self, dmginfo:GetInflictor() or self
	if GAMEMODE:CallZombieFunction(self, "OnTakeDamage", attacker, inflictor, dmginfo) then return true end
	
	local damage = dmginfo:GetDamage()
	self:SetHealth(self:Health() - damage)
	
	if damage > 0 and not self:IsOnFire() then
		self:SpawnBloodEffect(dmginfo:GetDamagePosition(), damage)
		
		if self:Health() > 0 then
			self:PlayVoiceSound(self.PainSounds)
		end
	end
	
	if self:Health() <= 0 then
		timer.Simple(0, function() 
			if not IsValid(self) then return end 
			self:OnDeath(attacker, inflictor) 
		end)
	end
end

function ENT:SpawnBloodEffect(pos, damage)
	local effect = EffectData()
		effect:SetOrigin(pos)
		effect:SetScale(4)
		effect:SetEntity(self)
		effect:SetColor(self:GetBloodColor())
	util.Effect("BloodImpact", effect, true, true)	
	
	local effect = EffectData()
		effect:SetOrigin(pos)
		effect:SetScale(6)
		effect:SetEntity(self)
		effect:SetColor(self:GetBloodColor())
		effect:SetFlags(3)
	util.Effect("bloodspray", effect, true, true)
end

function ENT:PlayAttackSequence()
	self:SetSchedule(SCHED_MELEE_ATTACK1)
	
	if self.AttackSounds then
		self:PlayVoiceSound(self.AttackSounds)
	end
	
	local len = self:SequenceDuration()
	self.AttackEnd = CurTime() + len
	self.AttackTime = CurTime() + (len * 0.55)
end

function ENT:SelectSchedule()
	if self:HasCondition(COND_LIGHT_DAMAGE) then
		self:SetSchedule(SCHED_SMALL_FLINCH)
	elseif self:HasCondition(COND_HEAVY_DAMAGE) then
		self:SetSchedule(SCHED_BIG_FLINCH)
	elseif self:HasCondition(COND_PHYSICS_DAMAGE) then
		self:SetSchedule(SCHED_FLINCH_PHYSICS)
	end
	
	if self:HasCondition(COND_RECEIVED_ORDERS) then
		self.FoundBreakable = false
		self.BreakableEnt = nil
		self.NextBreakableScan = CurTime() + 5.0
	end
	
	local enemy = self:GetEnemy()
	if IsValid(enemy) then
		local melee = self:MeleeAttack1Conditions(self:GetPos():Dot(enemy:GetPos()), self:GetPos():Distance(enemy:GetPos())) or self:HasCondition(COND_CAN_MELEE_ATTACK1)
		if melee and not self.IsAttacking then 
			self.IsAttacking = true
			self:PlayAttackSequence()
		else
			self:SetSchedule(SCHED_CHASE_ENEMY)
			self.IsAttacking = false
		end
	else
		self:UpdateEnemy(self:FindEnemy())
	end
	
	--self:SetSchedule(SCHED_IDLE_WANDER)
end

function ENT:CalculateMeleeDamageForce(info, vecMeleeDir, vecForceOrigin, flScale)
	info:SetDamagePosition(vecForceOrigin)
	
	local flForceScale = info:GetBaseDamage() * (75 * 4)
	local vecForce = vecMeleeDir
	vecForce:Normalize()
	
	vecForce = vecForce * flForceScale;
	vecForce = vecForce * GetConVar("phys_pushscale"):GetFloat()
	
	if flScale then
		vecForce = vecForce * flScale
	end
	
	info:SetDamageForce(vecForce)
end

function ENT:CheckTraceHullAttack(vStart, vEnd, mins, maxs, iDamage, iDmgType, flForceScale, bDamageAnyNPC)
	local dmgInfo = DamageInfo()
	dmgInfo:SetAttacker(self)
	dmgInfo:SetInflictor(self)
	dmgInfo:SetDamage(iDamage)
	dmgInfo:SetDamageType(iDmgType)
	
	local tr = util.TraceHull({
		start = vStart,
		endpos = vEnd,
		filter = self,
		mins = mins,
		maxs = maxs,
		mask = MASK_SHOT_HULL
	})
	local pEntity = tr.Entity
	if not IsValid(pEntity) or (pEntity:IsPlayer() and not pEntity:Alive()) then
		return NULL
	end

	// Must hate the hit entity
	if self:GetRelationship(pEntity) == D_HT then
		if iDamage > 0 then
			self:CalculateMeleeDamageForce(dmgInfo, (vEnd - vStart), vStart, flForceScale)
			pEntity:TakeDamageInfo(dmgInfo)
			
			if bit.band(iDmgType, DMG_BURN) ~= 0 then
				pEntity:Ignite(2)
			end
		end
	end
	
	return pEntity
end

function ENT:ClawAttack(flDist, iDamage, qaViewPunch, vecVelocityPunch)
	local iDamageType = self.DamageType
	
	if self:IsOnFire() then
		iDamage = iDamage * (math.Rand(1, 2))
		iDamageType = DMG_BURN
	end

	if IsValid(self:GetEnemy()) then
		local tr = util.TraceHull({
			start = self:WorldSpaceCenter(),
			endpos = self:GetEnemy():WorldSpaceCenter(),
			filter = self,
			mins = -Vector(8,8,8),
			maxs = Vector(8,8,8),
			mask = MASK_SOLID_BRUSHONLY
		})
		
		if tr.Fraction < 1 then
			return NULL
		end
	end

	local vecMins = self:OBBMins()
	local vecMaxs = self:OBBMaxs()
	vecMins.z = vecMins.x
	vecMaxs.z = vecMaxs.x

	local pHurt = self:CheckTraceHullAttack(self:EyePos(), self:EyePos() + self:EyeAngles():Forward() * flDist, vecMins, vecMaxs, iDamage, iDamageType)
	if IsValid(pHurt) then
		self:PlayVoiceSound(self.ClawHitSounds)

		local pPlayer = pHurt
		if pPlayer ~= NULL and pPlayer:IsPlayer() and not pPlayer:IsFlagSet(FL_GODMODE) then
			pPlayer:ViewPunch(qaViewPunch)
			pPlayer:SetVelocity(pPlayer:GetVelocity() + vecVelocityPunch)
			
			local flNoise = 6.0
			local traceHit

			for i=0, 6 do
				local vecTraceDir
				
				if math.random(0, 10) == 5 then
					vecTraceDir = pPlayer:EyePos()
					vecTraceDir.z = vecTraceDir.z - math.Rand(-flNoise, 0.0)
				else
					local dir = pPlayer:GetPos() - self:GetPos()
					dir:Normalize()

					local angles = dir:Angle()
					local forward = angles:Forward()

					vecTraceDir = self:WorldSpaceCenter() + (forward * 128 )

					vecTraceDir.x = vecTraceDir.x + math.Rand(-flNoise, flNoise)
					vecTraceDir.y = vecTraceDir.y + math.Rand(-flNoise, flNoise)
					vecTraceDir.z = vecTraceDir.z + math.Rand(-flNoise, flNoise + 10.0)
				end

				traceHit = util.TraceLine({
					start = self:WorldSpaceCenter(),
					endpos = vecTraceDir,
					filter = self,
					mask = MASK_SHOT_HULL
				})
				
				local effect = EffectData()
					effect:SetOrigin(traceHit.HitPos + Vector(0, 0, 40))
					effect:SetScale(2)
				util.Effect("BloodImpact", effect, true, true)
			end
		end
	else 
		self:PlayVoiceSound(self.ClawMissSounds)
	end

	return pHurt
end

function ENT:FindNearestPhysicsObject()
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
			return entity
		end
	end
end

function ENT:SwatObject(pPhysObj, direction)
	local targetmass = pPhysObj:GetMass()
	local liftforce = math.Remap(targetmass, 5, 350, 3000, GetConVar("zm_zombieswatlift"):GetFloat())
	local uplift = Vector(0, 0, liftforce)
	local swatforce = math.Remap(targetmass, 5, 500, GetConVar("zm_zombieswatforcemin"):GetFloat(), GetConVar("zm_zombieswatforcemax"):GetFloat())
	
	pPhysObj:ApplyForceCenter(direction * swatforce + uplift)
	self.ePhysicsEnt = nil
end

function ENT:GetClawAttackRange()
	return self.AttackRange
end

function ENT:PerformAttack()
	if self.IsAttacking then
		local forward = self:GetAngles():Forward()
		local qaPunch = Angle(45, math.random(-5,5), math.random(-5,5))
		
		forward = forward * 200
		
		self:ClawAttack(self:GetClawAttackRange(), self.AttackDamage, qaPunch, forward)
	elseif self.bPlayingSwatSeq then
		local swat_ent = self.ePhysicsEnt
		if IsValid(self.ePhysicsEnt) then
			local phys = self.ePhysicsEnt:GetPhysicsObject()
			if IsValid(phys) then
				self:PlayVoiceSound(self.DoorHitSound)
				
				if self.ePhysicsEnt:GetClass() == "func_breakable" then
					self.ePhysicsEnt:TakeDamage(self.AttackDamage, self, self)
					self.bPlayingSwatSeq = false
					return 
				end

				local physicsCenter = self:LocalToWorld(phys:GetMassCenter())
				
				if not IsValid(self:GetEnemy()) then 
					self.bPlayingSwatSeq = false
					return 
				end
				
				local v = self:GetEnemy():WorldSpaceCenter() - physicsCenter
				v:Normalize()
				
				self:SwatObject(phys, v)
			end
		end
		
		self.bPlayingSwatSeq = false
	end
end

function ENT:PerformSwatScan()
	local swatent = self:FindNearestPhysicsObject()
	if IsValid(swatent) then
		local enemy = self:GetEnemy()
		if IsValid(enemy) then
			self.bPlayingSwatSeq = true
			self.ePhysicsEnt = swatent
			
			if not self.IsSwatting then
				self:PlayAttackSequence()
				self.IsSwatting = true
			end
		end
	else
		self.ePhysicsEnt = nil
	end
end

function ENT:PerformAttackEnd()
	self.IsAttacking = false
	self.IsSwatting = false
end

function ENT:Think()
	if self.NextIdleMoan < CurTime() then
		self:PlayVoiceSound(self.MoanSounds)
		self.NextIdleMoan = CurTime() + math.random(15, 25)
	end
	
	if not self.IsAttacking and CurTime() >= self.NextSwatScan then
		self:PerformSwatScan()
		self.NextSwatScan = CurTime() + math.random(5, 15)
	end
	
	if self.IsAttacking or self.bPlayingSwatSeq then
		if self.AttackTime and self.AttackTime < CurTime() then
			self:PerformAttack()
			self.AttackTime = nil
		end
		
		if self.AttackEnd and self.AttackEnd < CurTime() then
			self:PerformAttackEnd()
		end
	end

	if self:IsMoving() and self:IsOnGround() and self:GetGroundEntity() ~= nil then
		if self.MoveTime < CurTime() then
			self:PlayVoiceSound(self.MoveSounds)
			self.MoveTime = CurTime() + self.FootStepTime
		end
	end
	
	if self.CustomThink then
		self:CustomThink()
	end
end

function ENT:Classify()
	return CLASS_ZOMBIE
end