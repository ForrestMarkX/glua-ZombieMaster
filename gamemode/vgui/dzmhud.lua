local PANEL = {}

function PANEL:Init()
	gui.EnableScreenClicker(true)
end

local matFigures = Material("vgui/minifigures") 
local matSkull = Material("vgui/miniskull")
function PANEL:Paint()
	return true
	--[[
	local wid, hei = self:GetSize()
	
	draw.RoundedBox(4, wid / 1.15, hei / 1.25, wid / 7.38, hei / 4.91, Color(100, 0, 0, 100))
	draw.RoundedBox(4, 0, hei / 1.12, wid / 8.73, hei / 9, Color(100, 0, 0, 100))

	surface.SetMaterial(matSkull)
	surface.SetDrawColor(Color(255, 255, 255, 255))
	surface.DrawTexturedRect(wid / 160, hei / 1.11, wid / 53.33, hei / 30, Color(255, 255, 255, 255))

	surface.SetMaterial(matFigures)
	surface.SetDrawColor(Color(255, 255, 255, 255))
	surface.DrawTexturedRect(wid / 80, hei / 1.04, wid / 80, hei / 36, Color(255, 255, 255, 255))
	
	draw.DrawText(MySelf:GetZMPoints(), "Arial24", wid / 32, hei / 1.11, Color(255, 255, 255, 255))
	draw.DrawText("+ "..GAMEMODE:GetResourceAdditive(), "Arial24", wid / 22.86, hei / 1.09, Color(255, 255, 255, 255))
	draw.DrawText(GAMEMODE:GetCurZombiePop().." / "..GAMEMODE:GetMaxZombiePop(), "Arial24", wid / 32, hei / 1.03, Color(255, 255, 255, 255))
	--]]
end

vgui.Register("DZMHud", PANEL, "DPanel")