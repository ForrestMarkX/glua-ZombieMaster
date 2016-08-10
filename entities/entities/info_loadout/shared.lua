ENT.Type = "point"

function ENT:Initialize() 
	self:SetSolid( SOLID_NONE )
	self:AddEffects( EF_NODRAW )
	self:SetMoveType( MOVETYPE_NONE )
	
	if SERVER then
		self.weaponsCategorised = {}
		self.m_iWeaponsAll = {}
		self:FillWeaponLists()
		
		self.m_iMethod = self.m_iMethod or 0
	end
end