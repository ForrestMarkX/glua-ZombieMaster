AddCSLuaFile()

ENT.Type = "anim"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:Initialize()
	self:SetModel( "models/rallypoint.mdl" )
	self:SetSolid( SOLID_NONE )
	self:SetMoveType( MOVETYPE_FLY )
	self:DrawShadow( false )

	if SERVER then
		self:SetCoordinates(self:GetPos())
	end
end

if SERVER then
	function ENT:GetCoordinates()
		return self.m_vecCoordinates
	end

	function ENT:SetCoordinates( vecNewRallyCoordinates )
		self.m_vecCoordinates = vecNewRallyCoordinates
		self:SetPos(vecNewRallyCoordinates)
	end

	function ENT:GetSpawnParent()
		return self.m_iOwner
	end

	function ENT:SetSpawnParent( entindex )
		self.m_iOwner = entindex
	end

	function ENT:ActivateRallyPoint()
		self.m_bActive = true
	end

	function ENT:DeactivateRallyPoint()
		self.m_bActive = true
	end
end

if CLIENT then
	function ENT:DrawTranslucent()
		if not LocalPlayer():IsZM() then return end
		
		render.SuppressEngineLighting(true)
		self:DrawModel()
		render.SuppressEngineLighting(false)
	end
end