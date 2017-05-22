local PANEL = {}

function PANEL:Init()
	self.toolpan = vgui.Create("DPanel")
	self.toolpan:SetSize(ScrW() * 0.1, ScrH() * 0.03)
	self.toolpan:InvalidateLayout(true)
	self.toolpan:Center()
	self.toolpan:AlignBottom(10)
	
	self.toollab = vgui.Create("DLabel", self.toolpan)
	self.toollab:SetTextColor(color_white)
	self.toollab:SetFont("ZMHUDFontSmaller")
	self.toollab:SizeToContents()
	
	self.toolpan:InvalidateLayout(true)
	self.toolpan:SizeToChildren(true, false)
	self.toolpan:SetSize(self.toolpan:GetWide() + 15, self.toolpan:GetTall())
	self.toollab:Center()
	self.toolpan:Center()
	self.toolpan:AlignBottom(10)
end

function PANEL:Paint()
	return true
end

function PANEL:SetTooltip(text)
	self.toollab:SetText(text)
end

vgui.Register("zm_toolpanel", PANEL, "Panel")