ENT.Type = "anim"
ENT.Model = ""
ENT.RenderGroup = RENDERGROUP_BOTH

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "Cost")
	self:NetworkVar("Int", 1, "TrapCost")
	self:NetworkVar("Bool", 0, "Active")
	self:NetworkVar("String", 0, "Description")
end

function ENT:Initialize()
	self:SetModel(self.Model)
	self:AddSolidFlags(FSOLID_NOT_STANDABLE)
    self:SetSolid(SOLID_BBOX)
	self:SetMoveType(MOVETYPE_NOCLIP)
	self:SetCollisionBounds(Vector(-32, -32, -32), Vector(32, 32, 32))
	self:SetCollisionGroup(COLLISION_GROUP_WORLD)
	self:DrawShadow(false)
	self.IsTriggerNode = true
	self:CollisionRulesChanged()
	
	if SERVER then
		timer.Simple(1, function()
			if self.GetTrapCost and self:GetTrapCost() == 0 then
				self:SetTrapCost(self:GetCost() + 100)
			end
		end)
	end
end