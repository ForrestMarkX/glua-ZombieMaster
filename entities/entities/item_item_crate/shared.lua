ENT.Type = "anim"

function ENT:SetObjectHealth(health)
    self:SetDTFloat(0, health)
    if health <= 0 and not self.Destroyed then
        self.Destroyed = true

        local ent = ents.Create("prop_physics")
        if ent:IsValid() then
            ent:SetModel(self:GetModel())
            ent:SetMaterial(self:GetMaterial())
            ent:SetAngles(self:GetAngles())
            ent:SetPos(self:GetPos())
            ent:SetSkin(self:GetSkin() or 0)
            ent:SetColor(self:GetColor())
            ent:Spawn()
            ent:Fire("break", "", 0)
            ent:Fire("kill", "", 0.1)
        end
    end
end

function ENT:GetObjectHealth()
    return self:GetDTFloat(0)
end

function ENT:SetMaxObjectHealth(health)
    self:SetDTFloat(1, health)
end

function ENT:GetMaxObjectHealth()
    return self:GetDTFloat(1)
end

function ENT:SetObjectOwner(ent)
    self:SetDTEntity(0, ent)
end

function ENT:GetObjectOwner()
    return self:GetDTEntity(0)
end