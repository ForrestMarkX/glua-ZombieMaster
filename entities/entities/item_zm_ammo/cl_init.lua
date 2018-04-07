include("shared.lua")

function ENT:ShouldDrawOutline()
    return GAMEMODE.bUseItemHalos and self:GetPos():DistToSqr(LocalPlayer():GetPos()) < 42000 and gamemode.Call("PlayerCanPickupItem", LocalPlayer(), self)
end