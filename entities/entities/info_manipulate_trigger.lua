AddCSLuaFile()

ENT.Base = "info_node_base"
ENT.Type = "anim"
ENT.Model = Model("models/trap.mdl")

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	
	if SERVER then
		self:NextThink( CurTime() + 0.5 )
	end
end

if SERVER then
	function ENT:Trigger()
		local m_pParentManipulate = self:GetParent()
		if m_pParentManipulate and m_pParentManipulate:GetActive() then
			m_pParentManipulate:Trigger(self)
		end

		self:Remove()
	end

	function ENT:Think()
		for _, pl in pairs(ents.FindInSphere(self:GetPos(), GetConVar("zm_trap_triggerrange"):GetInt())) do
			if pl:IsPlayer() and pl:IsSurvivor() then
				self:Trigger()
				return
			end
		end

		self:NextThink( CurTime() + 0.5 )
		return true
	end
end