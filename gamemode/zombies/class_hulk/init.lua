NPC.HullType = HULL_MEDIUM_TALL
NPC.HullSizeMins = Vector(13, 13, 90)
NPC.HullSizeMaxs = Vector(-13, -13, 0)

NPC.ClearCapabilities = true
NPC.Capabilities = bit.bor(CAP_MOVE_GROUND, CAP_INNATE_MELEE_ATTACK1)

function NPC:OnSpawned(npc)
	self.BaseClass.OnSpawned(self, npc)
	npc.AttackCoolDown = CurTime()
end

function NPC:Think(npc)
	self.BaseClass.Think(self, npc)
	
	local enemy = npc:GetEnemy()
	if IsValid(enemy) then
		if npc:IsCurrentSchedule(SCHED_MELEE_ATTACK1) then return end
		
		if npc:GetPos():Distance(enemy:GetPos()) <= 72 and npc.AttackCoolDown < CurTime() then
			npc:SetSchedule(SCHED_COMBAT_FACE)
			
			npc.AttackCoolDown = CurTime() + 2
			timer.Simple(0.25, function()
				npc:SetSchedule(SCHED_MELEE_ATTACK1)
			end)
		end
	end
end

function NPC:OnScaledDamage(npc, hitgroup, dmginfo)
	if hitgroup == HITGROUP_LEFTLEG or hitgroup == HITGROUP_RIGHTLEG then
		dmginfo:ScaleDamage(2)
	end
end

function NPC:OnDamagedEnt(npc, ent, dmginfo)
	dmginfo:SetDamage(math.random(GetConVar("zm_zombie_poison_dmg_slash_min"):GetInt(), GetConVar("zm_zombie_poison_dmg_slash_max"):GetInt()))
end