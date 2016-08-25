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

function meta:ForceGoto(pos)
	self:SetLastPosition(pos)
	self:NavSetGoal(pos)
	self:SetSchedule(SCHED_FORCED_GO_RUN)
	self:SetCondition(63) --COND_RECEIVED_ORDERS
end

function meta:ForceGotoEnemy(enemy, pos)
	self:SetLastPosition(pos)
	self:SetTarget(enemy)
	self:NavSetGoal(pos)
	self:UpdateEnemyMemory(enemy, pos)
	self:SetSchedule(SCHED_FORCED_GO_RUN)
	self:SetEnemy(enemy)
	self:SetNPCState(NPC_STATE_COMBAT)
	self:SetCondition(63) --COND_RECEIVED_ORDERS
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