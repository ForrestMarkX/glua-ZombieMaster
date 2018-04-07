if CLIENT then return end

ENT.Type = "brush"

function ENT:Initialize()
    self:SetTrigger(true)
    self.Entities = {}
end

function ENT:IsTouchedBy(ent)
    return table.HasValue(self.Entities, ent)
end

function ENT:StartTouch(ent)
    if not self:PassesTriggerFilters(ent) then return end
    table.insert(self.Entities, ent)
    
    self:Input("OnStartTouch", self, ent)
end

function ENT:Touch(ent)
    if not self:PassesTriggerFilters(ent) then return end
    if not table.HasValue(self.Entities, ent) then table.insert(self.Entities, ent) end
    
    self:Input("OnTouch", self, ent)
end

function ENT:EndTouch(ent)
    if not self:IsTouchedBy(ent) then return end
    table.RemoveByValue(self.Entities, ent)
    
    self:Input("OnEndTouch", self, ent)

    local bFoundOtherTouchee = false
    local iSize = #self.Entities
    for i=iSize, 0, -1 do 
        local hOther = self.Entities[i]
        if not IsValid(hOther) then
            table.RemoveByValue(self.Entities, hOther)
        else
            bFoundOtherTouchee = true
        end
    end

    if not bFoundOtherTouchee then
        self:Input("OnEndTouchAll", self, ent)
    end
end