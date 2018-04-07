ENT.Type = "point"

function ENT:Initialize()
    local iScore = self:Points()
    self:SetPoints(iScore)
end

function ENT:KeyValue(key, value)
    key = string.lower(key)
    if key == "points" then
        self:SetPoints(value)
    end
end

function ENT:AcceptInput(name, caller, activator, arg)
    name = string.lower(name)
    if name == "applyscoresurvivors" then
        self:InputApplyScoreSurvivors(tonumber(arg))
        return true
    elseif name == "applyscorezm" then
        self:InputApplyScoreZM(tonumber(arg))
        return true
    end
end

function ENT:ApplyTheScore(bZM)
    for _, plr in pairs(player.GetAll()) do
        if not plr:IsSpectator() then
            if plr:IsZM() == bZM then
                plr:AddZMPoints(self:Points())
            else
                plr:AddFrags(self:Points())
            end
        end
    end
end

function ENT:InputApplyScoreSurvivors(inputdata)
    self:ApplyTheScore(false)
end

function ENT:InputApplyScoreZM(inputdata)
    self:ApplyTheScore(true)
end

function ENT:Points()
    return self.m_Score
end

function ENT:SetPoints(points)
    self.m_Score = points
end