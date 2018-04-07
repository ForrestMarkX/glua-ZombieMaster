local meta = FindMetaTable("Entity")
if not meta then return end

meta.oldPlayerHolding = meta.oldPlayerHolding or meta.IsPlayerHolding
function meta:IsPlayerHolding()
    local isHolding = self:oldPlayerHolding()
    if self.bIsHolding ~= isHolding then
        self:SetNW2Bool("holding", isHolding)
    end
    return isHolding
end