-- Original code from Zombie Survival by Jetboom

function WorldVisible(posa, posb)
	return not util.TraceLine({start = posa, endpos = posb, mask = MASK_SOLID_BRUSHONLY}).Hit
end

function TrueVisible(posa, posb)
	return not util.TraceLine({start = posa, endpos = posb, filter = player.GetAll(), mask = MASK_SHOT}).Hit
end

function TrueVisibleFilters(posa, posb, ...)
	local filt = ents.FindByClass("projectile_*")
	filt = table.Add(filt, player.GetAll())
	if ... ~= nil then
		for k, v in pairs({...}) do
			filt[#filt + 1] = v
		end
	end

	return not util.TraceLine({start = posa, endpos = posb, filter = filt, mask = MASK_SHOT}).Hit
end

function util.BlastDamageEx(inflictor, attacker, epicenter, radius, damage, damagetype)
	local filter = inflictor
	for _, ent in pairs(ents.FindInSphere(epicenter, radius)) do
		if ent and ent:IsValid() then
			local nearest = ent:NearestPoint(epicenter)
			if TrueVisibleFilters(epicenter, nearest, inflictor, ent) then
				ent:TakeSpecialDamage(((radius - nearest:Distance(epicenter)) / radius) * damage, damagetype, attacker, inflictor, nearest)
			end
		end
	end
end

-- From ULX csay. Needed to print a colored message at the center of the screen
function util.PrintMessageC(pl, msg, color, duration, fade)
	if SERVER then
		net.Start("zm_coloredprintmessage")
			net.WriteString(msg or "")
			net.WriteColor(color or color_white)
			net.WriteUInt(duration or 5, 32)
			net.WriteFloat(fade or 0.5)
		if IsValid(pl) then net.Send(pl) else net.Broadcast() end
		
		return
	end
	
	color = color or Color(255, 255, 255, 255)
	duration = duration or 5
	fade = fade or 0.5
	local start = CurTime()

	local function drawToScreen()
		local alpha = 255
		local dtime = CurTime() - start

		if dtime > duration then
			hook.Remove( "HUDPaint", "CSayHelperDraw" )
			return
		end

		if fade - dtime > 0 then
			alpha = (fade - dtime) / fade
			alpha = 1 - alpha
			alpha = alpha * 255
		end

		if duration - dtime < fade then
			alpha = (duration - dtime) / fade
			alpha = alpha * 255
		end
		color.a  = alpha

		draw.DrawText(msg, "TargetID", ScrW() * 0.5, ScrH() * 0.25, color, TEXT_ALIGN_CENTER)
	end

	hook.Add("HUDPaint", "PrintMessageCDraw", drawToScreen)
end