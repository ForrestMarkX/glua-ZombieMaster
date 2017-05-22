local PANEL = {}

function PANEL:Init()
	self.AvatarButton = self:Add("DButton")
	self.AvatarButton:AlignLeft(18)
	self.AvatarButton:SetSize(32, 32)
	self.AvatarButton.DoClick = function() self.Player:ShowProfile() end

	self.Avatar = vgui.Create("AvatarImage", self.AvatarButton)
	self.Avatar:SetSize(32, 32)
	self.Avatar:SetMouseInputEnabled(false)
	
	self.SpecialImage = self:Add("DImage")
	self.SpecialImage:SetSize(16, 16)
	self.SpecialImage:SetMouseInputEnabled(true)
	self.SpecialImage:CenterVertical(0.65)
	
	self.Name = self:Add("DLabel")
	self.Name:Dock(FILL)
	self.Name:SetFont("ZMScoreBoardPlayer")
	self.Name:DockMargin(55, 0, 0, 0)
	self.Name:SetColor(color_white)

	self.Ping = self:Add("DPingMeter")
	self.Ping:Dock(RIGHT)
	self.Ping:DockMargin(0, 0, 32, 0)
	self.Ping:SetSize(self:GetTall(), self:GetTall())
	self.Ping.PingBars = 5
	
	self.Mute = self:Add("DImageButton")
	self.Mute:SetSize(32, 32)
	self.Mute:DockMargin(0, 0, 32, 0)
	self.Mute:Dock(RIGHT)

	self.Deaths = self:Add("DLabel")
	self.Deaths:Dock(RIGHT)
	self.Deaths:DockMargin(0, 0, 16, 0)
	self.Deaths:SetWidth(50)
	self.Deaths:SetFont("ZMScoreBoardPlayerSmall")
	self.Deaths:SetContentAlignment(5)

	self.Kills = self:Add("DLabel")
	self.Kills:Dock(RIGHT)
	self.Kills:DockMargin(0, 0, 16, 0)
	self.Kills:SetWidth(50)
	self.Kills:SetFont("ZMScoreBoardPlayerSmall")
	self.Kills:SetContentAlignment(5)
	
	self:Dock(TOP)
	self:DockPadding(3, 3, 3, 3)
	self:SetHeight(32)
	self:DockMargin(2, 0, 2, 2)
end

function PANEL:Setup(pl)
	self.m_Flash = pl:SteamID() == "STEAM_0:1:3307510" or pl:IsAdmin() or pl:IsSuperAdmin() 
	self.Player = pl
	self.Avatar:SetPlayer(pl, 32)
	self.Ping:SetPlayer(pl)
	self:Think(self)
	
	if pl == LocalPlayer() and IsValid(self.Mute) then
		self.Mute:SetEnabled(false)
	end
	
	if gamemode.Call("IsSpecialPerson", pl, self.SpecialImage) then
		self.SpecialImage:SetVisible(true)
	else
		self.SpecialImage:SetTooltip()
		self.SpecialImage:SetVisible(false)
	end
end

function PANEL:Think()
	if not IsValid(self.Player) then
		self:SetZPos( 9999 ) -- Causes a rebuild
		self:Remove()
		return
	end

	if self.PName == nil or self.PName ~= self.Player:Nick() then
		self.PName = self.Player:Nick()
		self.Name:SetText(self.PName)
	end
	
	if self.NumKills == nil or self.NumKills ~= self.Player:Frags() then
		self.NumKills = self.Player:Frags()
		self.Kills:SetText(self.NumKills)
	end

	if self.NumDeaths == nil or self.NumDeaths ~= self.Player:Deaths() then
		self.NumDeaths = self.Player:Deaths()
		self.Deaths:SetText( self.NumDeaths )
	end

	if (self.Muted == nil or self.Muted ~= self.Player:IsMuted()) and self.Player ~= LocalPlayer() then
		self.Mute:SetColor(color_black)
		
		self.Muted = self.Player:IsMuted()
		if self.Muted then
			self.Mute:SetImage( "icon32/muted.png" )
		else
			self.Mute:SetImage( "icon32/unmuted.png" )
		end

		self.Mute.DoClick = function() self.Player:SetMuted(not self.Muted) end
	end
	
	if self.Player:Team() ~= self._LastTeam then
		if not IsValid(g_Scoreboard) then return end
		
		g_Scoreboard.SurvivorsList:InvalidateLayout()
		g_Scoreboard.ZombieMasterList:InvalidateLayout()
		g_Scoreboard.SpectatorsList:InvalidateLayout()
		
		self._LastTeam = self.Player:Team()
		self:SetParent(self._LastTeam == TEAM_SURVIVOR and g_Scoreboard.SurvivorsList or self._LastTeam == TEAM_ZOMBIEMASTER and g_Scoreboard.ZombieMasterList or g_Scoreboard.SpectatorsList)
		self:SetZPos(9999)
	end

	self:SetZPos((self.NumKills * -50) + self.NumDeaths + self.Player:EntIndex())
