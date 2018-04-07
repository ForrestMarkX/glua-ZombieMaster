local PANEL = {}

AccessorFunc(PANEL, "m_Tooltip", "Tip")

function PANEL:OnCursorEntered()
    GAMEMODE.DrawingPowerTooltip = true
    GAMEMODE.ToolPan_Center_Tip:SetVisible(true)

    GAMEMODE.ToolLab_Center_Tip:SetText(self:GetTip())
    GAMEMODE.ToolLab_Center_Tip:SizeToContents()
    
    GAMEMODE.ToolPan_Center_Tip:InvalidateLayout(true)
    GAMEMODE.ToolPan_Center_Tip:SizeToChildren(true, false)
    GAMEMODE.ToolPan_Center_Tip:SetSize(GAMEMODE.ToolPan_Center_Tip:GetWide() + 15, GAMEMODE.ToolPan_Center_Tip:GetTall())
    GAMEMODE.ToolLab_Center_Tip:Center()
    GAMEMODE.ToolPan_Center_Tip:Center()
    GAMEMODE.ToolPan_Center_Tip:AlignBottom(10)
end

function PANEL:OnCursorExited()
    GAMEMODE.DrawingPowerTooltip = false
    GAMEMODE.ToolPan_Center_Tip:SetVisible(false)
end

function PANEL:Think()
    self:SetSize(ScreenScale(11), ScreenScale(11))
end
    
vgui.Register("zm_powerbutton", PANEL, "DImageButton")

local PANEL = {}

function PANEL:Paint(w, h)
    draw.DrawSimpleRect(0, 0, w, h, Color(60, 0, 0, self:IsActive() and 255 or 100))
    draw.DrawSimpleOutlined(0, 0, w, h - 1, color_black)
end

function PANEL:PerformLayout()
    self:ApplySchemeSettings()

    if not self.Image then return end

    self.Image:Center()

    if not self:IsActive() then
        self.Image:SetImageColor(Color(255, 255, 255, 155))
    else
        self.Image:SetImageColor(Color(255, 255, 255, 255))
    end
end

function PANEL:ApplySchemeSettings()
    local ExtraInset = 10

    if self.Image then
        ExtraInset = ExtraInset + self.Image:GetWide()
    end
    
    self:SetTextInset(ExtraInset, 4)
    self.Image:SetSize(ScreenScale(8), ScreenScale(8))
    
    local w, h = self:GetContentSize()
    self:SetSize(w, h + self.Image:GetTall())

    DLabel.ApplySchemeSettings(self)
end

vgui.Register("zm_powertab", PANEL, "DTab")

local PANEL = {}
local panellist = {}
    
function PANEL:Init()
    self:SetSize(ScrW() * 0.075, ScrH() * 0.15)
    self:AlignBottom(4)
    self:AlignRight(4)
    
    self.tabScroller:SetOverlap(-4)
end

function PANEL:AddItem(name, panel, category)
    for _, tab in pairs(self:GetItems()) do
        if tab.Name == "PowerTab"..category then
            tab.Panel.LayoutPan:Add(panel)
            
            if not panellist[name] then
                panellist[name] = {}
            end
            
            panellist[name][tab.Panel] = panel
        end
    end
end

function PANEL:RemoveItem(name, category)
    for _, tab in pairs(self:GetItems()) do
        if tab == "PowerTab"..category and IsValid(panellist[name][tab.Panel]) then
            panellist[name][tab.Panel]:Remove()
            panellist[name] = nil
        end
    end
end

function PANEL:AddSheet(label, panel, material, NoStretchX, NoStretchY, Tooltip )
    if not IsValid(panel) then
        ErrorNoHalt( "DPropertySheet:AddSheet tried to add invalid panel!" )
        debug.Trace()
        return
    end

    local Sheet = {}

    Sheet.Name = label

    Sheet.Tab = vgui.Create("zm_powertab", self)
    Sheet.Tab:SetTooltip(Tooltip)
    Sheet.Tab:Setup("", self, panel, material)

    Sheet.Panel = panel
    Sheet.Panel.NoStretchX = NoStretchX
    Sheet.Panel.NoStretchY = NoStretchY
    Sheet.Panel:SetPos(self:GetPadding(), 20 + self:GetPadding())
    Sheet.Panel:SetVisible(false)

    panel:SetParent(self)

    table.insert(self.Items, Sheet)

    if not self:GetActiveTab() then
        self:SetActiveTab(Sheet.Tab)
        Sheet.Panel:SetVisible(true)
    end

    self.tabScroller:AddPanel(Sheet.Tab)

    return Sheet
end

function PANEL:Paint(w, h)
    draw.DrawSimpleRect(0, self.tabScroller:GetTall(), w, h - self.tabScroller:GetTall(), Color(60, 0, 0, 200))
    draw.DrawSimpleOutlined(0, self.tabScroller:GetTall(), w, h - self.tabScroller:GetTall(), color_black)
end 

function PANEL:PerformLayout()
    self.BaseClass.PerformLayout(self)
    
    self:SetSize(ScrW() * 0.075, ScrH() * 0.15)
    self:AlignBottom(4)
    self:AlignRight(4)    
end

vgui.Register("zm_powerpanel", PANEL, "DPropertySheet")