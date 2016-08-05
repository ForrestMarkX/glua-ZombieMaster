local ScoreBoard
function GM:ScoreboardShow()
	gui.EnableScreenClicker(true)

	if not ScoreBoard then
		ScoreBoard = vgui.Create("ZMScoreBoard")
	end

	ScoreBoard:SetSize(math.min(ScrW(), ScrH()) - 5, ScrH() * 0.9)
	ScoreBoard:AlignTop(ScrH() * 0.05)
	ScoreBoard:CenterHorizontal()
	ScoreBoard:SetAlpha(0)
	ScoreBoard:AlphaTo(255, 0.5, 0)
	ScoreBoard:SetVisible(true)
end

function GM:ScoreboardHide()
	if not MySelf:IsZM() then
		gui.EnableScreenClicker(false)
	end

	if ScoreBoard then
		ScoreBoard:SetVisible(false)
	end
end

local PANEL = {}

PANEL.RefreshTime = 0.5
PANEL.NextRefresh = 0
PANEL.m_MaximumScroll = 0

local function BlurPaint(self)
	draw.SimpleText(self:GetValue(), self.Font, 0, 0, self:GetTextColor())
	return true
end
local function emptypaint(self)
	return true
end

function PANEL:Init()
	self.NextRefresh = RealTime() + 0.1

	self.m_TitleLabel = vgui.Create("DLabel", self)
	self.m_TitleLabel.Font = "ZMScoreBoardTitle"
	self.m_TitleLabel:SetFont(self.m_TitleLabel.Font)
	self.m_TitleLabel:SetText(GetHostName())
	self.m_TitleLabel:SetTextColor(COLOR_GRAY)
	self.m_TitleLabel:SizeToContents()
	self.m_TitleLabel:NoClipping(true)
	self.m_TitleLabel.Paint = BlurPaint

	self.m_HumanHeading = vgui.Create("DTeamHeading", self)
	self.m_HumanHeading:SetTeam(TEAM_SURVIVOR)

	self.m_ZombieHeading = vgui.Create("DTeamHeading", self)
	self.m_ZombieHeading:SetTeam(TEAM_ZOMBIEMASTER)
	
	self.m_SpectatorHeading = vgui.Create("DTeamHeading", self)
	self.m_SpectatorHeading:SetTeam(TEAM_SPECTATOR)

	self.ZombieList = vgui.Create("DScrollPanel", self)
	self.ZombieList.Team = TEAM_ZOMBIEMASTER

	self.HumanList = vgui.Create("DScrollPanel", self)
	self.HumanList.Team = TEAM_SURVIVOR
	
	self.SpectatorList = vgui.Create("DScrollPanel", self)
	self.SpectatorList.Team = TEAM_SPECTATOR

	self:InvalidateLayout()
end

function PANEL:PerformLayout()
	self.m_HumanHeading:SetSize(self:GetWide() / 2 - 25, 28)
	self.m_HumanHeading:SetPos(self:GetWide() * 0.25 - self.m_HumanHeading:GetWide() * 0.5, 110 - self.m_HumanHeading:GetTall())

	self.m_ZombieHeading:SetSize(self:GetWide() / 2 - 25, 28)
	self.m_ZombieHeading:SetPos(self:GetWide() * 0.75 - self.m_ZombieHeading:GetWide() * 0.5, 110 - self.m_ZombieHeading:GetTall())

	self.m_SpectatorHeading:SetSize(self:GetWide() / 2 - 25, 28)
	self.m_SpectatorHeading:SetPos(self:GetWide() * 0.75 - self.m_SpectatorHeading:GetWide() * 0.5, 210 - self.m_SpectatorHeading:GetTall())
	
	self.HumanList:SetSize(self:GetWide() / 2 - 24, self:GetTall() - 150)
	self.HumanList:AlignBottom(16)
	self.HumanList:AlignLeft(8)

	self.ZombieList:SetSize(self:GetWide() / 2 - 24, self:GetTall() - (self:GetTall() - 40))
	self.ZombieList:AlignTop(133)
	self.ZombieList:AlignRight(8)
	
	self.SpectatorList:SetSize(self:GetWide() / 2 - 24, self:GetTall() - 249)
	self.SpectatorList:AlignBottom(16)
	self.SpectatorList:AlignRight(8)
end

function PANEL:Think()
	if RealTime() >= self.NextRefresh then
		self.NextRefresh = RealTime() + self.RefreshTime
		self:Refresh()
	end
end