end

local colTemp = Color(255, 255, 255, 220)
function PANEL:Paint(w, h)
	local col = Color(0, 0, 0, 180)
	local mul = 0.5
	local pl = self.Player
	if pl:IsValid() then
		col = team.GetColor(pl:Team())

		if self.m_Flash then
			mul = 0.6 + math.abs(math.sin(RealTime() * 6)) * 0.4
		elseif pl == LocalPlayer() then
			mul = 0.8
		end
		
		colTemp = team.GetColor(pl:Team())

		colTemp.r = col.r * mul
		colTemp.g = col.g * mul
		colTemp.b = col.b * mul
	end

	if self.Hovered then
		mul = math.min(1, mul * 1.5)
	end
	
	local col = colTemp
	col.a = 85
	draw.RoundedBox(4, 0, 0, w, h, col)

	return true
end

vgui.Register("ZMPlayerLine", PANEL, "DPanel")

local PANEL = {}

local function NoPanelDraw(self, w, h)
	return true
end
function PANEL:Init()
	self.Header = self:Add("Panel")
	self.Header:Dock(TOP)
	self.Header:SetHeight(100)

	self.Name = self.Header:Add( "DLabel" )
	self.Name:SetFont("ZMScoreBoardTitle")
	self.Name:SetTextColor(COLOR_GRAY)
	self.Name:Dock(TOP)
	self.Name:SetHeight(40)
	self.Name:SetContentAlignment(5)
	self.Name:SetExpensiveShadow(2, Color(0, 0, 0, 200))
	
	self.HeadersPan = self:Add("DPanel")
	self.HeadersPan:SetPos(0, 64)
	self.HeadersPan.Paint = NoPanelDraw
	
	self.NameCol = self.HeadersPan:Add("DLabel")
	self.NameCol:Dock(FILL)
	self.NameCol:SetFont("ZMScoreBoardPlayer")
	self.NameCol:DockMargin(85, 0, 0, 0)
	self.NameCol:SetColor(color_white)
	self.NameCol:SetText(translate.Get("scoreboard_name"))

	self.PingCol = self.HeadersPan:Add("DLabel")
	self.PingCol:Dock(RIGHT)
	self.PingCol:SetFont("ZMScoreBoardPlayer")
	self.PingCol:SetColor(color_white)
	self.PingCol:SetText(translate.Get("scoreboard_ping"))
	
	self.MuteCol = self.HeadersPan:Add("DLabel")
	self.MuteCol:Dock(RIGHT)
	self.MuteCol:SetFont("ZMScoreBoardPlayer")
	self.MuteCol:SetColor(color_white)
	self.MuteCol:SetText(translate.Get("scoreboard_mute"))

	self.DeathsCol = self.HeadersPan:Add("DLabel")
	self.DeathsCol:Dock(RIGHT)
	self.DeathsCol:SetFont("ZMScoreBoardPlayer")
	self.DeathsCol:SetColor(color_white)
	self.DeathsCol:SetText(translate.Get("scoreboard_deaths"))

	self.KillsCol = self.HeadersPan:Add("DLabel")
	self.KillsCol:Dock(RIGHT)
	self.KillsCol:SetFont("ZMScoreBoardPlayer")
	self.KillsCol:SetColor(color_white)
	self.KillsCol:SetText(translate.Get("scoreboard_kills"))
	
	self.PlayerList = self:Add("DScrollPanel")
	self.PlayerList:SetPos(0, 84)
	
	self.m_HumanHeading = self.PlayerList:Add("DTeamHeading")
	self.m_HumanHeading:Dock(TOP)
	self.m_HumanHeading:SetTeam(TEAM_SURVIVOR)

	self.SurvivorsList = self.PlayerList:Add("DPanel")
	self.SurvivorsList:Dock(TOP)
	self.SurvivorsList:DockMargin(0, 0, 0, 4)
	self.SurvivorsList.Paint = NoPanelDraw
	
	self.m_ZombieHeading = self.PlayerList:Add("DTeamHeading")
	self.m_ZombieHeading:Dock(TOP)
	self.m_ZombieHeading:SetTeam(TEAM_ZOMBIEMASTER)
	
	self.ZombieMasterList = self.PlayerList:Add("DPanel")
	self.ZombieMasterList:Dock(TOP)
	self.ZombieMasterList:DockMargin(0, 0, 0, 4)
	self.ZombieMasterList.Paint = NoPanelDraw
	
	self.m_SpectatorHeading = self.PlayerList:Add("DTeamHeading")
	self.m_SpectatorHeading:Dock(TOP)
	self.m_SpectatorHeading:SetTeam(TEAM_SPECTATOR)
	
	self.SpectatorsList = self.PlayerList:Add("DPanel")
	self.SpectatorsList:Dock(TOP)
	self.SpectatorsList:DockMargin(0, 0, 0, 4)
	self.SpectatorsList.Paint = NoPanelDraw
