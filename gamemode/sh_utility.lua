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

if not CLIENT then return end

local function ZoneSelect(x1, y1, x2, y2)
	local SelectedZombies = {}
	for _, npc in pairs(ents.FindByClass("npc_*")) do
		local npc_spos = npc:GetPos():ToScreen()
		if (npc_spos.x > x1 and npc_spos.x < x2 and npc_spos.y > y1 and npc_spos.y < y2) and npc_spos.visible then
			SelectedZombies[#SelectedZombies + 1] = npc
		end
	end
	
	net.Start("zm_boxselect")
		net.WriteTable(SelectedZombies)
	net.SendToServer()
end
function util.BoxSelect(x, y)
	local topleft_x, topleft_y, botright_x, botright_y

	if mouseX < x then
		topleft_x = mouseX
		botright_x = x
	else
		topleft_x = x
		botright_x = mouseX
	end

	if mouseY < y then
		topleft_y = mouseY
		botright_y = y
	else
		topleft_y = y
		botright_y = mouseY
	end

	ZoneSelect(topleft_x, topleft_y, botright_x, botright_y)
end