local meta = FindMetaTable("NPC")
if not meta then return end

function meta:NPCThink()
	local isDead = self:Health() <= 0 or self:IsCurrentSchedule(SCHED_DIE)
	if isDead then return end
	
	local chasingEnemy = self:IsCurrentSchedule(SCHED_CHASE_ENEMY)
	if chasingEnemy then return end
	
	local specialAttack = self:IsCurrentSchedule(SCHED_RANGE_ATTACK2) or self:IsCurrentSchedule(SCHED_MELEE_ATTACK1) or self:IsCurrentSchedule(SCHED_MELEE_ATTACK2) or self:IsCurrentSchedule(SCHED_SPECIAL_ATTACK1) or self:IsCurrentSchedule(SCHED_SPECIAL_ATTACK2)
	if specialAttack then return end
	
	local forcedRunning = self:IsCurrentSchedule(SCHED_FORCED_GO_RUN)
	if forcedRunning and not IsValid(self:GetEnemy()) then return end
	
	local defending = self:IsCurrentSchedule(SCHED_AMBUSH)
	if defending then return end
	
	self:Fire("Wake")
	
	if IsValid(self:GetEnemy()) then
		self:RefreshEnemyMemory()
		self:SetNPCState(NPC_STATE_COMBAT)

		local state = self:GetNPCState()
		if state == NPC_STATE_ALERT then
			self:SetSchedule(SCHED_FORCED_GO_RUN)
			self:SetNPCState(NPC_STATE_IDLE)
			return
		end
		
		self:CheckForEnemies()
	end
end

function meta:ForceGoto(pos, bRun)
	local eyeh = self:EyePos().z
	if eyeh > pos.z then
		pos.z = eyeh
	end
	
	self:SetSaveValue("m_vecLastPosition", pos)
	self:SetSaveValue("m_vecLastGoalPosition", pos)
	self:NavSetGoal(pos)

	self:SetSchedule(SCHED_FORCED_GO_RUN)
end

function meta:ForceGotoEnemy(enemy, pos, bRun)
	local eyeh = self:EyePos().z
	if eyeh > pos.z then
		pos.z = eyeh
	end
	
	self:SetSaveValue("m_vecLastPosition", pos)
	self:SetSaveValue("m_vecLastGoalPosition", pos)
	self:NavSetGoalTarget(enemy, pos)
	
	self:SetTarget(enemy)
	self:UpdateEnemyMemory(enemy, pos)
	self:SetEnemy(enemy)
	self:SetNPCState(NPC_STATE_COMBAT)

	if bRun then
		self:SetSchedule(SCHED_FORCED_GO_RUN)
	else
		self:SetSchedule(SCHED_FORCED_GO)
	end
end

function meta:RefreshEnemyMemory()
	local enemy = self:GetEnemy()
	local enemyPos = enemy:GetPos()
	
	self:SetLastPosition(enemyPos)
	self:SetTarget(enemy)
	self:NavSetGoal(enemyPos)
	self:UpdateEnemyMemory(enemy, enemyPos)
end

function meta:CheckForEnemies()
	for k, v in pairs(team.GetPlayers(TEAM_SURVIVOR)) do
		if IsValid(v) and v:Health() > 0 and v:Visible(self) then
			self:SetEnemy(v)
			self:RefreshEnemyMemory()
			break
		end
	end
end

function meta:ForceSwat(pTarget, breakable)
	if not pTarget then return end
	if self:IsCurrentSchedule(SCHED_MELEE_ATTACK1) then return end
	
	if self:GetPos():Distance(pTarget:GetPos()) <= 75 then
		self:SetEnemy(pTarget)
		self:SetTarget(pTarget)
		self.attack = true
		self:SetSchedule(SCHED_COMBAT_FACE)
		self:SetSchedule(SCHED_MELEE_ATTACK1)
	else
		self:ForceGotoEnemy(pTarget, pTarget:GetPos())
	end
end