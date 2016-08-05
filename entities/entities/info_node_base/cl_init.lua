include("shared.lua")

ENT.GlowColor = Color(255, 255, 255)
ENT.GlowSize = 128

local matGlow = Material("sprites/glow04_noz")
function ENT:DrawTranslucent()
	if MySelf:IsZM() then return end
	
	render.SuppressEngineLighting(true)
	render.SetMaterial(matGlow)
	render.DrawSprite(self:GetPos(), self.GlowSize, self.GlowSize, self.GlowColor)
	self:DrawModel()
	render.SuppressEngineLighting(false)
end

function ENT:Think()
	if MySelf:IsZM() and self:GetActive() then
		local dlight = DynamicLight( self:EntIndex() )
		if ( dlight ) then
			dlight.pos = self:GetPos()
			dlight.r = self.GlowColor.r
			dlight.g = self.GlowColor.g
			dlight.b = self.GlowColor.b
			dlight.brightness = 2
			dlight.Decay = 1000
			dlight.Size = self.GlowSize
			dlight.DieTime = CurTime() + 1
		end
	end
end