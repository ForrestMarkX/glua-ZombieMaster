AddCSLuaFile()

ENT.Type = "anim"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:Initialize()
	self:SetModel( "models/spawnnode.mdl" )
	self:SetSolid( SOLID_NONE )
	self:SetMoveType( MOVETYPE_FLY )
	self:DrawShadow( false )
	
	if SERVER then
		self.nodeName = nil or self.nodeName
	end
end

if SERVER then
	function ENT:KeyValue( key, value )
		key = string.lower(key)
		if key == "nodename" then
			self.nodeName = value or self.nodeName
		end
	end

	function ENT:GetSpawnNode()
		if self.nodeName then
			local pNodeEnt = ents.FindByName(self.nodeName)[1]
			
			if IsValid(pNodeEnt) then
				return pNodeEnt
			end
		else
			return nil
		end
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