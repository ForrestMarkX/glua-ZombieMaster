local meta = FindMetaTable("NPC")
if not meta then return end

function meta:IsScripted()
	return scripted_ents.GetType(self:GetClass()) == "ai"
end

meta.CustomScheds = {}
function meta:DefineCustomSchedule(sched)
	if self.CustomScheds[sched.DebugName] then return end
	self.CustomScheds[sched.DebugName] = sched
end

function meta:GetCustomSchedule(name)
	return self.CustomScheds[name]
end

function meta:HasCustomSchedule(name)
	return self.CustomScheds[name] ~= nil
end

function meta:ForceGo(targetPos, traceDir)
	self:SetSaveValue("m_vecLastPosition", targetPos)
	self:SetSchedule(SCHED_FORCED_GO_RUN)
	self:SetCondition(COND_RECEIVED_ORDERS)
	
	GAMEMODE:CallZombieFunction(self, "OnForceGo")
end

function meta:ForceSwat(pTarget, breakable)
	if not pTarget then return end
	if self:IsCurrentSchedule(SCHED_MELEE_ATTACK1) then return end
	
	if self:GetPos():Distance(pTarget:GetPos()) < (self.GetClawAttackRange and self:GetClawAttackRange() or 72) then
		self:SetEnemy(pTarget)
		self:SetTarget(pTarget)
		self:SetSchedule(SCHED_COMBAT_FACE)
		
		timer.Simple(0.25, function()
			self:SetSchedule(SCHED_MELEE_ATTACK1)
			
			if not self.IsEngineNPC then
				self.IsAttacking = true
				timer.Simple(1, function()
					if not IsValid(self) then return end
					pTarget:TakeDamage(self.AttackDamage, self, self)
				end)
			end
		end)
	else
		self:ForceGo(pTarget:GetPos())
	end
end

function meta:FindEnemy()
	local et = ents.FindInSphere(self:GetPos(), 512)
	for k, v in ipairs(et) do
		if not v:IsPlayer() then continue end
		if not v:Alive() then continue end
		if not v:IsSurvivor() then continue end
		
		self:UpdateEnemy(v)
		return
	end
end

function meta:UpdateEnemy(enemy)
	if IsValid(enemy) then
		self:SetEnemy(enemy)
		self:UpdateEnemyMemory(enemy, enemy:GetPos())
		
		self:SetSaveValue("m_vecLastPosition", enemy:GetPos())
		self:SetSchedule(SCHED_FORCED_GO)
		
		if self.PlayVoiceSound then
			self:PlayVoiceSound(self.AlertSounds)
		end
	else
		self:SetEnemy(NULL)
	end
end