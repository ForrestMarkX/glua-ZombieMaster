include("shared.lua")

ENT.GlowMat = Material("sprites/glow04_noz")
ENT.GlowColor = Color(255, 255, 255)
ENT.GlowSize = 128

function ENT:DrawTranslucent()
	if not LocalPlayer():IsZM() then return end
	
	render.SetMaterial(self.GlowMat)
	render.DrawSprite(self:GetPos(), self.GlowSize, self.GlowSize, self.GlowColor)
end

function ENT:Draw()
	if not LocalPlayer():IsZM() then return end
	
	render.SuppressEngineLighting(true)
	self:DrawModel()
	render.SuppressEngineLighting(false)
end

function ENT:Think()
	if LocalPlayer():IsZM() and self:GetActive() then
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