local meta = FindMetaTable("Entity")
if not meta then return end

function meta:TakeSpecialDamage(damage, damagetype, attacker, inflictor, hitpos)
	attacker = attacker or self
	if not attacker:IsValid() then attacker = self end
	inflictor = inflictor or attacker
	if not inflictor:IsValid() then inflictor = attacker end

	local dmginfo = DamageInfo()
	dmginfo:SetDamage(damage)
	dmginfo:SetAttacker(attacker)
	dmginfo:SetInflictor(inflictor)
	dmginfo:SetDamagePosition(hitpos or self:NearestPoint(inflictor:NearestPoint(self:LocalToWorld(self:OBBCenter()))))
	dmginfo:SetDamageType(damagetype)
	self:TakeDamageInfo(dmginfo)

	return dmginfo
end