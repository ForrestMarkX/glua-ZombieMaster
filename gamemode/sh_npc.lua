local meta = FindMetaTable("NPC")
if not meta then return end

function meta:ForceGoto(pos)
	self:SetSaveValue("m_vecLastPosition", pos)
	self:SetSchedule(SCHED_FORCED_GO)
end