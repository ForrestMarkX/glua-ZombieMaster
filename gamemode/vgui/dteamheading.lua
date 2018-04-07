local PANEL = {}
PANEL.m_Team = 0
PANEL.NextRefresh = 0
PANEL.RefreshTime = 2

function PANEL:Init()
    self.m_TeamNameLabel = Label(" ", self)
    self.m_TeamNameLabel:SetFont("ZMScoreBoardHeading")
    self.m_TeamNameLabel:SizeToContents()
    
    self:InvalidateLayout()
end

function PANEL:Think()
    if RealTime() >= self.NextRefresh then
        self.NextRefresh = RealTime() + self.RefreshTime
        self:Refresh()
    end
end

function PANEL:PerformLayout()
    self.m_TeamNameLabel:Center()
end

function PANEL:Refresh()
    local teamid = self:GetTeam()
    
    self.m_TeamNameLabel:SetText(team.GetName(teamid))
    self.m_TeamNameLabel:SizeToContents()
    
    self:InvalidateLayout()
end

function PANEL:Paint(wid, hei)
    local teamid = self:GetTeam()
    
    local col = team.GetColor(teamid)
    draw.RoundedBoxHollow(3, 0, 0, wid, hei, Color(col.r * 0.65, col.g * 0.65, col.b * 0.65))
    draw.RoundedBox(2, 2, 2, wid - 4, hei - 4, Color(col.r * 0.45, col.g * 0.45, col.b * 0.45, 200))
    
    return true
end

function PANEL:SetTeam(teamid)
    self.m_Team = teamid
end
function PANEL:GetTeam() return self.m_Team end

vgui.Register("DTeamHeading", PANEL, "Panel")
