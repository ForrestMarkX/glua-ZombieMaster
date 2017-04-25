local PANEL = {}
PANEL.m_Team = 0
PANEL.NextRefresh = 0
PANEL.RefreshTime = 2

function PANEL:Init()
	self.m_TeamNameLabel = Label(" ", self)
	self.m_TeamNameLabel:SetFont("ZMScoreBoardHeading")
	self.m_TeamNameLabel:SizeToContents()
	
	--[[
	self.NameCol = vgui.Create("DLabel", self)
	self.NameCol:SetText(" ")
	self.NameCol:SetSize( 240, 80 )
	self.NameCol:Dock(LEFT)
	self.NameCol:DockMargin(0, 34, 0, 34)
	self.NameCol.Paint = function(self, w, h)
		draw.SimpleText("Name", "ZMScoreBoardPlayer", w/2, h/2, color_white, 1, 1)
	end
	
	self.ScoreCol = vgui.Create("DLabel", self)
	self.ScoreCol:SetText(" ")
	self.ScoreCol:SetSize( 120, 40 )
	self.ScoreCol:Dock(LEFT)
	self.ScoreCol:DockMargin(0, 34, 0, 34)
	self.ScoreCol.Paint = function(self, w, h)
		draw.SimpleText("Score", "ZMScoreBoardPlayer", w/2, h/2, color_white, 1, 1)
	end
	
	self.DeathCol = vgui.Create("DLabel", self)
	self.DeathCol:SetText(" ")
	self.DeathCol:SetSize( 120, 40 )
	self.DeathCol:Dock(LEFT)
	self.DeathCol:DockMargin(0, 34, 0, 34)
	self.DeathCol.Paint = function(self, w, h)
		draw.SimpleText("Deaths", "ZMScoreBoardPlayer", w/2, h/2, color_white, 1, 1)
	end

	self.PingCol = vgui.Create("DLabel", self)
	self.PingCol:SetText(" ")
	self.PingCol:SetSize( 120, 40 )
	self.PingCol:Dock(LEFT)
	self.PingCol:DockMargin(0, 34, 0, 34)
	self.PingCol.Paint = function(self, w, h)
		draw.SimpleText("Ping", "ZMScoreBoardPlayer", w/2, h/2, color_white, 1, 1)
	end
	--]]
	
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
	draw.RoundedBox(4, 0, 0, wid, hei, Color(col.r * 0.45, col.g * 0.45, col.b * 0.45))
	draw.RoundedBox(4, 2, 2, wid - 4, hei - 4, Color(col.r * 0.65, col.g * 0.65, col.b * 0.65))
	
	return true
end

function PANEL:SetTeam(teamid)
	self.m_Team = teamid
end
function PANEL:GetTeam() return self.m_Team end

vgui.Register("DTeamHeading", PANEL, "Panel")
