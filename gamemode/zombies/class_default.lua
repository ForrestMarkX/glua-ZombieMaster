NPC.Class = ""
NPC.Name = ""
NPC.Description = ""
NPC.Icon = ""
NPC.Flag = 0
NPC.Cost = 0
NPC.PopCost = 0
NPC.SortIndex = 0

NPC.Hidden = true
NPC.DelaySetModel = false
NPC.IsEngineNPC = true

NPC.Health = 0
NPC.Model = "models/zombie/zm_classic.mdl"
NPC.HullType = HULL_HUMAN
NPC.SolidType = SOLID_BBOX
NPC.MoveType = MOVETYPE_STEP
NPC.SkinNum = 3
NPC.BloodColor = BLOOD_COLOR_RED
NPC.DieSound = ""

if SERVER then
	NPC.SpawnFlags = bit.bor(SF_NPC_LONG_RANGE, SF_NPC_FADE_CORPSE, SF_NPC_ALWAYSTHINK, SF_NPC_NO_PLAYER_PUSHAWAY)
	NPC.Capabilities = bit.bor(CAP_MOVE_GROUND, CAP_INNATE_MELEE_ATTACK1, CAP_SQUAD, CAP_SKIP_NAV_GROUND_CHECK)
end

function NPC:OnSpawned(npc)
	npc:SetBloodColor(self.BloodColor)
	
	if self.Capabilities then
		npc:CapabilitiesClear()
		npc:CapabilitiesAdd(self.Capabilities)
	end
	
	if self.HullType then
		npc:SetHullType(self.HullType)
	end
	
	if self.HullSizeMins and self.HullSizeMaxs then
		npc:SetCollisionBounds(self.HullSizeMins, self.HullSizeMaxs)
	end
	
	if (self.SkinNum or 0) > 0 then
		npc:SetSkin(math.random(0, self.SkinNum))
	end
	
	npc.IsEngineNPC = self.IsEngineNPC
	npc.NextBreakableScan = CurTime()
	
	npc:SetSolid(self.SolidType)
	npc:SetMoveType(self.MoveType)
	npc:SetNW2Bool("selected", false)
	npc:SetNW2Bool("bDead", false)
	
	if self.Health and self.Health ~= 0 then
		npc:SetHealth(self.Health)
	end
	
	if self.MaxYawSpeed then
		npc:SetMaxYawSpeed(self.MaxYawSpeed)
	end
	
	npc:SetHullSizeNormal()

	npc:UpdateEnemy(npc:FindEnemy())
end