function PANEL:Paint()
	local wid, hei = self:GetSize()
	draw.RoundedBoxEx(8, 0, 64, wid, hei - 64, Color(5, 5, 5, 180), false, false, true, true)
	draw.RoundedBoxEx(8, 0, 0, wid, 64, Color(5, 5, 5, 220), true, true, false, false)
end

function PANEL:GetPlayerPanel(pl)
	for _, panel in pairs(self.PlayerPanels) do
		if panel:Valid() and panel:GetPlayer() == pl then
			return panel
		end
	end
end

function PANEL:CreatePlayerPanel(pl)
	local curpan = self:GetPlayerPanel(pl)
	if curpan and curpan:Valid() then return curpan end

	local panel = vgui.Create("ZSPlayerPanel", pl:IsZM() and self.ZombieList or pl:IsSurvivor() and ScoreBoard.HumanList or ScoreBoard.SpectatorList)
	panel:SetPlayer(pl)
	panel:Dock(TOP)
	panel:DockMargin(8, 2, 8, 2)

	self.PlayerPanels[pl] = panel

	return panel
end

function PANEL:Refresh()
	self.m_TitleLabel:SetText(GetHostName())
	self.m_TitleLabel:SizeToContents()
	self.m_TitleLabel:SetPos(math.min(self:GetWide() - self.m_TitleLabel:GetWide(), self:GetWide() * 0.5 - self.m_TitleLabel:GetWide() * 0.5), 32 - self.m_TitleLabel:GetTall() / 2)

	if self.PlayerPanels == nil then self.PlayerPanels = {} end

	for ply, panel in pairs(self.PlayerPanels) do
		if not panel:Valid() then
			self:RemovePlayerPanel(panel)
		end
	end

	for _, pl in pairs(player.GetAll()) do
		self:CreatePlayerPanel(pl)
	end
end

function PANEL:RemovePlayerPanel(panel)
	if panel:Valid() then
		self.PlayerPanels[panel:GetPlayer()] = nil
		panel:Remove()
	end
end

vgui.Register("ZMScoreBoard", PANEL, "Panel")

local PANEL = {}

PANEL.RefreshTime = 1

PANEL.m_Player = NULL
PANEL.NextRefresh = 0

local function MuteDoClick(self)
	local pl = self:GetParent():GetPlayer()
	if pl:IsValid() then
		pl:SetMuted(not pl:IsMuted())
		self:GetParent().NextRefresh = RealTime()
	end
end

local function AvatarDoClick(self)
	local pl = self.PlayerPanel:GetPlayer()
	if pl:IsValid() and pl:IsPlayer() then
		pl:ShowProfile()
	end
end

local function empty() end

function PANEL:Init()
	self:SetTall(32)

	self.m_AvatarButton = self:Add("DButton", self)
	self.m_AvatarButton:SetText(" ")
	self.m_AvatarButton:SetSize(32, 32)
	self.m_AvatarButton:Center()
	self.m_AvatarButton.DoClick = AvatarDoClick
	self.m_AvatarButton.Paint = empty
	self.m_AvatarButton.PlayerPanel = self

	self.m_Avatar = vgui.Create("AvatarImage", self.m_AvatarButton)
	self.m_Avatar:SetSize(32, 32)
	self.m_Avatar:SetVisible(false)
	self.m_Avatar:SetMouseInputEnabled(false)

	self.m_SpecialImage = vgui.Create("DImage", self)
	self.m_SpecialImage:SetSize(16, 16)
	self.m_SpecialImage:SetMouseInputEnabled(true)
	self.m_SpecialImage:SetVisible(false)

	self.m_PlayerLabel = EasyLabel(self, " ", "ZMScoreBoardPlayer", COLOR_WHITE)
	self.m_ScoreLabel = EasyLabel(self, " ", "ZMScoreBoardPlayerSmall", COLOR_WHITE)
	self.m_DeathLabel = EasyLabel(self, " ", "ZMScoreBoardPlayerSmall", COLOR_WHITE)

	self.m_PingMeter = vgui.Create("DPingMeter", self)
	self.m_PingMeter.PingBars = 5

	self.m_Mute = vgui.Create("DImageButton", self)
	self.m_Mute.DoClick = MuteDoClick
end

