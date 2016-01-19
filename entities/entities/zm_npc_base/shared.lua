ENT.Base = "base_ai"
ENT.Type = "ai"

ENT.AutomaticFrameAdvance = true

function ENT:SetupDataTables()
	self:NetworkVar("Vector", 0, "DamageForce")
end