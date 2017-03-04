NPC.Class = "npc_zm_fastzombie"
NPC.Name = translate.Get("npc_class_banshee")
NPC.Description = translate.Get("npc_description_banshee")
NPC.Icon = "VGUI/zombies/info_banshee"
NPC.Flag = FL_SPAWN_BANSHEE_ALLOWED
NPC.Cost = GetConVar("zm_cost_banshee"):GetInt()
NPC.PopCost = GetConVar("zm_popcost_banshee"):GetInt()

NPC.Model = {"models/zombie/zm_fast.mdl"}

function NPC:Think(npc)
	if not IsValid(npc) then return end
	
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
	end
end