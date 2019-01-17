include("shared.lua")

ENT.GlowMat = Material("sprites/glow04_noz")
ENT.GlowColor = Color(255, 255, 255)
ENT.GlowSize = 128
ENT.OrbSize = 16.6

function ENT:DrawTranslucent()
    if not LocalPlayer():IsZM() then return end
    
    render.SetMaterial(self.GlowMat)
    render.DrawSprite(self:GetPos(), self.GlowSize, self.GlowSize, self.GlowColor)
end

local matCubemap = Material("debug/env_cubemap_model")
function ENT:Draw()
    if not LocalPlayer():IsZM() then return end
    
    render.OverrideDepthEnable(true, true)
    render.SuppressEngineLighting(true)
        render.SetMaterial(matCubemap)
        render.DrawSphere(self:GetPos(), self.OrbSize, 30, 7, self.SphereColor)
        self:DrawModel()
    render.SuppressEngineLighting(false)
    render.OverrideDepthEnable(false, false)
end