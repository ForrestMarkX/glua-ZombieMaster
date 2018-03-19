AddCSLuaFile("sh_zerolag.lua")

if CLIENT then
	local CachedFontWidths = {}
	local function draw_GetFontWidth(font)
		if CachedFontWidths[font] then
			return CachedFontWidths[font] 
		end

		surface.SetFont(font)
		local w, h = surface.GetTextSize("W")
		CachedFontWidths[font] = w

		return w
	end
	draw.GetFontWidth = draw_GetFontWidth
end
	
hook.Add("Initialize", "ZeroLag", function()
	-- Why is this called so much?
	hook.Remove("PlayerTick", "TickWidgets")

	-- Supposedly garry has it removed on its own, but w/e
	if timer.Exists("CheckHookTimes") then timer.Remove("CheckHookTimes") end

	if CLIENT then
		-- Not called alot, doesn't increase FPS alot, but they don't do anything so remove them?
		hook.Remove("RenderScreenspaceEffects", "RenderTexturize")
		hook.Remove("PreRender", "PreRenderFrameBlend")
		hook.Remove("RenderScreenspaceEffects", "RenderMaterialOverlay")
		hook.Remove("RenderScreenspaceEffects", "RenderSunbeams")
		hook.Remove("Think", "DOFThink")
		hook.Remove("RenderScreenspaceEffects", "RenderSobel")
		hook.Remove("RenderScreenspaceEffects", "RenderBloom")
		hook.Remove("RenderScene", "RenderSuperDoF")
		hook.Remove("PostDrawEffects", "RenderWidgets")
		hook.Remove("RenderScreenspaceEffects", "RenderSharpen")
		hook.Remove("PostRender", "RenderFrameBlend")
		hook.Remove("PreventScreenClicks", "SuperDOFPreventClicks")
		hook.Remove("RenderScene", "RenderStereoscopy")
		hook.Remove("RenderScreenspaceEffects", "RenderToyTown")
		hook.Remove("NeedsDepthPass", "NeedsDepthPass_Bokeh")
		hook.Remove("RenderScreenspaceEffects", "RenderMotionBlur")
		hook.Remove("RenderScreenspaceEffects", "RenderBokeh")
		hook.Remove("RenderScreenspaceEffects", "RenderColorModify")
		hook.Remove("GUIMouseReleased", "SuperDOFMouseUp")
		hook.Remove("GUIMousePressed", "SuperDOFMouseDown")
		
		-- As much as I am sure people like mouth animations, the rent is too dam high
		function GAMEMODE:MouthMoveAnimation(pl) return end
	end
end)