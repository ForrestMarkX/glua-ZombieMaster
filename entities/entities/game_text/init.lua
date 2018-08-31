ENT.Type = "point"

local SF_ENVTEXT_ALLPLAYERS = 0x0001

function ENT:Initialize()

end

function ENT:KeyValue(key, value)
    key = string.lower(key)
    if key == "color" then
        local r, g, b = value:match("(%d+) (%d+) (%d+)")
        self.Color1 = Color(r, g, b) or self.Color1
    elseif key == "color2" then
        local r, g, b = value:match("(%d+) (%d+) (%d+)")
        self.Color2 = Color(r, g, b) or self.Color2
    elseif key == "x" then
        self.XPos = tonumber(value) or self.XPos
    elseif key == "y" then
        self.YPos = tonumber(value) or self.YPos
    elseif key == "fadein" then
        self.FadeInTime = tonumber(value) or self.FadeInTime
    elseif key == "fadeout" then
        self.FadeOutTime = tonumber(value) or self.FadeOutTime
    elseif key == "holdtime" then
        self.HoldTime = tonumber(value) or self.HoldTime
    elseif key == "effect" then
        self.EffectType = tonumber(value) or self.EffectType
    elseif key == "fxtime" then
        self.FXTime = tonumber(value) or self.FXTime
    elseif key == "message" then
        self.Message = value or self.Message
    elseif string.Left(key, 2) == "on" then
        self:StoreOutput(key, value)
    end
end

function ENT:AcceptInput(name, caller, activator, arg)
    name = string.lower(name)
    if name == "display" then
        self:InputDisplay(activator)
        return true
    elseif name == "addoutput" then
        self:InputAddOutput(arg)
        return true
    elseif string.Left(name, 2) == "on" then
        self:TriggerOutput(name, activator, args)
    end
end

function ENT:InputDisplay(activator)
    self:Display(activator)
end

function ENT:Display(activator)
    if not self:CanFireForActivator(activator) then
        return
    end
    
    if self.Message and self.Message[1] == "#" then
        self.Message = language.GetPhrase(string.sub(self.Message, 2))
    end

    local messagetab = {
        XPos = self.XPos,
        YPos = self.YPos,
        FadeInTime = self.FadeInTime,
        FadeOutTime = self.FadeOutTime,
        HoldTime = self.HoldTime,
        Font = "zm_game_text",
        Color1 = self.Color1,
        Color2 = self.Color2,
        Effect = self.EffectType,
        FXTime = self.FXTime,
        Message = self.Message or ""
    }
    if self:MessageToAll() then
        self.CurrentDisplayTab = util.PrintMessageBold("GameText_"..self:EntIndex(), messagetab)
    else
        self.CurrentDisplayTab = util.PrintMessage("GameText_"..self:EntIndex(), activator, messagetab)
    end
end

function ENT:CanFireForActivator(activator)
    return true
end

function ENT:MessageToAll()
    return self:HasSpawnFlags(SF_ENVTEXT_ALLPLAYERS)
end

function ENT:InputAddOutput(data)
    local sChar = string.find(data, " ")
    if sChar then
        local sOutputName = string.Left(data, sChar-1)
        local params = string.Replace(string.sub(data, sChar+1, #data), ":", ",")
        self:KeyValue(sOutputName, params)
    else
        error("AddOutput input fired with bad string. Format: <output name> <targetname>,<inputname>,<parameter>,<delay>,<max times to fire (-1 == infinite)>\n")
    end
end