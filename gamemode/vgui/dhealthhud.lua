local PANEL = {}

function PANEL:Init()
    self:SetBackgroundColor(Color(70, 0, 0, 150))
    self:SetBackgroundImage("zmr_effects/hud_bg_hp")
    
    self.HealthIcon = vgui.Create("CHudHealthIcon", self)
    
    self.HealthLabel = vgui.Create("CHudHealthLabel", self)
    self.HealthLabel:SetFont("ZMHudNumbers")
    self.HealthLabel:SetText(LocalPlayer():Health())
    
    self:ParentToHUD()
end

function PANEL:SetBackgroundImage(mat)
    self.m_iImage = Material(mat)
end

function PANEL:GetBackgroundImage()
    return self.m_iImage
end

function PANEL:PerformLayout()    
    self:SetSize(ScrW() * 0.175, ScrH() * 0.1)
    self:AlignBottom(ScreenScale(6))
    
    self.HealthIcon:SetSize(self:GetTall() * 0.7, self:GetTall() * 0.7)
    self.HealthIcon:AlignLeft(ScreenScale(18))
    self.HealthIcon:CenterVertical()
    
    self.HealthLabel:SizeToContents()
    self.HealthLabel:MoveRightOf(self.HealthIcon, ScreenScale(4))
    self.HealthLabel:CenterVertical()
end

function PANEL:Think()
    if not LocalPlayer():IsSurvivor() or cvars.Number("zm_hudtype", 0) ~= HUD_ZMR then
        self:Remove()
        return
    end
    
    local health = LocalPlayer():Health()
    if health ~= self.OldHealth then
        self.OldHealth = health
        self.HealthLabel:SetText(LocalPlayer():Health())
        self:InvalidateLayout()
    end
end

function PANEL:Paint(w, h)
    surface.SetDrawColor(self:GetBackgroundColor())
    surface.SetMaterial(self:GetBackgroundImage())
    surface.DrawTexturedRect(0, 0, w, h)
    
    return true
end

vgui.Register("CHudHealthInfo", PANEL, "DPanel")

local PANEL = {}

local healthIconBG = Material("zmr_effects/hpbar_bg")
local healthIcon = Material("zmr_effects/hpbar_fg")
local healthIconCritical = Material("zmr_effects/hpbar_fg_critical")
function PANEL:Paint(dw, dh)
    surface.SetDrawColor(color_white)

    local w = healthIcon:Width()
    local h = healthIcon:Height()
    local x = 0
    local y = 0

    if w > dw and h > dh then
        if w > dw then
            local diff = dw / w
            w = w * diff
            h = h * diff
        end

        if h > dh then
            local diff = dh / h
            w = w * diff
            h = h * diff
        end
    end

    if w < dw then
        local diff = dw / w
        w = w * diff
        h = h * diff
    end

    if h < dh then
        local diff = dh / h
        w = w * diff
        h = h * diff
    end

    local OffX = (dw - w) * 0.5
    local OffY = (dh - h) * 0.5
    
    local maxhp = LocalPlayer():GetMaxHealth()
    local hp = math.Clamp(LocalPlayer():Health(), 0, maxhp)
    local frac = 1 - (hp / maxhp)
    local iscrit = hp < (maxhp * 0.35)
    
    if not iscrit then
        surface.SetMaterial(healthIcon)
        surface.DrawTexturedRect(OffX + x, OffY + y, w, h)
    end
    
    if hp <= 0 then return end

    local fill_y = math.Round(h * frac)

    surface.SetMaterial(healthIconBG)
    surface.DrawTexturedRectUV(OffX + (x-1), OffY + (y-1), (w+2), (h+2) * frac, 0, 0, 1, frac)
    
    if iscrit then
        surface.SetMaterial(healthIconCritical)
        surface.DrawTexturedRect(OffX + x, OffY + y, w, h)
    end
    
    return true
end

vgui.Register("CHudHealthIcon", PANEL, "DPanel")

local PANEL = {}

function PANEL:Paint(w, h)
    local health = tonumber(self:GetText())
    if LocalPlayer().CurrentHP ~= health then
        LocalPlayer().CurrentHP = health
        
        LocalPlayer().LastHurtTime = CurTime()
        LocalPlayer().HurtTimer = CurTime() + 5
    end
    
    local healthCol = health <= 10 and Color(185, 0, 0, 255) or health <= 30 and Color(150, 50, 0) or health <= 60 and Color(255, 200, 0) or color_white
    if health <= 10 then
        local sinScale = math.floor(math.abs(math.sin(CurTime() * 8)) * 128)
        healthCol.a = math.Clamp(sinScale, 90, 230)
    end
    
    DisableClipping(true)
    draw.SimpleTextBlurry(health, self:GetFont(), 0, 0, healthCol, -1, -1, LocalPlayer().LastHurtTime, LocalPlayer().HurtTimer)
    DisableClipping(false)
    
    return true
end

vgui.Register("CHudHealthLabel", PANEL, "DLabel")