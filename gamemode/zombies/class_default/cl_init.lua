local circleMaterial 	   = Material("SGM/playercircle")
local healthcircleMaterial = Material("effects/zm_healthring")
local healthcolmax 		   = Color(20, 255, 20)
local healthcolmin 		   = Color(255, 0, 0)
function NPC:PostDraw(npc)
	if LocalPlayer():IsZM() and npc:Health() > 0 then
		local Health, MaxHealth = npc:Health(), npc:GetMaxHealth()
		local pos = npc:GetPos() + Vector(0, 0, 2)
		local colour = Color(0, 0, 0, 125)
		local healthfrac = math.max(Health, 0) / MaxHealth
		
		colour.r = Lerp(healthfrac, healthcolmin.r, healthcolmax.r)
		colour.g = Lerp(healthfrac, healthcolmin.g, healthcolmax.g)
		colour.b = Lerp(healthfrac, healthcolmin.b, healthcolmax.b)
		
		render.SetMaterial(healthcircleMaterial)
		render.DrawQuadEasy(pos, Vector(0, 0, 1), 40, 40, colour)
		render.DrawQuadEasy(pos, -Vector(0, 0, 1), 40, 40, colour)
		
		if npc.bIsSelected then
			render.SetMaterial(circleMaterial)
			render.DrawQuadEasy(pos, Vector(0, 0, 1), 40, 40, colour)
			render.DrawQuadEasy(pos, -Vector(0, 0, 1), 40, 40, colour)
		end
	end
end