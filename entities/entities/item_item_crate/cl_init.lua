include("shared.lua")

function ENT:Initialize()
	self:SetRenderBounds(Vector(-72, -72, -72), Vector(72, 72, 128))
end

function ENT:SetObjectHealth(health)
	self:SetDTFloat(0, health)
end

function ENT:Draw()
	if self:GetObjectHealth() <= 0 then return end
	self:DrawModel()
end
