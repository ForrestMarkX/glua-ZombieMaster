local PANEL = {}

AccessorFunc(PANEL, "m_iFlags",     "Zombieflags",     FORCE_NUMBER)
AccessorFunc(PANEL, "m_iCurrent",     "Current")

function PANEL:Paint(w, h)
    draw.RoundedBox(0, 0, 0, w, h, Color(60, 0, 0, 200))
end

local function PaintButton(self, w, h)
    if self.m_bDisabled then
        boxColor = Color(58, 0, 0)
        surfaceColor = Color(26, 0, 0, 250)
        self:SetTextColor(Color(60, 60, 60))
    elseif self:IsHovered() then
        boxColor = Color(173, 0, 0)
        surfaceColor = Color(78, 0, 0, 250)
        self:SetTextColor(color_white)
    else
        boxColor = Color(115, 0, 0)
        surfaceColor = Color(52, 0, 0, 250)
        self:SetTextColor(color_white)
    end
    
    draw.OutlinedBox(0, 0, w, h, 2, boxColor)
    surface.SetDrawColor(surfaceColor)
    surface.DrawRect(2, 2, w - 3, h - 3)
end
local function ThinkButton(self)
    self.BaseClass.Think(self)
        
    if not self.DontDisabled then
        if #self.ParentQueue:GetItems() <= 0 then
            self:SetEnabled(false)
        else
            self:SetEnabled(true)
        end
    end
    
    if self.bActive ~= not self.m_bDisabled then
        self.bActive = not self.m_bDisabled
        if not self.bActive then
            self:AlphaTo(185, 0.75, 0)
            self:SetTextColor(Color(60, 60, 60))
        else
            self:AlphaTo(255, 0.75, 0)
            self:SetTextColor(color_white)
        end
    end
end
function PANEL:Init()
    self:SetSize(411, 300)
    self:SetTitle("Spawn Menu")
    self:MakePopup()
    
    self.imageBackground = vgui.Create("DPanel", self)
    self.imageBackground:SetSize(142, 142)
    self.imageBackground:SetPos(146, 30)
    self.imageBackground.Paint = function() 
        surface.SetDrawColor(Color(52, 0, 0, 250))
        surface.DrawRect(0, 0, ScrW() - 5, ScrH() - 5)
    end
    
    self.buttons = vgui.Create("DPanelList", self)
    self.buttons:SetPos(4, 28)
    self.buttons:SetSize(self:GetWide() * 0.31, self:GetTall() * 0.75)
    self.buttons:SetPadding(2)
    self.buttons:SetSpacing(4)
    self.buttons:EnableVerticalScrollbar(true)
    
    self.buttons.Paint = function(self, w, h)
        DisableClipping(true)
        draw.DrawSimpleRect(w + 5, 0, 1, h, color_black)
        DisableClipping(false)
    end
    
    self.queue = vgui.Create("DIconLayout", self)
    self.queue:SetPos(self:GetWide() - 98, 24)
    self.queue:SetSize(125, self:GetTall() - 62)
    self.queue:SetSpaceY(0)
    self.queue:SetSpaceX(0)
    
    self.bardraw = vgui.Create("DPanel", self)
    self.bardraw:SetPos(self:GetWide() - 98, 24)
    self.bardraw:SetSize(125, self:GetTall() - 62)
    
    self.bardraw.Paint = function(self, w, h)
        DisableClipping(true)
        draw.DrawSimpleRect(-3, 0, 1, self:GetParent():GetTall() - 62, color_black)
        DisableClipping(false)
    end
    
    self.removeOne = vgui.Create("DButton", self)
    self.removeOne.ParentQueue = self.queue
    self.removeOne:SetPos(self:GetWide() - 90, self:GetTall() - 62)
    self.removeOne:SetSize(80, 20)
    self.removeOne:SetText("Remove Last")
    self.removeOne:SetTextColor(color_white)
    self.removeOne.DontDisabled = true
    self.removeOne.Paint = PaintButton
    self.removeOne.DoClick = function()
        if LocalPlayer():IsZM() then
            if self.queue.PanelList and #self.queue.PanelList > 0 then
                net.Start("zm_rqueue")
                    net.WriteEntity(self:GetCurrent())
                    net.WriteBool(false)
                net.SendToServer()
                
                self:UpdateQueue()
            end
        end
    end
    
    self.clearQueue = vgui.Create("DButton", self)
    self.clearQueue.ParentQueue = self.queue
    self.clearQueue:SetPos(self:GetWide() - 90, self:GetTall() - 38)
    self.clearQueue:SetSize(80, 20)
    self.clearQueue:SetText("Clear")
    self.clearQueue:SetTextColor(color_white)
    self.clearQueue.DontDisabled = true
    self.clearQueue.Paint = PaintButton
    self.clearQueue.DoClick = function()
        if LocalPlayer():IsZM() then
            if self.queue.PanelList and #self.queue.PanelList > 0 then
                for _, img in pairs(self.queue.PanelList) do
                    img:Remove()
                end
                
                net.Start("zm_rqueue")
                    net.WriteEntity(self:GetCurrent())
                    net.WriteBool(true)
                net.SendToServer()
            end
        end
    end
    
    self.placeRally = vgui.Create("DButton", self)
    self.placeRally.ParentQueue = self.queue
    self.placeRally:SetPos(self:GetWide() - 372, self:GetTall() - 38)
    self.placeRally:SetSize(95, 32)
    self.placeRally:SetText("Place Rally Point")
    self.placeRally:SetTextColor(color_white)
    self.placeRally.Paint = PaintButton
    self.placeRally.DoClick = function()
        if LocalPlayer():IsZM() then
            RunConsoleCommand("zm_power_rallypoint", self:GetCurrent():EntIndex())
            self:SetVisible(false)
            
            GAMEMODE.ZombiePanelMenu = self
        end
    end
    
    self.closebut = vgui.Create("DButton", self)
    self.closebut.ParentQueue = self.queue
    self.closebut:SetPos(self:GetWide() - 250, self:GetTall() - 38)
    self.closebut:SetSize(128, 32)
    self.closebut:SetText("Close")
    self.closebut:SetTextColor(color_white)
    self.closebut.Paint = PaintButton
    self.closebut.DoClick = function()
        if LocalPlayer():IsZM() then
            self:Close()
        end
    end
