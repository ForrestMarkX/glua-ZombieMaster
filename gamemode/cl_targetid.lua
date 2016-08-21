function GM:HUDDrawTargetID()
	if LocalPlayer():IsZM() then return end
	
	local tr = util.GetPlayerTrace(LocalPlayer())
	local trace = util.TraceLine(tr)
	
	if not trace.Hit or not trace.HitNonWorld then return end
	
	local ent = trace.Entity
	if not IsValid(ent) then return end
	if not ent:IsPlayer() then return end
	
	local text = ent:Nick() or "ERROR"
	local font = "TargetID"
	
	local health = ent:Health()
	local healthtext = health < 20 and "Critical" or health < 50 and "Wounded" or health < 75 and "Injured" or "Healthy"
	
	surface.SetFont(font)
	draw.DrawText(text.."("..healthtext..")", "DermaLarge", ScrW() / 96, ScrH() / 1.88, Color(255, 255, 255, 255))
end