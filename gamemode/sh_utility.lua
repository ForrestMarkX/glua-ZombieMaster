local function GetXPosition(x, width, totalWidth)
	local xPos
	if x == -1 then
		xPos = (ScrW() - width) / 2
	else
		if x < 0 then
			xPos = (1.0 + x) * ScrW() - totalWidth
		else
			xPos = x * ScrW()
        end
	end

	if xPos + width > ScrW() then
		xPos = ScrW() - width
	elseif xPos < 0 then
		xPos = 0
    end

	return xPos
end
local function GetYPosition(y, height)
	local yPos
	if y == -1 then
		yPos = (ScrH() - height) * 0.5
	else
		if y < 0 then
			yPos = (1.0 + y) * ScrH() - height
		else
			yPos = y * ScrH()
        end
	end

	if yPos + height > ScrH() then
		yPos = ScrH() - height
	elseif yPos < 0 then
		yPos = 0
    end

	return yPos
end
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
        tab.Font = "zm_game_text"
    end
    
    if not GAMEMODE.ParsedTextObjects then
        GAMEMODE.ParsedTextObjects = {}
    end
    
    GAMEMODE.ParsedTextObjects[uname] = {
        Message = tab.Message,
        Font = tab.Font,
        HoldTime = tab.HoldTime or 0.5,
        Duration = (tab.HoldTime + tab.FadeInTime + tab.FadeOutTime) or 5,
        FadeIn = tab.FadeInTime or 0,
        FadeOut = tab.FadeOutTime or 0,
        XFactor = tab.XPos or 0.5,
        YFactor = tab.YPos or 0.1,
        Color1 = tab.Color1 or color_white,
        Color2 = tab.Color2 or color_white,
        EffectType = tab.Effect or 0,
        FXTime = tab.FXTime or 0,
        StartTime = CurTime()
    }
    
    for HookName, Object in pairs(GAMEMODE.ParsedTextObjects) do
        if uname ~= HookName and Object.XFactor == tab.XPos and Object.YFactor == tab.YPos then
            GAMEMODE.ParsedTextObjects[HookName] = nil
            hook.Remove("HUDPaint", HookName)
            
            GAMEMODE.ParsedTextObjects[uname].FadeIn = 0
        end
    end
    
    local function drawToScreen()
        local tab = GAMEMODE.ParsedTextObjects[uname]
        if not tab then
            hook.Remove( "HUDPaint", uname )
            return
        end
        
        local msg = tab.Message
        local bScan = tab.EffectType >= 2
        local alpha = 255
        local dtime = CurTime() - tab.StartTime
        local dur = tab.Duration * (bScan and #msg or 1)
        local fadein = tab.FadeIn
        local fadeout = tab.FadeOut

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

        surface.SetFont(tab.Font)
        local w, h = surface.GetTextSize(tab.Message)
        local x, y = GetXPosition(tab.XFactor, w, w), GetYPosition(tab.YFactor, h)
        
        if bScan then
            local fadeTime = (fadein * #msg) + tab.HoldTime
            local fadeBlend = 0
            
            if dtime > fadeTime and fadeout > 0 then
                fadeBlend = ((dtime - fadeTime) / fadeout) * 255
            else
                fadeBlend = 0
            end
            
            local charTime = 0
            local blend = 0
            local srcRed, srcGreen, srcBlue = tab.Color1.r, tab.Color1.g, tab.Color1.b
            local destRed, destGreen, destBlue = 0, 0, 0
            local color = Color(0, 0, 0)
            for i = 1, #msg do
                charTime = charTime + fadein
                if charTime > dtime then
                    srcRed, srcGreen, srcBlue = 0, 0, 0 
                    blend = 0
                else
                    local deltaTime = dtime - charTime

                    destRed, destGreen, destBlue = 0, 0, 0
                    if dtime > fadeTime then
                        blend = fadeBlend
                    elseif deltaTime > tab.FXTime then
                        blend = 0
                    else
                        destRed = tab.Color2.r
                        destGreen = tab.Color2.g
                        destBlue = tab.Color2.b
                        blend = 255 - (deltaTime * (1/tab.FXTime) * 255 + 0.5)
                    end
                end
                
                math.Clamp(blend, 0, 255)
                math.Clamp(fadeBlend, 0, 255)

                color.r = bit.rshift((srcRed * (255-blend)) + (destRed * blend), 8)
                color.g = bit.rshift((srcGreen * (255-blend)) + (destGreen * blend), 8)
                color.b = bit.rshift((srcBlue * (255-blend)) + (destBlue * blend), 8)
                
                surface.SetTextColor(color.r, color.g, color.b, color == color_black and 0 or 255 - fadeBlend)
                local w = surface.GetTextSize(string.sub(msg, 1, i - 1))
                surface.SetTextPos(x + w, y)
                surface.DrawText(string.sub(msg, i, i))
                
                if fadeBlend == 255 then
                    GAMEMODE.ParsedTextObjects[uname] = nil
                    hook.Remove( "HUDPaint", uname )
                end
            end
        else
            surface.SetTextColor(tab.Color1.r, tab.Color1.g, tab.Color1.b, alpha)
            surface.SetTextPos(x, y)
            surface.DrawText(msg)
        end
    end
    hook.Add("HUDPaint", uname, drawToScreen)
    
    return GAMEMODE.ParsedTextObjects[uname]
end

function util.PrintMessageBold(uname, tab)
    return util.PrintMessage(uname, nil, tab)
end

if not CLIENT then return end

local function ZoneSelect(x1, y1, x2, y2)
    local SelectedZombies = {}
    for _, npc in pairs(ents.FindByClass("npc_*")) do
        local npc_spos = npc:WorldSpaceCenter():ToScreen()
        if (npc_spos.x > x1 and npc_spos.x < x2 and npc_spos.y > y1 and npc_spos.y < y2) then
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