local meta = FindMetaTable("Entity")
if not meta then return end

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

function meta:RandomPointInBounds(vecNormalizedMins, vecNormalizedMaxs)
	local vecNormalizedSpace = Vector(math.Rand(vecNormalizedMins.x, vecNormalizedMaxs.x), math.Rand(vecNormalizedMins.y, vecNormalizedMaxs.y), math.Rand(vecNormalizedMins.z, vecNormalizedMaxs.z))
	return self:LocalToWorld(vecNormalizedSpace)
end