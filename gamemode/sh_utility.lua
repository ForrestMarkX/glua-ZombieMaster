function util.PrintMessage(uname, pl, tab)
	if type(tab) ~= "table" or tab.Message == nil then
		error("Argument #3 was not a table or the message was nil.")
	end
	
	if SERVER then
		net.Start("zm_coloredprintmessage")
			net.WriteString(uname)
			net.WriteTable(tab)
		if IsValid(pl) then net.Send(pl) else net.Broadcast() end
		
		return
	end

	if not tab.Font then
		tab.Font = "zm_hud_font_small"
	end
	
	local msg = ""
	if type(tab.Message) == "table" then
		msg = "<font=" .. tab.Font .. ">"
		local index = -1
		for i, t in pairs(tab.Message) do
			if IsColor(t) or (type(t) == "table" and t.r and t.g and t.b) then
				msg = msg .. "<color=" .. t.r .. "," .. t.g .. "," .. t.b .. ">"
				index = i
			else
				msg = msg .. tostring(t)
				if index == (i - 1) then
					msg = msg .. "</color>"
				end
			end
		end
		msg = msg .. "</font>"
	elseif type(tab.Message) == "string" then
		if tab.Font then msg = "<font=" .. tab.Font .. ">" end
		msg = tab.Message
		if tab.Font then msg = msg .. "</font>" end
	else
		error("The message was not a string or a table!")
	end
	
	if not GAMEMODE.ParsedTextObjects then
		GAMEMODE.ParsedTextObjects = {}
	end
	
	local mParseMsg = markup.Parse(msg)
	GAMEMODE.ParsedTextObjects[uname] = {
		Parsed = mParseMsg,
		Duration = (tab.HoldTime + tab.FadeInTime + tab.FadeOutTime) or 5,
		FadeIn = tab.FadeInTime or 0.5,
		FadeOut = tab.FadeOutTime or 0.5,
		XFactor = tab.XPos or 0.5,
		YFactor = tab.YPos or 0.1,
		StartTime = CurTime()
	}
	
	for HookName, Object in pairs(GAMEMODE.ParsedTextObjects) do
		if uname ~= HookName and Object.XFactor == tab.XPos and Object.YFactor == tab.YPos then
			GAMEMODE.ParsedTextObjects[HookName] = nil
			hook.Remove("HUDPaint", HookName)
		end
	end
	
	local function drawToScreen()
		local tab = GAMEMODE.ParsedTextObjects[uname]
		if not tab or tab.Parsed == nil then
			hook.Remove( "HUDPaint", uname )
			return
		end
		
		local alpha = 255
		local dtime = CurTime() - tab.StartTime
		local x, y = tab.XFactor, tab.YFactor
		local dur = tab.Duration
		local fadein = tab.FadeIn
		local fadeout = tab.FadeOut
		local flags = tab.Flags

		if dtime > dur then
			GAMEMODE.ParsedTextObjects[uname] = nil
			hook.Remove( "HUDPaint", uname )
			return
		end

		if fadein - dtime > 0 then
			alpha = (fadein - dtime) / fadein
			alpha = 1 - alpha
			alpha = alpha * 255
		end

		if dur - dtime < fadeout then
			alpha = (dur - dtime) / fadeout
			alpha = alpha * 255
		end

		tab.Parsed:Draw(ScrW() * (x == -1 and 0.5 or x), ScrH() * (y == -1 and 0.7 or y), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, alpha)
	end
	hook.Add("HUDPaint", uname, drawToScreen)
	
	return mParseMsg
end

function util.PrintMessageBold(uname, tab)
	return util.PrintMessage(uname, nil, tab)
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