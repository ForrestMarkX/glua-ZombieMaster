function GM:HUDDrawTargetID()
	if MySelf:Team() == TEAM_ZOMBIEMASTER then return end
	
	local tr = util.GetPlayerTrace(MySelf)
	local trace = util.TraceLine( tr )
	if not trace.Hit then return end
	if not trace.HitNonWorld then return end
	
	local text = "ERROR"
	local font = "TargetID"
	local healthtext = "ERROR"
	
	if trace.Entity:IsPlayer() then
		text = trace.Entity:Nick()
		healthtext = trace.Entity:Health() < 20 and "Critical" or trace.Entity:Health() < 50 and "Wounded" or trace.Entity:Health() < 75 and "Injured" or "Healthy"
	else return
	end
	
	surface.SetFont( font )
	draw.DrawText(text.."("..healthtext..")", "DermaLarge", ScrW()/96, ScrH()/1.88, Color(255, 255, 255, 255))
end