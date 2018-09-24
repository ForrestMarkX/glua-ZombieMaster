chat.OldAddText = chat.OldAddText or chat.AddText
function chat.AddText(...)
    if IsValid(GAMEMODE.PlayerLobby) then
        GAMEMODE.PlayerLobby:AddChatText({...})
        return
    end
    chat.OldAddText(...)
end

local clrBG = Color(60, 0, 0, 220)
local clrOutline = Color(150, 0, 0, 255)
local matGradr = Material("VGUI/gradient-r")
local matGradl = Material("VGUI/gradient-l")
local texRightEdge = surface.GetTextureID("gui/gradient")
local function DrawFadedLine(self, w, h)
    surface.SetDrawColor(clrOutline)
    
    surface.SetMaterial(matGradr)
    surface.DrawTexturedRect(0, h - 2, w * 0.5, 2)
    
    surface.SetMaterial(matGradl)
    surface.DrawTexturedRect(w * 0.5, h - 2, w * 0.5, 2)
end
local function LobbyMenuPaint(self)
    return true
end
local function OutlinedDraw(self, w, h)
    surface.SetDrawColor(clrOutline)
    
    surface.SetMaterial(matGradr)
    surface.DrawTexturedRect(0, 1, w * 0.5, 2)
    
    surface.SetMaterial(matGradl)
    surface.DrawTexturedRect(w * 0.5, 1, w * 0.5, 2)
    
    draw.RoundedBox(8, 0, 0, w, h, clrBG)
    draw.RoundedBoxHollow(3, -1, -1, w + 2, h + 2, clrOutline)
    
    surface.SetDrawColor(clrOutline)
    
    surface.SetMaterial(matGradr)
    surface.DrawTexturedRect(0, h - 2, w * 0.5, 2)
    
    surface.SetMaterial(matGradl)
    surface.DrawTexturedRect(w * 0.5, h - 2, w * 0.5, 2)
end
local function BasicOutline(self, w, h)
    draw.OutlinedBox(0, 0, w, h, self.OutlineThickness or 1, clrOutline)
end
local function AddPlayerToList(self, pl)
    if IsValid(self.PlayerPanels[pl]) then return end
    
    local panel = vgui.Create("LobbyPlayerPanel", self)
    panel:SetPlayer(pl)
    panel:Dock(TOP)
    panel:DockMargin(6, 3, 6, 3)
    
    self.PlayerPanels[pl] = panel