end

function PANEL:PerformLayout()
	self.PlayerList:SetSize(self:GetWide(), self:GetTall() - 84)
	self.HeadersPan:SetSize(self:GetWide(), 20)
	
	self.SurvivorsList:SetWide(self:GetWide())
	self.ZombieMasterList:SetWide(self:GetWide())
	self.SpectatorsList:SetWide(self:GetWide())
	
	self.m_HumanHeading:MoveAbove(self.SurvivorsList, 5)
	self.m_HumanHeading:SetWide(self:GetWide())
	self.SurvivorsList:MoveBelow(self.m_HumanHeading, 5)
	
	self.m_ZombieHeading:MoveAbove(self.ZombieMasterList, 5)
	self.m_ZombieHeading:SetWide(self:GetWide())
	self.ZombieMasterList:MoveBelow(self.m_ZombieHeading, 5)
	
	self.m_SpectatorHeading:MoveAbove(self.SpectatorsList, 5)
	self.m_SpectatorHeading:SetWide(self:GetWide())
	self.SpectatorsList:MoveBelow(self.m_SpectatorHeading, 5)
end

function PANEL:Paint(w, h)
	draw.RoundedBoxEx(8, 0, 64, w, h - 64, Color(5, 5, 5, 180), false, false, true, true)
	draw.RoundedBoxEx(8, 0, 0, w, 64, Color(5, 5, 5, 220), true, true, false, false)
end

function PANEL:Think()
	self.Name:SetText(GetHostName())

	local plyrs = player.GetAll()
	for id, pl in pairs(plyrs) do
		if IsValid(pl.ScoreEntry) then continue end

		pl.ScoreEntry = vgui.Create("ZMPlayerLine")
		pl.ScoreEntry:Setup(pl)
		pl.ScoreEntry:Dock(TOP)
		pl.ScoreEntry:DockMargin(8, 2, 8, 2)

		if pl:IsSurvivor() then
			self.SurvivorsList:Add(pl.ScoreEntry)
		elseif pl:IsZM() then
			self.ZombieMasterList:Add(pl.ScoreEntry)
		else
			self.SpectatorsList:Add(pl.ScoreEntry)
		end
	end
	
	if IsValid(self.SurvivorsList) then self.SurvivorsList:SizeToChildren(false, true) end
	if IsValid(self.ZombieMasterList) then self.ZombieMasterList:SizeToChildren(false, true) end
	if IsValid(self.SpectatorsList) then self.SpectatorsList:SizeToChildren(false, true) end
end

vgui.Register("ZMScoreBoard", PANEL, "EditablePanel")

function GM:ScoreboardShow()
	gui.EnableScreenClicker(true)
	
	if not IsValid(g_Scoreboard) then
		g_Scoreboard = vgui.Create("ZMScoreBoard")
	end
	
	if IsValid(g_Scoreboard) then
		g_Scoreboard:SetSize(math.min(ScrW(), ScrH()) - 5, ScrH() * 0.9)
		g_Scoreboard:AlignTop(ScrH() * 0.05)
		g_Scoreboard:CenterHorizontal()
		g_Scoreboard:SetAlpha(0)
		g_Scoreboard:AlphaTo(255, 0.5, 0)
		g_Scoreboard:SetVisible(true)
	end
end

function GM:ScoreboardHide()
	if not LocalPlayer():IsZM() then
		gui.EnableScreenClicker(false)
	end
	
	if IsValid(g_Scoreboard) then
		g_Scoreboard:Hide()
	end
end

function GM:HUDDrawScoreBoard()
end