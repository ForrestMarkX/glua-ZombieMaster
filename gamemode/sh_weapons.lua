local meta = FindMetaTable("Weapon")
if not meta then return end

function meta:SetNextReload(fTime)
	self.m_NextReload = fTime
end

function meta:GetNextReload()
	return self.m_NextReload or 0
end

if not CLIENT then return end

function meta:ShouldDrawOutline()
	return self:GetPos():DistToSqr(LocalPlayer():GetPos()) < 42000 and gamemode.Call("PlayerCanPickupWeapon", LocalPlayer(), self)
end