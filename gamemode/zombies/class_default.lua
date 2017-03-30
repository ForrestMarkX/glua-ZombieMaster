NPC.Class = ""
NPC.Name = ""
NPC.Description = ""
NPC.Icon = ""
NPC.Flag = 0
NPC.Cost = 0
NPC.PopCost = 0
NPC.SortIndex = 0

NPC.Hidden = true

NPC.Health = 0
NPC.Model = {}

if SERVER then
	NPC.SpawnFlags = SF_NPC_LONG_RANGE + SF_NPC_FADE_CORPSE + SF_NPC_ALWAYSTHINK + SF_NPC_NO_PLAYER_PUSHAWAY
	NPC.Capabilities = nil

	NPC.Friends = {"npc_zombie", "npc_poisonzombie", "npc_burnzombie", "npc_dragzombie"}
end

function NPC:OnSpawned(npc)
	npc:SetBloodColor(BLOOD_COLOR_RED)
	
	npc:SetKeyValue("wakeradius", 32768)
	npc:SetKeyValue("wakesquad", 1)
	npc:SetNPCState(NPC_STATE_ALERT)
	
	if self.Capabilities then
		npc:CapabilitiesClear()
		npc:CapabilitiesAdd(self.Capabilities)
	end
	
	if self.Health and self.Health ~= 0 then
		npc:SetHealth(self.Health)
	end
end

function NPC:OnScaledDamage(npc, hitgroup, dmginfo)
end

function NPC:OnTakeDamage(npc, attacker, inflictor, dmginfo)
	local damage = dmginfo:GetDamage()
	if npc:Health() <= damage then
		dmginfo:SetDamageType(bit.bor(dmginfo:GetDamageType(), DMG_REMOVENORAGDOLL))
	end

	local atkowner = attacker:GetOwner()
	if IsValid(attacker) and attacker:GetClass() == "env_fire" and IsValid(atkowner) and atkowner:GetClass() == "npc_burnzombie" then
		dmginfo:SetDamageType(DMG_GENERIC)
		dmginfo:SetDamage(0)
		dmginfo:ScaleDamage(0)
		return true
	end
	
	if not IsValid(npc:GetEnemy()) and IsValid(attacker) then
		npc:ForceGotoEnemy(attacker, attacker:GetPos())
		
		for k, v in pairs(ents.FindByClass("npc_*")) do
			if IsValid(v) and v:IsNPC() and not IsValid(v:GetEnemy()) then
				npc:ForceGotoEnemy(v, attacker:GetPos())
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
	
	if IsValid(attacker) and attacker:IsPlayer() then
		attacker:AddFrags(1)
	end
end

function NPC:Think(npc)
	--[[
	if not IsValid(npc) then return end
	
	local isDead = npc:Health() <= 0 or npc:IsCurrentSchedule(SCHED_DIE)
	if isDead then
		return
	end
	
	local strafing = npc:IsCurrentSchedule(SCHED_RUN_RANDOM)
	if strafing then
		return
	end
	
	local currentActivity = npc:GetActivity()
	local reloading = npc:IsCurrentSchedule(SCHED_RELOAD) or npc:IsCurrentSchedule(SCHED_HIDE_AND_RELOAD) or currentActivity == ACT_RELOAD
	if reloading then
		return
	end
	
	local getLineOfFire = npc:IsCurrentSchedule(SCHED_ESTABLISH_LINE_OF_FIRE)
	if getLineOfFire then
		return
	end
	
	local chasingEnemy = npc:IsCurrentSchedule(SCHED_CHASE_ENEMY)
	if chasingEnemy then
		return
	end
	
	local fallingBack = npc:IsCurrentSchedule(SCHED_RUN_FROM_ENEMY_FALLBACK)
	if fallingBack then
		return
	end
	
	local specialAttack = npc:IsCurrentSchedule(SCHED_RANGE_ATTACK2) or npc:IsCurrentSchedule(SCHED_MELEE_ATTACK1) or npc:IsCurrentSchedule(SCHED_MELEE_ATTACK2) or npc:IsCurrentSchedule(SCHED_SPECIAL_ATTACK1) or npc:IsCurrentSchedule(SCHED_SPECIAL_ATTACK2)
	if specialAttack then
		return
	end
	
	local forcedRunning = npc:IsCurrentSchedule(SCHED_FORCED_GO_RUN)
	if forcedRunning and not IsValid(npc:GetEnemy()) then
		return
	end
	
	npc:Fire("Wake")
	
	if IsValid(npc:GetEnemy()) then
		npc:RefreshEnemyMemory()
		npc:SetNPCState(NPC_STATE_COMBAT)
		npc:Fire("SetReadinessHigh")
	else
		npc:Fire("SetReadinessLow")
		
		local state = npc:GetNPCState()
		local patrolling = npc:IsCurrentSchedule(SCHED_PATROL_WALK)
		
		if state == NPC_STATE_IDLE and not patrolling then
			npc:SetSchedule(SCHED_PATROL_WALK)
			return
		end
	end
	--]]
	
	local meleeAttacking = npc:GetActivity() == ACT_MELEE_ATTACK1
	if IsValid(npc:GetEnemy()) then
		local enemyDistance = npc:GetPos():Distance(npc:GetEnemy():GetPos())
		local chasingEnemy = npc:IsCurrentSchedule(SCHED_CHASE_ENEMY)
		
		if enemyDistance <= 75 then
			if not meleeAttacking then
				npc:RefreshEnemyMemory()
				npc:SetSchedule(SCHED_MELEE_ATTACK1)
			end
		elseif not chasingEnemy then
			npc:SetSchedule(SCHED_CHASE_ENEMY)
		end
	end
end