end
local function OpenLobby()
    if IsValid(GAMEMODE.PlayerLobby) then
        GAMEMODE.PlayerLobby:SetVisible(true)
        return
    end
    
    local lobbypanel = vgui.Create("DFrame")
    lobbypanel.btnClose:SetVisible(false)
    lobbypanel.btnMaxim:SetVisible(false)
    lobbypanel.btnMinim:SetVisible(false)
    lobbypanel:SetDraggable(false)
    lobbypanel:SetTitle(" ")
    lobbypanel:SetSize(ScrW(), ScrH())
    lobbypanel:Center()
    lobbypanel.Paint = LobbyMenuPaint
    lobbypanel.AddChatText = function(self, tab)
        self.ChatBox:AppendMessage(tab)
    end
    --lobbypanel:ParentToHUD()
    
    GAMEMODE.PlayerLobby = lobbypanel
    lobbypanel:MakePopup()
    
    local playerbackground = vgui.Create("DPanel", lobbypanel)
    playerbackground:SetSize(lobbypanel:GetWide() * 0.255, lobbypanel:GetTall() * 0.5525)
    playerbackground:AlignLeft(ScreenScale(40))
    playerbackground:AlignTop(ScreenScale(16))
    playerbackground.Paint = OutlinedDraw
    
    local timetostart = vgui.Create("DLabel", playerbackground)
    timetostart:SetFont("zm_hud_font_normal")
    timetostart:SetText("Waiting for Players...")
    timetostart:SizeToContents()
    timetostart:CenterHorizontal()
    
    local lastwarntim = -1
    function timetostart:Think()
        if player.GetCount()  > 1 and GAMEMODE:GetReadyCount() ~= -1 then
            local time = math.max(0, GAMEMODE:GetReadyCount() - CurTime())
            local col = color_white
            
            if time < 5 then
                local glow = math.sin(RealTime() * 8) * 200 + 255
                col = Color(255, glow, glow)
            else
                col = color_white
            end
            
            self:SetText(string.FormattedTime(time, "%02i:%02i"))
            self:SetTextColor(col)
            self:SizeToContents()
            self:CenterHorizontal()
        end
    end
    
    local playercontainer = vgui.Create("DScrollPanel", playerbackground)
    playercontainer.PlayerPanels = {}
    playercontainer:SetSize(playerbackground:GetWide() * 0.98, (playerbackground:GetTall() - (timetostart:GetTall() * 2)) * 0.98)
    playercontainer:CenterHorizontal()
    playercontainer:AlignBottom(ScreenScale(4))
    playercontainer.Paint = function() return true end
    playercontainer.AddPlayer = AddPlayerToList
    playercontainer.Think = function(self)
        if RealTime() >= (self.NextRefresh or 0) then
            self.NextRefresh = RealTime() + 0.5
            for _, pl in pairs(player.GetAll()) do
                self:AddPlayer(pl)
            end
        end
    end
    
    timetostart:AlignTop((playercontainer:GetTall() - timetostart:GetTall()) * 0.0325)
    
    for _, pl in pairs(player.GetAll()) do
        playercontainer:AddPlayer(pl)
    end
    
    local mapinfopanel = vgui.Create("DPanel", lobbypanel)
    mapinfopanel:SetSize(lobbypanel:GetWide() * 0.6, lobbypanel:GetTall() * 0.075)
    mapinfopanel:AlignRight(ScreenScale(40))
    mapinfopanel:AlignTop(ScreenScale(16))
    mapinfopanel.Paint = OutlinedDraw
    
    local maplabel = Label("Map: "..game.GetMap(), mapinfopanel)
    maplabel:SetFont("zm_hud_font_small")
    maplabel:SizeToContents()
    maplabel:SetTextColor(color_white)
    maplabel:AlignLeft(6)
    maplabel:CenterVertical(0.375)
    
    local playercount = Label("Player Count: 0/"..game.MaxPlayers(), mapinfopanel)
    playercount:SetFont("zm_hud_font_smaller")
    playercount:SizeToContents()
    playercount:SetTextColor(color_white)
    playercount:AlignLeft(6)
    playercount:CenterVertical(0.675)
    playercount.Think = function(self)
        local count = player.GetCount()
        if count ~= oldcount then
            oldcount = count
            self:SetText("Player Count: "..count.."/"..game.MaxPlayers())
            self:SizeToContents()
        end
    end
    
    local hostname = Label(GetHostName(), mapinfopanel)
    hostname:SetFont("zm_hud_font_small")
    hostname:SizeToContents()
    hostname:SetTextColor(color_white)
    hostname:AlignRight(6)
    hostname:CenterVertical()
    
    local motdpanel = vgui.Create("DPanel", lobbypanel)
    motdpanel:SetSize(lobbypanel:GetWide() * 0.6, (lobbypanel:GetTall() * 0.725) + 5)
    motdpanel:MoveBelow(mapinfopanel, 2)
    motdpanel:AlignRight(ScreenScale(40))
    motdpanel.Paint = OutlinedDraw
    
    local motd = vgui.Create("DHTML", motdpanel)
    motd:SetSize(motdpanel:GetWide() - ScreenScale(6), motdpanel:GetTall() - ScreenScale(6))
    motd:Center()
    motd:OpenURL(GetConVar("zm_motd_url"):GetString() or "")
    lobbypanel.MOTD = motd
    
    local chatboxpanel = vgui.Create("DPanel", lobbypanel)
    chatboxpanel:SetSize(lobbypanel:GetWide() * 0.255, lobbypanel:GetTall() * 0.25)
    chatboxpanel:AlignLeft(ScreenScale(40))
    chatboxpanel:MoveBelow(playerbackground, 5)
    chatboxpanel.Paint = OutlinedDraw
    
    local saypanel = vgui.Create("DPanel", chatboxpanel)
    saypanel:SetSize(chatboxpanel:GetWide() * 0.15, chatboxpanel:GetTall() * 0.1)
    saypanel:AlignLeft(2)
    saypanel:AlignBottom(2)
    saypanel.Paint = BasicOutline
    
    local saylabel = Label("Say:", saypanel)
    saylabel:SetFont("zm_hud_font_tiny")
    saylabel:SizeToContents()
    saylabel:SetTextColor(color_white)
    saylabel:Center()
    
    local textpanel = vgui.Create("DPanel", chatboxpanel)
    textpanel:SetSize(chatboxpanel:GetWide() * 0.83, chatboxpanel:GetTall() * 0.1)
    textpanel:MoveRightOf(saypanel, 2)
    textpanel:AlignBottom(2)
    textpanel.Paint = BasicOutline
    
    local textentry = vgui.Create("DTextEntry", textpanel)
    textentry:SetTextColor(color_black)
    textentry:SetHistoryEnabled(true)
    textentry:SetSize(textpanel:GetSize())
    textentry.OnEnter = function(self)
        LocalPlayer():ConCommand("say "..self:GetValue())
        
        self:AddHistory(self:GetValue())
        self:SetText("")
        
        timer.Simple(FrameTime() * 4, function()
            if not IsValid(self) then return end
            self:RequestFocus()
            self:SetCaretPos(string.len(self:GetValue()))
        end)
    end
    
    local richtext = vgui.Create("RichText", chatboxpanel)
    richtext:AlignTop(5)
    richtext:SetSize(chatboxpanel:GetWide(), (chatboxpanel:GetTall() - textentry:GetTall()) - 5)
    richtext.AppendMessage = function(self, tab)
        for _, info in pairs(tab) do
            if IsColor(info) then
                self:InsertColorChange(info.r, info.g, info.b, 255)
            else
                self:AppendText(IsEntity(info) and info:IsPlayer() and info:Nick() or tostring(info))
                self:InsertColorChange(255, 255, 255, 255)
            end
        end
        
        self:AppendText("\n")
    end
    richtext.PerformLayout = function(self, w, h)
        self:SetFontInternal( "zm_hud_font_tiny" )
        self:SetFGColor( Color( 255, 255, 255 ) )
    end
    lobbypanel.ChatBox = richtext
    
    local bottomspace = vgui.Create("DPanel", lobbypanel)
    bottomspace:SetSize(lobbypanel:GetWide(), lobbypanel:GetTall() * 0.05)
    bottomspace:AlignBottom()
    bottomspace.Paint = OutlinedDraw
    
    local disconnectb = vgui.Create("DButton", bottomspace)
    disconnectb:Dock(RIGHT)
    disconnectb:DockMargin(ScreenScale(2), ScreenScale(3), ScreenScale(2), ScreenScale(3))
    disconnectb:SetFont("zm_hud_font_tiny")
    disconnectb:SetText("Disconnect")
    disconnectb:SizeToContents()
    
    function disconnectb:DoClick()
        RunConsoleCommand("disconnect")
    end
    
    local readyb = vgui.Create("DButton", bottomspace)
    readyb:Dock(RIGHT)
    readyb:DockMargin(ScreenScale(2), ScreenScale(3), ScreenScale(2), ScreenScale(3))
    readyb:SetFont("zm_hud_font_tiny")
    readyb:SetText(GAMEMODE.playerReadyList[LocalPlayer()] and "Un-Ready" or "Ready")
    readyb:SizeToContents()
    readyb:SetTextColor(Color(0, 255, 0))
    
    function readyb:DoClick()
        if GAMEMODE:GetGameStarting() or (self.Cooldown or 0) > CurTime() then return end
        
        local MySelf = LocalPlayer()
        GAMEMODE.playerReadyList[MySelf] = not GAMEMODE.playerReadyList[MySelf]
        
        if GAMEMODE.playerReadyList[MySelf] then
            surface.PlaySound("buttons/button17.wav")
        else
            surface.PlaySound("buttons/button18.wav")
        end
        
        self:SetTextColor(GAMEMODE.playerReadyList[MySelf] and Color(255, 0, 0) or Color(0, 255, 0))
        self:SetText(GAMEMODE.playerReadyList[MySelf] and "Un-Ready" or "Ready")
        self:SizeToContents()
        
        net.Start("zm_playeready")
            net.WriteBool(GAMEMODE.playerReadyList[MySelf])
        net.SendToServer()
        
        self.Cooldown = CurTime() + 1
    end
    
    local optionsb = vgui.Create("DButton", bottomspace)
    optionsb:Dock(RIGHT)
    optionsb:DockMargin(ScreenScale(2), ScreenScale(3), ScreenScale(2), ScreenScale(3))
    optionsb:SetFont("zm_hud_font_tiny")
    optionsb:SetText("Options")
    optionsb:SizeToContents()
    
    function optionsb:DoClick()
        MakepOptions()
    end
    
    local changecharacter = vgui.Create("DButton", bottomspace)
    changecharacter:Dock(RIGHT)
    changecharacter:DockMargin(ScreenScale(2), ScreenScale(3), ScreenScale(2), ScreenScale(3))
    changecharacter:SetFont("zm_hud_font_tiny")
    changecharacter:SetText("Change Character")
    changecharacter:SizeToContents()
    
    function changecharacter:DoClick()
        RunConsoleCommand("playermodel_selector")
    end
