NPC.Class = "npc_fastzombie"
NPC.Name = translate.Get("npc_class_banshee")
NPC.Description = translate.Get("npc_description_banshee")
NPC.Icon = "VGUI/zombies/info_banshee"
NPC.Flag = FL_SPAWN_BANSHEE_ALLOWED
NPC.Cost = GetConVar("zm_cost_banshee"):GetInt()
NPC.PopCost = GetConVar("zm_popcost_banshee"):GetInt()

NPC.Model = {"models/zombie/zm_fast.mdl"}

function NPC:Think(npc)
	if not IsValid(npc) then return end
	
	--[[
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
	-]]
	
	local meleeAttacking = npc:GetActivity() == ACT_MELEE_ATTACK1
	if IsValid(npc:GetEnemy()) then
		local currentPos = npc:GetPos()
		local enemyPos = npc:GetEnemy():GetPos()
		local enemyDistance = currentPos:Distance(enemyPos)
		local currentActivity = npc:GetActivity()
		local floatingOffGround = npc:HasCondition(NPC_COND_FLOATING_OFF_GROUND)
		local seeEnemy = npc:HasCondition(NPC_COND_SEE_ENEMY)
		
		if enemyDistance <= 90 and currentActivity > 1963 and not floatingOffGround then
			npc:RefreshEnemyMemory()
			npc:SetSchedule(SCHED_MELEE_ATTACK1)
		elseif enemyDistance <= 180 and currentActivity > 1963 and not floatingOffGround and seeEnemy then
			npc:RefreshEnemyMemory()
			npc:SetSchedule(SCHED_RANGE_ATTACK1)
		end
		
		if currentActivity == ACT_RUN and seeEnemy and enemyDistance > 90 and enemyDistance < 500 then
			npc:RefreshEnemyMemory()
			npc:SetSchedule(SCHED_RANGE_ATTACK1)
		end
	end
end