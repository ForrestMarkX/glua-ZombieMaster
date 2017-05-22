local meta = FindMetaTable("Entity")
if not meta then return end

function meta:TakeSpecialDamage(damage, damagetype, attacker, inflictor, hitpos)
	if self:IsPlayer() and self:HasGodMode() then return end
	
	attacker = attacker or self
	if not attacker:IsValid() then attacker = self end
	inflictor = inflictor or attacker
	if not inflictor:IsValid() then inflictor = attacker end

	local dmginfo = DamageInfo()
	dmginfo:SetDamage(damage)
	dmginfo:SetAttacker(attacker)
	dmginfo:SetInflictor(inflictor)
	dmginfo:SetDamagePosition(hitpos or self:NearestPoint(inflictor:NearestPoint(self:LocalToWorld(self:OBBCenter()))))
	dmginfo:SetDamageType(damagetype or DMG_GENERIC)
	self:TakeDamageInfo(dmginfo)

	return dmginfo
end

function meta:SetModelDelayed(delay, mdl)
	timer.Simple(delay, function() if IsValid(self) then self:SetModel(mdl) end end)
end

function meta:IsPointInBounds(vecWorldPt)
	local vecLocalSpace = self:WorldToLocal(vecWorldPt)
	local m_vecMins = self:OBBMins()
	local m_vecMaxs = self:OBBMaxs()
	
	return (vecLocalSpace.x >= m_vecMins.x and vecLocalSpace.x <= m_vecMaxs.x) and
			(vecLocalSpace.y >= m_vecMins.y and vecLocalSpace.y <= m_vecMaxs.y) and
			(vecLocalSpace.z >= m_vecMins.z and vecLocalSpace.z <= m_vecMaxs.z)
end