end
GM.OpenLobbyMenu = OpenLobby

local PANEL = {}

function PANEL:Init()
    self:SetTall(32)
    
    self.m_AvatarButton = self:Add("DButton", self)
    self.m_AvatarButton:SetText(" ")
    self.m_AvatarButton:SetSize(32, 32)
    self.m_AvatarButton:CenterVertical()
    self.m_AvatarButton.DoClick = function(pan)
        local pl = self:GetPlayer()
        if IsValid(pl) and pl:IsPlayer() then
            pl:ShowProfile()
        end
    end
    self.m_AvatarButton.Paint = function(self, w, h)
        draw.OutlinedBox(0, 0, w, h, 3, clrOutline)
    end
    self.m_AvatarButton.PlayerPanel = self

    self.m_Avatar = vgui.Create("AvatarImage", self.m_AvatarButton)
    self.m_Avatar:SetSize(28, 28)
    self.m_Avatar:Center()
    self.m_Avatar:SetVisible(false)
    self.m_Avatar:SetMouseInputEnabled(false)
    
    self.m_PlayerLabel = Label(" ", self)
    self.m_PlayerLabel:SetFont("zm_hud_font_tiny")
    self.m_PlayerLabel:SetTextColor(color_white)
    
    self.m_ReadyLabel = Label("Not Ready", self)
    self.m_ReadyLabel:SetFont("zm_hud_font_smaller")
    self.m_ReadyLabel:SetTextColor(Color(255, 0, 0))
