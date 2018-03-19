local circleMaterial 	   = Material("effects/zombie_select")
local healthcircleMaterial = Material("effects/zm_healthring")
local undovision		   = false
function NPC:PreDraw(npc)
	if LocalPlayer():IsZM() then
		if npc:Health() > 0 then
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
		
		local v_qual = GetConVar("zm_vision_quality"):GetInt()
		if v_qual >= 2 then
			render.ClearStencil()
			render.SetStencilEnable(true)
			
				render.SetStencilWriteMask(255)
				render.SetStencilTestMask(255)
				render.SetStencilReferenceValue(15)
				
				render.SetStencilFailOperation(STENCILOPERATION_KEEP)
				render.SetStencilZFailOperation(STENCILOPERATION_REPLACE)
				render.SetStencilPassOperation(STENCILOPERATION_KEEP)
				render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
				
				npc:DrawModel()
				
				render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
				cam.Start3D2D(npc:GetPos(), npc:GetAngles(), 1)
					render.SetMaterial(ZM_Vision)
					render.DrawScreenQuad()
				cam.End3D2D()
				
			render.SetStencilEnable(false)
		elseif v_qual == 1 and not LocalPlayer():IsLineOfSightClear(npc) then
			undovision = true
			
			render.ModelMaterialOverride(ZM_Vision_Low)
			render.SetColorModulation(1, 0, 0, 1)
		end
	end
end

function NPC:PostDraw(npc)
	if undovision then
		undovision = false
		
		render.ModelMaterialOverride()
		render.SetColorModulation(1, 1, 1)
	end
end