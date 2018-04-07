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

function meta:SetClassName(name)
    self:SetDTString(0, name)
end

function meta:GetClassName()
    return self:GetDTString(0)
end

function meta:GetBonePositionMatrixed(index)
	local matrix = self:GetBoneMatrix(index)
	if matrix then
		return matrix:GetTranslation(), matrix:GetAngles()
	end

	return self:GetPos(), self:GetAngles()
end

function meta:NearestBone(pos)
	local count = self:GetBoneCount()
	if count == 0 then return end

	local nearest
	local nearestdist

	for boneid = 1, count - 1 do
		local bonepos, boneang = self:GetBonePositionMatrixed(boneid)
		local dist = bonepos:Distance(pos)

		if not nearest or dist < nearestdist then
			nearest = boneid
			nearestdist = dist
		end
	end

	return nearest
end