local colTemp = Color(255, 255, 255, 220)
function PANEL:Paint()
	local col = Color(0, 0, 0, 180)
	local mul = 0.5
	local pl = self:GetPlayer()
	if pl:IsValid() then
		col = team.GetColor(pl:Team())

		if self.m_Flash then
			mul = 0.6 + math.abs(math.sin(RealTime() * 6)) * 0.4
		elseif pl == MySelf then
			mul = 0.8
		end
	end

	if self.Hovered then
		mul = math.min(1, mul * 1.5)
	end

	colTemp.r = col.r * mul
	colTemp.g = col.g * mul
	colTemp.b = col.b * mul
	
	self.m_PlayerLabel:SetColor(colTemp)

	return true
end

function PANEL:DoClick()
	local pl = self:GetPlayer()
	if pl:IsValid() then
		gamemode.Call("ClickedPlayerButton", pl, self)
	end
end

function PANEL:PerformLayout()
	self.m_AvatarButton:AlignLeft(16)
	self.m_AvatarButton:CenterVertical()

	self.m_PlayerLabel:SizeToContents()
	self.m_PlayerLabel:MoveRightOf(self.m_AvatarButton, 4)
	self.m_PlayerLabel:CenterVertical()
	
	self.m_ScoreLabel:SizeToContents()
	self.m_ScoreLabel:SetPos(self:GetWide() * 0.575 - self.m_ScoreLabel:GetWide() / 2, 0)
	self.m_ScoreLabel:CenterVertical()
	
	self.m_DeathLabel:SizeToContents()
	self.m_DeathLabel:MoveRightOf(self.m_ScoreLabel, 50)
	self.m_DeathLabel:CenterVertical()

	self.m_SpecialImage:CenterVertical()

	local pingsize = self:GetTall() - 4

	self.m_PingMeter:SetSize(pingsize, pingsize)
	self.m_PingMeter:AlignRight(8)
	self.m_PingMeter:CenterVertical()

	self.m_Mute:SetSize(16, 16)
	self.m_Mute:MoveLeftOf(self.m_PingMeter, 8)
	self.m_Mute:CenterVertical()
end

function PANEL:Refresh()
	local pl = self:GetPlayer()
	if not pl:IsValid() then
		self:Remove()
		return
	end

	local name = pl:Name()
	local maxlength = math.ceil((ScrW() / 500) * 5)
	
	if ScrW() < 500 then
		maxlength = #name
	end
	
	if #name > maxlength then
		name = string.sub(name, 1, maxlength)..".."
	end
	self.m_PlayerLabel:SetText(name)
	self.m_ScoreLabel:SetText(pl:Frags())
	self.m_DeathLabel:SetText(pl:Deaths())
	
	if not pl:IsSurvivor() then
		self.m_ScoreLabel:SetVisible(false)
		self.m_DeathLabel:SetVisible(false)
	else
		self.m_ScoreLabel:SetVisible(true)
		self.m_DeathLabel:SetVisible(true)
	end

	if pl == LocalPlayer() then
		self.m_Mute:SetVisible(false)
	else
		if pl:IsMuted() then
			self.m_Mute:SetImage("icon16/sound_mute.png")
		else
			self.m_Mute:SetImage("icon16/sound.png")
		end
	end

	self:SetZPos(-pl:Frags())

	if pl:Team() ~= self._LastTeam then
		self._LastTeam = pl:Team()
		self:SetParent(self._LastTeam == TEAM_SURVIVOR and ScoreBoard.HumanList or self._LastTeam == TEAM_ZOMBIEMASTER and ScoreBoard.ZombieList or ScoreBoard.SpectatorList)
	end

	self:InvalidateLayout()
end

function PANEL:Think()
	if RealTime() >= self.NextRefresh then
		self.NextRefresh = RealTime() + self.RefreshTime
		self:Refresh()
	end
end

function PANEL:SetPlayer(pl)
	self.m_Player = pl or NULL

	if pl:IsValid() and pl:IsPlayer() then
		self.m_Avatar:SetPlayer(pl)
		self.m_Avatar:SetVisible(true)

		if gamemode.Call("IsSpecialPerson", pl, self.m_SpecialImage) then
			self.m_SpecialImage:SetVisible(true)
		else
			self.m_SpecialImage:SetTooltip()
			self.m_SpecialImage:SetVisible(false)
		end

		self.m_Flash = pl:SteamID() == "STEAM_0:1:3307510" or pl:IsAdmin() or pl:IsSuperAdmin() 
	else
		self.m_Avatar:SetVisible(false)
		self.m_SpecialImage:SetVisible(false)
	end

	self.m_PingMeter:SetPlayer(pl)

	self:Refresh()
end

function PANEL:GetPlayer()
	return self.m_Player
end

vgui.Register("ZSPlayerPanel", PANEL, "Button")
