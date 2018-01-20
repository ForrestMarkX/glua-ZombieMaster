NPC.HullType = HULL_HUMAN
NPC.SolidType = SOLID_BBOX
NPC.MoveType = MOVETYPE_STEP
NPC.BloodColor = BLOOD_COLOR_RED

NPC.SpawnFlags = bit.bor(SF_NPC_ALWAYSTHINK, SF_NPC_LONG_RANGE)
NPC.Capabilities = bit.bor(CAP_FRIENDLY_DMG_IMMUNE, CAP_MOVE_GROUND, CAP_INNATE_MELEE_ATTACK1, CAP_SKIP_NAV_GROUND_CHECK)

function NPC:OnSpawned(npc)
	npc:SetBloodColor(self.BloodColor)
	
	self:SetupCapabilities(npc)
	
	if self.HullType then
		npc:SetHullType(self.HullType)
	end
	
	if self.HullSizeMins and self.HullSizeMaxs then
		timer.Simple(0.1, function()
			if not IsValid(npc) then return end
			npc:SetCollisionBounds(self.HullSizeMins, self.HullSizeMaxs)
		end)
	end
	
	if self.IsEngineNPC ~= nil then 
		npc.IsEngineNPC = self.IsEngineNPC 
	end 
  
	npc.NextBreakableScan = CurTime()
	
	npc:SetSolid(self.SolidType)
	npc:SetMoveType(self.MoveType)
	npc:SetNW2Bool("selected", false)
	
	if self.Health and self.Health ~= 0 then
		npc:SetHealth(self.Health)
	end
	
	if self.MaxYawSpeed then
		npc:SetMaxYawSpeed(self.MaxYawSpeed)
	end

	timer.Simple(1, function()
		if not IsValid(npc) then return end
		npc:UpdateEnemy(npc:FindEnemy())
	end)
end

function NPC:SetupCapabilities(npc)
	if not self.Capabilities then return end
	
	npc:CapabilitiesClear()
	npc:CapabilitiesAdd(self.Capabilities)
end

function NPC:OnScaledDamage(npc, hitgroup, dmginfo)
	local damagetype = dmginfo:GetDamageType()
	if damagetype ~= DMG_CLUB then
		if hitgroup == HITGROUP_HEAD then
			if bit.band(damagetype, DMG_BUCKSHOT) ~= 0 then
				local flDist = 1024
				if IsValid(dmginfo:GetAttacker()) then
					flDist = (npc:GetPos() - dmginfo:GetAttacker():GetPos()):Length()
				end

				if flDist <= ZOMBIE_BUCKSHOT_TRIPLE_DAMAGE_DIST then
					dmginfo:ScaleDamage(3)
				end
			else
				dmginfo:ScaleDamage(2)
			end
		elseif hitgroup == HITGROUP_LEFTARM or hitgroup == HITGROUP_RIGHTARM or hitgroup == HITGROUP_LEFTLEG or hitgroup == HITGROUP_RIGHTLEG or hitgroup == HITGROUP_GEAR then
			dmginfo:ScaleDamage(0.25)
		end
	end
end

function NPC:OnTakeDamage(npc, attacker, inflictor, dmginfo)
	local damage = dmginfo:GetDamage()
	if damage > 0 and bit.band(dmginfo:GetDamageType(), DMG_BULLET) ~= 0 then
		local effect = EffectData()
			effect:SetOrigin(dmginfo:GetDamagePosition())
			effect:SetMagnitude(math.Rand(damage * 0.25, damage * 0.6))
			effect:SetScale(math.max(128, math.Rand(damage, damage * 4)))
		util.Effect("bloodstream", effect)
	end
	
	if IsValid(attacker) then
		local entteam = attacker.OwnerTeam
		if IsValid(attacker) and attacker:GetClass() == "env_fire" and entteam == TEAM_ZOMBIEMASTER then
			dmginfo:SetDamageType(DMG_BULLET)
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
	
	if npc.IsEngineNPC then
		npc:SetModel(npc.CurrentModel)
	else
		net.Start("zm_spawnclientragdoll")
			net.WriteEntity(npc)
		net.Broadcast()
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
					
					timer.Simple(0.25, function()
						npc:SetSchedule(SCHED_MELEE_ATTACK1)
						
						if not npc.IsEngineNPC then
							npc.IsAttacking = true
							
							local len = npc:SequenceDuration()
							timer.Simple(len, function()
								if not IsValid(npc) or not IsValid(npc.BreakableEnt) then return end
								npc.BreakableEnt:TakeDamage(npc.AttackDamage, npc, npc)
							end)
						end
					end)
				end
			end
		end
		
		npc.NextBreakableScan = CurTime() + 5.0
	end
	
	if npc.InDefenceMode and npc.NextDefenceCheck and CurTime() >= npc.NextDefenceCheck then
		if npc:GetPos():Distance(npc.DefencePoint or npc:GetPos()) > 512 then
			npc:SetEnemy(NULL)
			npc:SetSchedule(SCHED_AMBUSH)
			npc:SetCondition(COND_ENEMY_UNREACHABLE)
			npc:ForceGo(npc.DefencePoint or npc:GetPos())
		end
		
		npc.NextDefenceCheck = CurTime() + 1.0
	end
end