end

function PANEL:Populate()
    local zombieData = GAMEMODE:GetZombieTable()
    
    for k, data in SortedPairsByMemberValue(zombieData, "Cost", false) do
        local buttonBase = vgui.Create("DPanel")
        buttonBase:SetTall(28)
        buttonBase.Paint = function() end
        
        local buttonSingle = vgui.Create("DButton", buttonBase)
        buttonSingle:SetSize(75, 28)
        buttonSingle:SetText(data.Name)
        buttonSingle.Paint = PaintButton
        buttonSingle.Think = ThinkButtonZombie
        buttonSingle.DoClick = function()
            net.Start("zm_spawnzombie")
                net.WriteEntity(self:GetCurrent())
                net.WriteString(data.Class)
                net.WriteUInt(1, 6)
            net.SendToServer()
        end
        
        buttonSingle.OnCursorEntered = function()
            self.image = vgui.Create("DImage", self)
            self.image:SetImage(data.Icon)
            self.image:SetPos(154, 30)
            self.image:SetSize(142, 142)

            self.base = vgui.Create("DPanel", self)
            self.base:SetPos(128, self:GetTall() - 145)
            self.base:SetSize(200, 106)
            self.base.Paint = function() end
            
            self.costLabel = Label("Resources: " .. data.Cost, self.base)
            self.costLabel:SetFont("DermaDefaultBold")
            self.costLabel:SizeToContents()
            self.costLabel:SetPos(13, 20)
            
            self.popLabel = Label("Population: " .. data.PopCost, self.base)
            self.popLabel:SetFont("DermaDefaultBold")
            self.popLabel:SizeToContents()
            self.popLabel:SetPos(13, 40)
            
            self.desc = Label(data.Description, self.base)
            self.desc:SetFont("DermaDefaultBold")
            self.desc:SizeToContents()
            self.desc:SetPos(13, 60)
            self.desc:DockMargin(13, 60, 12, 0)
            self.desc:Dock(FILL)
            self.desc:SetContentAlignment(7)
            self.desc:SetWrap(true)
        end
        
        buttonSingle.OnCursorExited = function()
            if (self.image) then
                self.image:Remove()
            end
            
            if (self.base) then
                self.base:Remove()
            end
        end

        local buttonFive = vgui.Create("DButton", buttonBase)
        buttonFive:SetSize(25, 28)
        buttonFive:SetText("x 5")
        buttonFive.Paint = PaintButton
        buttonFive.Think = ThinkButtonZombie
        buttonFive.DoClick = function()
            net.Start("zm_spawnzombie")
                net.WriteEntity(self:GetCurrent())
                net.WriteString(data.Class)
                net.WriteUInt(5, 6)
            net.SendToServer()
        end
        
        buttonFive:MoveRightOf(buttonSingle, 5)
        
        if not gamemode.Call("CanSpawnZombie", data.Flag or 0, self:GetZombieflags()) then
            buttonSingle:SetDisabled(true)
            buttonFive:SetDisabled(true)
        end
        
        buttonFive.OnCursorEntered = buttonSingle.OnCursorEntered
        buttonFive.OnCursorExited  = buttonSingle.OnCursorExited
        
        self.buttons:AddItem(buttonBase)
    end
end

function PANEL:AddQueue(type)
    local data = GAMEMODE:GetZombieData(type)
    local smallImage = "VGUI/zombies/queue_"..string.lower(data.Name)
    
    local image = vgui.Create("DImage")
    image:SetImage(smallImage)
    image:SetSize(32, 32)
    image.Paint = function(self, w, h)
        draw.OutlinedBox(0, 0, w, h, 1, Color(115, 0, 0))
        surface.SetDrawColor(Color(52, 0, 0, 250))
        surface.DrawRect(1, 1, w - 2, h - 2)

        self:PaintAt(0, 0, w, h)
    end
    
    self.queue:Add(image)
    
    if not self.queue.PanelList then self.queue.PanelList = {} end
    self.queue.PanelList[#self.queue.PanelList + 1] = image
end

function PANEL:UpdateQueue()
    if not self.queue.PanelList then return end
    
    local items = self.queue.PanelList
    local item
    for i=1, #items do
        if IsValid(items[i]) then
            item = items[i]
            break
        end
    end
    
    if not IsValid(item) then return end
    
    item:Remove()
end

function PANEL:Close()
    self:SetVisible(false)
end

function PANEL:Think()
    if self:IsVisible() then
        LocalPlayer().bIsDragging = false
    end
end

vgui.Register("zm_zombiemenu", PANEL, "DFrame")