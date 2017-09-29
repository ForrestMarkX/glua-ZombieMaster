local circleMaterial 	   = Material("effects/zombie_select")
local healthcircleMaterial = Material("effects/zm_healthring")
function NPC:PostDraw(npc)
	if LocalPlayer():IsZM() and npc:Health() > 0 then
		local pos = npc:GetPos() + Vector(0, 0, 3)
		local healthfrac = math.Clamp(npc:Health() / npc:GetMaxHealth(), 0, 1) * 255
		
		local brightness = math.Clamp(GetConVar("zm_healthcircle_brightness"):GetFloat(), 0, 1)
		if brightness == 0 then return end
			
		local redness = 255 - healthfrac
		local greenness = 255 - redness
		local colour = Color(redness * brightness, greenness * brightness, 0, 255)
		
		render.SetMaterial(healthcircleMaterial)
		render.DrawQuadEasy(pos, Vector(0, 0, 1), 40, 40, colour)
		
		if npc.bIsSelected then
			render.SetMaterial(circleMaterial)
			render.DrawQuadEasy(pos, Vector(0, 0, 1), 40, 40, colour)
		end
	end
end