end

function PANEL:Paint(w, h)
    surface.SetDrawColor(clrOutline)
    
    surface.SetMaterial(matGradl)
    surface.DrawTexturedRect(0, 0, w, 2)
    surface.SetMaterial(matGradl)
    surface.DrawTexturedRect(0, h - 2, w, 2)
end

function PANEL:Think()
    if IsValid(self.m_Player) then
        local bReady = GAMEMODE.playerReadyList[self.m_Player]
        if self.OldReady ~= bReady then
            self.OldReady = bReady
            self.m_ReadyLabel:SetText(bReady and "Ready" or "Not Ready")
            self.m_ReadyLabel:SetTextColor(bReady and Color(0, 255, 0) or Color(255, 0, 0))
            self.m_ReadyLabel:SizeToContents()
        end
        
        if self.m_Player:Nick() ~= "UNCONNECTED" then
            self:InvalidateLayout()
        end
    else
        self:Remove()
    end
end

function PANEL:PerformLayout(w, h)
    self.m_AvatarButton:CenterVertical()
    
    self.m_PlayerLabel:SetText(self.m_Player and self.m_Player:Nick() or "")
    self.m_PlayerLabel:SizeToContents()
    self.m_PlayerLabel:MoveRightOf(self.m_AvatarButton, 8)
    self.m_PlayerLabel:CenterVertical()
    
    self.m_ReadyLabel:SizeToContents()
    self.m_ReadyLabel:AlignRight(8)
    self.m_ReadyLabel:CenterVertical()
end

function PANEL:SetPlayer(pl)
    self.m_Player = pl or NULL

    if IsValid(pl) and pl:IsPlayer() then
        if pl:IsBot() then
            self.m_ReadyLabel:SetText("Ready")
            self.m_ReadyLabel:SetTextColor(Color(0, 255, 0))
            self.m_ReadyLabel:SizeToContents()
        end
        
        self.m_Avatar:SetPlayer(pl)
        self.m_Avatar:SetVisible(true)
        
        self.m_PlayerLabel:SetText(pl:Nick())
        self.m_PlayerLabel:SizeToContents()
        self.m_PlayerLabel:MoveRightOf(self.m_AvatarButton, 8)
        self.m_PlayerLabel:CenterVertical()
    else
        self.m_Avatar:SetVisible(false)
    end
end

function PANEL:GetPlayer()
    return self.m_Player
end

vgui.Register("LobbyPlayerPanel", PANEL, "Panel")