surface.CreateFont("dexfont_med", {font = "impact", size = 19, weight = 0, antialias = false, shadow = false, outline = true})

local PANEL = {}

AccessorFunc(PANEL, "m_iBorderRadius", "BorderRadius", FORCE_NUMBER)
AccessorFunc(PANEL, "m_bCurveTopLeft", "CurveTopLeft", FORCE_BOOL)
AccessorFunc(PANEL, "m_bCurveTopRight", "CurveTopRight", FORCE_BOOL)
AccessorFunc(PANEL, "m_bCurveBottomLeft", "CurveBottomLeft", FORCE_BOOL)
AccessorFunc(PANEL, "m_bCurveBottomRight", "CurveBottomRight", FORCE_BOOL)

AccessorFunc(PANEL, "m_tColor", "Color")

function PANEL:Init()
	self:SetBorderRadius(8)
	self:SetCurve(true)

	self:SetColor(Color(0, 0, 0, 180))

	self:ShowCloseButton(false)
	self:SetTitle(" ")

	self.lblTitle:SetFont("dexfont_med")

	self:InvalidateLayout()
end

function PANEL:PerformLayout()
	self.lblTitle:SetWide(self:GetWide() - 25)
	self.lblTitle:SetPos(8, 2)
end

function PANEL:SetTitle(title)
	self.lblTitle:SetText(title)
	self.lblTitle:SizeToContents()

	self:InvalidateLayout()
end

function PANEL:SetCurve(curve)
	self:SetCurveTopLeft(curve)
	self:SetCurveTopRight(curve)
	self:SetCurveBottomLeft(curve)
	self:SetCurveBottomRight(curve)
end

function PANEL:SetColorAlpha(a)
	self:GetColor().a = a
end

function PANEL:Paint()
	draw.RoundedBoxEx(self:GetBorderRadius(), 0, 0, self:GetWide(), self:GetTall(), self:GetColor(), self:GetCurveTopLeft(), self:GetCurveTopRight(), self:GetCurveBottomLeft(), self:GetCurveBottomRight())
end

vgui.Register("DEXRoundedFrame", PANEL, "DFrame")
