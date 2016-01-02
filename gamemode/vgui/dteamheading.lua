local PANEL = {}
PANEL.m_Team = 0
PANEL.NextRefresh = 0
PANEL.RefreshTime = 2

function PANEL:Init()
	self.m_TeamNameLabel = EasyLabel(self, " ", "ZSScoreBoardHeading", color_black)
	
	self.NameCol = vgui.Create("DLabel", self)
	self.NameCol:SetPos( self:GetWide() * 1.2, 15 )
	self.NameCol:SetText("")
	self.NameCol:SetSize( 120, 40 )
	self.NameCol.Paint = function(self, w, h)
		DisableClipping( true )
		draw.SimpleText("Name", "ZSScoreBoardPlayer", w/2, h/2, color_white, 1, 1)
		DisableClipping( false )
	end
	
	self.ScoreCol = vgui.Create("DLabel", self)
	self.ScoreCol:SetPos( self:GetWide() * 3.5, 15 )
	self.ScoreCol:SetText("")
	self.ScoreCol:SetSize( 120, 40 )
	self.ScoreCol.Paint = function(self, w, h)
		DisableClipping( true )
		draw.SimpleText("Score", "ZSScoreBoardPlayer", w/2, h/2, color_white, 1, 1)
		DisableClipping( false )
	end
	
	self.DeathCol = vgui.Create("DLabel", self)
	self.DeathCol:SetPos( self:GetWide() * 4.5, 15 )
	self.DeathCol:SetText("")
	self.DeathCol:SetSize( 120, 40 )
	self.DeathCol.Paint = function(self, w, h)
		DisableClipping( true )
		draw.SimpleText("Deaths", "ZSScoreBoardPlayer", w/2, h/2, color_white, 1, 1)
		DisableClipping( false )
	end

	self.PingCol = vgui.Create("DLabel", self)
	self.PingCol:SetPos( self:GetWide() * 6.32, 15 )
	self.PingCol:SetText("")
	self.PingCol:SetSize( 120, 40 )
	self.PingCol.Paint = function(self, w, h)
		DisableClipping( true )
		draw.SimpleText("Ping", "ZSScoreBoardPlayer", w/2, h/2, color_white, 1, 1)
		DisableClipping( false )
	end
	
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
	
	if teamid ~= TEAM_SURVIVOR then
		self.ScoreCol:SetVisible(false)
		self.DeathCol:SetVisible(false)
	else
		self.ScoreCol:SetVisible(true)
		self.DeathCol:SetVisible(true)
	end
	
	self.m_TeamNameLabel:SetText(team.GetName(teamid))
	self.m_TeamNameLabel:SetColor(team.GetColor(teamid))
	self.m_TeamNameLabel:SizeToContents()
	
	self:InvalidateLayout()
end

function PANEL:Paint()
	local teamid = self:GetTeam()
	local wid, hei = self:GetWide(), self:GetTall()
	DisableClipping( true )
	draw.RoundedBox(4, 0, hei + 17, wid, 2, team.GetColor(teamid))
	DisableClipping( false )
	return true
end

function PANEL:SetTeam(teamid)
	self.m_Team = teamid
end
function PANEL:GetTeam() return self.m_Team end

vgui.Register("DTeamHeading", PANEL, "Panel")
