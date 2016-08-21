local meta = FindMetaTable("Entity")
if not meta then return end

function meta:IsPlayerHolding()
	return self:GetSharedBool("holding", false)
end