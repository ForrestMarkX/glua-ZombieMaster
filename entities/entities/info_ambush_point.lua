AddCSLuaFile()

ENT.Base = "info_node_base"
ENT.Type = "anim"
ENT.Model = Model("models/trap.mdl")

ENT.GlowSize = 48
ENT.OrbSize = 12

function ENT:Initialize()
	self.BaseClass.Initialize(self)
	
	if SERVER then
		self:NextThink( CurTime() + 0.5 )
	end
end

if SERVER then
	function ENT:Trigger(pl)
		if not self.EntOwners then self:Remove() return end
		
		for _, npc in pairs(self.EntOwners) do
			npc:UpdateEnemy(pl)
		end
		
		self:Remove()
	end

	function ENT:Think()
		for _, pl in pairs(ents.FindInSphere(self:GetPos(), GetConVar("zm_trap_triggerrange"):GetInt())) do
			if pl:IsPlayer() and pl:IsSurvivor() then
				self:Trigger(pl)
				return
			end
		end

		self:NextThink( CurTime() + 0.5 )
		return true
	end
end