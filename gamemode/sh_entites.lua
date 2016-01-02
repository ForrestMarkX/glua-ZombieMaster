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

function meta:GetHolder()
	for _, ent in pairs(ents.FindByClass("status_human_holding")) do
		if ent:GetObject() == self then
			local owner = ent:GetOwner()
			if owner:IsPlayer() and owner:Alive() then return owner, ent end
		end
	end
end

function meta:RemoveNextFrame(time)
	self.Removing = true
	self:Fire("kill", "", time or 0.01)
end

function meta:OwnedByZM()
	return tobool(string.find(self:GetClass(), "npc_*"))
end

if SERVER then
	function meta:FireOutput(outpt, activator, caller, args)
		local intab = self[outpt]
		if intab then
			for key, tab in pairs(intab) do
				local param = ((tab.args == "") and args) or tab.args
				for __, subent in pairs(self:FindByNameHammer(tab.entityname, activator, caller)) do
					local delay = tonumber(tab.delay)
					if delay == nil or delay <= 0 then
						subent:Input(tab.input, activator, caller, param)
					else
						local inp = tab.input
						timer.Simple(delay, function() if subent:IsValid() then subent:Input(inp, activator, caller, param) end end)
					end
				end
			end
		end
	end

	function meta:AddOnOutput(key, value)
		self[key] = self[key] or {}
		local tab = string.Explode(",", value)
		table.insert(self[key], {entityname=tab[1], input=tab[2], args=tab[3], delay=tab[4], reps=tab[5]})
	end

	function meta:FindByNameHammer(name, activator, caller)
		if name == "!self" then return {self} end
		if name == "!activator" then return {activator} end
		if name == "!caller" then return {caller} end
		return ents.FindByName(name)
	end
end