function NPC:SetupModel(npc)
	if not self.Model then return end
	
	local mdl = ""
	if type(self.Model) == "table" then
		mdl = self.Model[math.random(#self.Model)]
	else
		mdl = self.Model
	end
	
	if self.DelaySetModel then
		npc:SetModelDelayed(0, mdl)
	else
		npc:SetModel(mdl)
	end
end

function NPC:OnScaledDamage(npc, hitgroup, dmginfo)
	local damagetype = dmginfo:GetDamageType()
	if damagetype ~= DMG_CLUB then
		if hitgroup == HITGROUP_HEAD and bit.band(damagetype, DMG_BUCKSHOT) == 0 then
			dmginfo:ScaleDamage(1.25)
		elseif hitgroup == HITGROUP_LEFTLEG or hitgroup == HITGROUP_RIGHTLEG then
			dmginfo:ScaleDamage(0.25)
		end
	end
end

function NPC:OnTakeDamage(npc, attacker, inflictor, dmginfo)
	if npc.Dead then
		npc:Extinguish()
		dmginfo:SetDamageType(DMG_GENERIC)
		dmginfo:SetDamage(0)
		dmginfo:ScaleDamage(0)
		return true
	end
	
	local damage = dmginfo:GetDamage()
	if damage > 0 and bit.band(dmginfo:GetDamageType(), DMG_BULLET) ~= 0 then
		local effect = EffectData()
			effect:SetOrigin(dmginfo:GetDamagePosition())
			effect:SetMagnitude(math.Rand(damage * 0.25, damage * 0.6))
			effect:SetScale(math.max(128, math.Rand(damage, damage * 4)))
		util.Effect("bloodstream", effect)
	end
		
	if npc:Health() <= damage then
		npc:SetEnemy(NULL)
		npc:SetNotSolid(true)
		npc:SetKeyValue("spawnflags", bit.bor(SF_NPC_GAG, SF_NPC_START_EFFICIENT))
		npc:SetSchedule(SCHED_NPC_FREEZE)
		npc:CapabilitiesClear()
		npc:Extinguish()
		npc:SetNW2Bool("bDead", true)
		
		npc:EmitSound(self.DieSound)
		
		SafeRemoveEntityDelayed(npc, 5)
		self:OnKilled(npc, attacker, inflictor)
		
		dmginfo:SetDamageType(DMG_GENERIC)
		dmginfo:SetDamage(0)
		dmginfo:ScaleDamage(0)
		return true
	end
	
	if IsValid(attacker) then
		local atkowner = attacker:GetOwner()
		if IsValid(attacker) and attacker:GetClass() == "env_fire" and IsValid(atkowner) and atkowner:GetClass() == "npc_burnzombie" then
			dmginfo:SetDamageType(DMG_GENERIC)
			dmginfo:SetDamage(0)
			dmginfo:ScaleDamage(0)
			return true
		end
		
		if not IsValid(npc:GetEnemy()) and attacker:IsPlayer() then
			if npc.UpdateEnemy then
				npc:UpdateEnemy(attacker)
			else
				npc:SetEnemy(attacker)
				npc:SetTarget(attacker)
			end
		end
	end
end

function NPC:OnKilled(npc, attacker, inflictor)
	local owner = npc:GetOwner()
	if IsValid(owner) and owner:IsPlayer() then
		local popCost = self.PopCost
		local population = GAMEMODE:GetCurZombiePop()

		popCost = popCost or 1

		GAMEMODE:TakeCurZombiePop(popCost)
	end
	
	net.Start("zm_spawnclientragdoll")
		net.WriteEntity(npc)
	net.Broadcast()
	
	if npc.OnDeath then
		npc:OnDeath(attacker)
	end
	
	if IsValid(attacker) and attacker:IsPlayer() then
		attacker:AddFrags(1)
	end
end

function NPC:Think(npc)
	if npc:HasCondition(COND_RECEIVED_ORDERS) then
		npc.FoundBreakable = false
		npc.BreakableEnt = nil
		npc.NextBreakableScan = CurTime() + 5.0
	end
	
	if (npc.NextBreakableScan and CurTime() >= npc.NextBreakableScan) or npc.FoundBreakable then
		local enemy = npc:GetEnemy()
		if not (IsValid(enemy) and enemy:IsPlayer()) then
			if not IsValid(npc.BreakableEnt) then
				for _, ent in pairs(ents.FindInSphere(npc:WorldSpaceCenter(), 64)) do
					if string.sub(ent:GetClass(), 0, 5) == "func_" then
						if ent:Health() > 0 and not ent:IsNPC() and not ent:IsPlayer() then
							npc.BreakableEnt = ent
							npc.FoundBreakable = true
							npc:UpdateEnemy(ent)
							break
						end
					end
				end
				
				if not IsValid(npc.BreakableEnt) and npc.FoundBreakable then
					npc.FoundBreakable = false
				end
			else
				if npc:GetPos():Distance(npc.BreakableEnt:GetPos()) < (npc.GetClawAttackRange and npc:GetClawAttackRange() or 72) and not npc:IsCurrentSchedule(SCHED_MELEE_ATTACK1) then
					npc:SetEnemy(npc.BreakableEnt)
					npc:SetTarget(npc.BreakableEnt)
					npc:SetSchedule(SCHED_TARGET_FACE)
					npc:SetSchedule(SCHED_MELEE_ATTACK1)
					
					if not self.IsEngineNPC then
						npc.IsAttacking = true
						
						local seq = npc:SelectWeightedSequence(ACT_MELEE_ATTACK1)
						local len = npc:SequenceDuration(seq)
						timer.Simple(len, function()
							if not IsValid(npc) or not IsValid(npc.BreakableEnt) then return end
							npc.BreakableEnt:TakeDamage(npc.AttackDamage, npc, npc)
						end)
					end
				end
			end
		end
		
		npc.NextBreakableScan = CurTime() + 5.0
	end
	
	if npc.InDefenceMode and npc.NextDefenceCheck and CurTime() >= npc.NextDefenceCheck then
		if npc:GetPos():Distance(npc.AmbushPoint or npc:GetPos()) > 512 then
			npc:SetEnemy(NULL)
			npc:SetSchedule(SCHED_AMBUSH)
			npc:SetCondition(COND_ENEMY_UNREACHABLE)
			npc:ForceGo(npc.AmbushPoint or npc:GetPos())
		end
		
		npc.NextDefenceCheck = CurTime() + 1.0
	end
end