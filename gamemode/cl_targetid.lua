local function DrawTargetID(ent, text, fraction, x, y, xalign, yalign)
    local green = fraction * 255
    local healthCol = Color(255 - green, green, 0)
    
    draw.SimpleTextOutlined(text, "DermaLarge", x, y, healthCol, xalign, yalign, 1, color_black)
end

function GM:HUDDrawTargetID()
    if LocalPlayer():IsZM() then 
        hook.Call("DrawZMTargetID", self) 
        return 
    elseif LocalPlayer():IsSpectator() and IsValid(LocalPlayer():GetObserverTarget()) then
        hook.Call("DrawSpectatorTargetID", self)
        return
    end
    
    local tr = util.GetPlayerTrace(LocalPlayer())
    tr.mins = Vector(-12, -12, 0)
    tr.maxs = Vector(12, 12, 72)
    tr.filter = function(ent)
        return ent:IsPlayer() and ent ~= LocalPlayer()
    end
    
    local trace = util.TraceHull(tr)
    if not trace.Hit or not trace.HitNonWorld then return end
    
    local ent = trace.Entity
    if not IsValid(ent) then return end
    
    local health = ent:Health()
    local healthtext = health < 20 and "Critical" or health < 50 and "Wounded" or health < 75 and "Injured" or "Healthy"
    DrawTargetID(ent, ent:Nick() .. " (" .. healthtext .. ")", math.Clamp(health / ent:GetMaxHealth(), 0, 1), ScrW() * 0.01, ScrH() * 0.5, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end

function GM:DrawZMTargetID()
    local mousepos = gui.ScreenToVector(gui.MousePos())
    local tr = util.TraceHull({
        filter = function(ent)
            return ent:IsPlayer() or ent:IsNPC()
        end,
        start = LocalPlayer():GetShootPos(),
        endpos = LocalPlayer():GetShootPos() + (mousepos * 56756),
        mins = Vector(-18, -18, 0), maxs = Vector(18, 18, 72)
    })
    
    if not tr.Hit or not tr.HitNonWorld then 
        if not self.DrawingPowerTooltip and IsValid(self.ToolPan_Center_Tip) then self.ToolPan_Center_Tip:SetVisible(false) end
        return 
    end
    
    local ent = tr.Entity
    if not IsValid(ent) then return end
    
    if not (ent:IsPlayer() or ent:IsNPC()) then
        if not self.DrawingPowerTooltip then
            if IsValid(self.ToolPan_Center_Tip) then self.ToolPan_Center_Tip:SetVisible(false) end
        end
        
        return
    end
    
    self.ToolPan_Center_Tip:SetVisible(true)
    if ent:IsPlayer() then
        self.ToolLab_Center_Tip:SetText(translate.Format("targetid_tooltip_human", ent:Name()))
        self.ToolLab_Center_Tip:SizeToContents()
    elseif ent:IsNPC() then
        local name = "ERROR"
        local datatable = self:GetZombieTable()
        for _, data in pairs(datatable) do
            if data.Class == ent:GetClass() then
                name = data.Name
                break
            end
        end
        
        self.ToolLab_Center_Tip:SetText(translate.Format("targetid_tooltip_"..string.lower(name), name))
        self.ToolLab_Center_Tip:SizeToContents()
    end
    
    self.ToolPan_Center_Tip:InvalidateLayout(true)
    self.ToolPan_Center_Tip:SizeToChildren(true, false)
    self.ToolPan_Center_Tip:SetSize(self.ToolPan_Center_Tip:GetWide() + 15, self.ToolPan_Center_Tip:GetTall())
    self.ToolLab_Center_Tip:Center()
    self.ToolPan_Center_Tip:Center()
    self.ToolPan_Center_Tip:AlignBottom(10)
end

function GM:DrawSpectatorTargetID()
    local ent = LocalPlayer():GetObserverTarget()
    local name = ""
    local maxhealth = 0
    local healthtext = ent:Health()
    if ent:IsPlayer() then
        name = ent:Name()
        maxhealth = ent:GetMaxHealth()
        
        if ent:IsZM() then
            healthtext = "Zombie Master"
        end 
    elseif ent:IsNPC() then
        local tab = self:GetZombieData(ent:GetClass())
        if tab then
            name = tab.Name
            maxhealth = tab.Health
        end
    end
    
    local text = name .. " (" .. healthtext .. ")"
    DrawTargetID(ent, text, math.Clamp(ent:Health() / maxhealth, 0, 1), ScrW() * 0.5, ScrH() * 0.95, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
end