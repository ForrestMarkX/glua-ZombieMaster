include("shared.lua")

function ENT:ShouldDrawOutline()
	return self:GetPos():DistToSqr(LocalPlayer():GetPos()) < 42000 and gamemode.Call("PlayerCanPickupItem", LocalPlayer(), self)
end