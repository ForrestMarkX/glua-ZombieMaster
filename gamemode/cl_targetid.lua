function GM:HUDDrawTargetID()
    if LocalPlayer():IsZM() then hook.Call("DrawZMTargetID", self) return end
    
    if LocalPlayer():IsSpectator() and IsValid(LocalPlayer():GetObserverTarget()) then
        hook.Call("DrawSpectatorTargetID", self)
        return
    end
    
    local tr = util.GetPlayerTrace(LocalPlayer())
    local trace = util.TraceLine(tr)
    
    if not trace.Hit or not trace.HitNonWorld then return end
    
    local ent = trace.Entity
    if not IsValid(ent) then return end
    if not ent:IsPlayer() then return end
    
    local text = ent:Nick() or "ERROR"
    local font = "TargetID"
    
    local health = ent:Health()
    local healthtext = health < 20 and "Critical" or health < 50 and "Wounded" or health < 75 and "Injured" or "Healthy"
    local green = math.Clamp(ent:Health() / ent:GetMaxHealth(), 0, 1) * 255
    local healthCol = Color(255 - green, green, 0)
    
    surface.SetFont(font)
    draw.DrawText(text.." ("..healthtext..")", "DermaLarge", ScrW() / 96, ScrH() / 1.88, healthCol)
end

function GM:DrawZMTargetID()
    local mousepos = gui.ScreenToVector(gui.MousePos())
    local tr = util.TraceLine({
        start = LocalPlayer():GetShootPos(),
        endpos = LocalPlayer():GetShootPos() + (mousepos * 56756)
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
    if not ent:IsPlayer() then return end
    
    local text = ent:Nick() or "ERROR"
    local font = "TargetID"
    
    local health = ent:Health()
    local healthtext = health < 20 and "Critical" or health < 50 and "Wounded" or health < 75 and "Injured" or "Healthy"
    local green = math.Clamp(ent:Health() / ent:GetMaxHealth(), 0, 1) * 255
    local healthCol = Color(255 - green, green, 0)
    
    surface.SetFont(font)
    draw.DrawText(text.." ("..healthtext..")", "DermaLarge", ScrW() / 96, ScrH() / 1.88, healthCol)
end