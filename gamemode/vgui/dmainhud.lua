local PANEL = {}

local function PaintPanel(self, w, h)
	draw.DrawSimpleRect(0, 0, w, h, Color(60, 0, 0, 200))
	draw.DrawSimpleOutlined(0, 0, w, h, color_black)
end
function PANEL:Init()
	self.PopulationPanel = vgui.Create("DPanel", self)
	self.PopulationPanel.Paint = PaintPanel
	
	self.InfoPanel = vgui.Create("DPanel", self)
	self.InfoPanel.Paint = PaintPanel
	
	self.SkullIcon = vgui.Create("DImage", self.InfoPanel)
	self.SkullIcon:SetImage("VGUI/miniskull")
	
	self.PopulationIcon = vgui.Create("DImage", self.PopulationPanel)
	self.PopulationIcon:SetImage("VGUI/minifigures")
	
	self.PopulationLabel = vgui.Create("DLabel", self.PopulationPanel)
	self.PopulationLabel:SetFont("zm_powerhud_smaller")
	
	self.CurrentPointsLabel = vgui.Create("DLabel", self.InfoPanel)
	self.CurrentPointsLabel:SetFont("zm_powerhud_small")
	
	self.IncomeLabel = vgui.Create("DLabel", self.InfoPanel)
	self.IncomeLabel:SetFont("zm_powerhud_smaller")
end

function PANEL:PerformLayout()	
	self:SetSize(ScrW() * 0.15, ScrH() * 0.1)
	self:AlignBottom(3)
	
	self.PopulationPanel:SetSize(self:GetWide() * 0.55, self:GetTall() * 0.3)
	self.PopulationPanel:MoveAbove(self.InfoPanel, -1)
	self.PopulationPanel:AlignLeft(2)
	
	self.PopulationIcon:SetSize(ScreenScale(6), ScreenScale(6))
	self.PopulationIcon:Center()
	self.PopulationIcon:AlignLeft(4)
	
	self.SkullIcon:SetSize(ScreenScale(11), ScreenScale(11))
	self.SkullIcon:Center()
	self.SkullIcon:AlignLeft(4)
	
	self.InfoPanel:SetSize(self:GetWide() * 0.65, self:GetTall() * 0.4)
	self.InfoPanel:AlignBottom(2)
	self.InfoPanel:AlignLeft(2)
end

function PANEL:Think()
	self.PopulationLabel:SetText(GAMEMODE:GetCurZombiePop() .. "/" .. GAMEMODE:GetMaxZombiePop())
	self.PopulationLabel:SizeToContentsX(5)
	self.PopulationLabel:CenterVertical()
	self.PopulationLabel:CenterHorizontal(0.55)
	
	self.CurrentPointsLabel:SetText(LocalPlayer():GetZMPoints())
	self.CurrentPointsLabel:SizeToContentsX(5)
	self.CurrentPointsLabel:CenterHorizontal(0.35)
	self.CurrentPointsLabel:CenterVertical(0.35)
	
	self.IncomeLabel:SetText("+ " .. LocalPlayer():GetZMPointIncome())
	self.IncomeLabel:SizeToContentsX(5)
	self.IncomeLabel:CenterHorizontal(0.55)
	self.IncomeLabel:CenterVertical(0.65)
end

function PANEL:Paint()
	return true
end

vgui.Register("zm_mainhud", PANEL, "DPanel")