hook.Add("EntityTakeDamage", "disablehumantrolling", function(ent, dmginfo)
	local attacker = dmginfo:GetAttacker()
	if ent:GetClass() == "func_physbox" and (string.find(string.lower(ent:GetName()), "upstairs_barricade") or ent:Health() == 10) then
		if (IsValid(attacker) and attacker:IsSurvivor()) or bit.band(dmginfo:GetDamageType(), DMG_BLAST) ~= 0 then
			dmginfo:SetDamage(0)
			dmginfo:ScaleDamage(0)
			return true
		end
	end
end)