local PANEL = {}

function PANEL:Init()
    local hinticon = vgui.Create("DImage", self)
    hinticon:SetSize(ScreenScale(11), ScreenScale(11))
    hinticon:SetImage("vgui/tt_icon_light.png")
    hinticon:SetImageColor(Color(255, 255, 255))
    hinticon:AlignLeft(2)
    
    self.HintIcon = hinticon
    
    local hinttext = vgui.Create("DLabel", self)
    hinttext:SetFont("zm_game_text_small")
    hinttext:SizeToContents()
    hinttext:MoveRightOf(hinticon)
    
    self.HintLabel = hinttext
    
    self.bActive = false
    
    self.GlowTime = 0
    self.HoldTime = 0
    self.CurHoldTime = 0
    
    self:SetAlpha(0)
end

function PANEL:SetHint(text)
    self.HintLabel:SetText(text)
    self.HintLabel:SizeToContents()
end

function PANEL:SetActive(b, time)
    if b and self.bActive then return end
    
    self.bActive = b
    
    if b then
        self.HoldTime = time or 0
        self.CurHoldTime = RealTime() + (time or 0)
        self:InvalidateLayout(true)
        self:AlphaTo(255, 1, 0)
        surface.PlaySound("buttons/blip1.wav")
    else
        self:SetAlpha(0)
    end
    
    self:SetVisible(b)
end

function PANEL:Think()
    if self.bActive then
        local glow = math.Clamp(math.sin(RealTime() * 2) * 200 + 255, 0, 255)
        local col = Color(255, glow, glow)
        
        self.HintLabel:SetTextColor(col)
        
        if self.CurHoldTime ~= 0 and self.CurHoldTime < RealTime() then
            self.CurHoldTime = 0
            
            self:AlphaTo(0, 1, self.HoldTime, function(animData, pnl)
                pnl:SetActive(false, 0)
            end)
        end
    end
end

function PANEL:PerformLayout(w, h)
    self:SizeToChildren(true, true)
    self:SetSize(self:GetWide() + 8, self:GetTall() + 8)
    self:Center()
    self:AlignBottom(ScrH() * 0.25)
    
    self.HintIcon:AlignLeft(2)
    self.HintLabel:MoveRightOf(self.HintIcon)
    
    self.HintIcon:CenterVertical()
    self.HintLabel:CenterVertical()
end

vgui.Register("zm_tippanel", PANEL, "DPanel")