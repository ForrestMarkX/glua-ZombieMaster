AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:KeyValue( key, value )
	key = string.lower(key)
	if key == "cost" then
		self:SetCost(value)
	elseif key == "trapcost" then
		self:SetTrapCost(value)
	elseif key == "active" then
		self:SetActive(tobool(value))
		
		if not self:GetActive() then
			self:AddSolidFlags( FSOLID_NOT_SOLID )
			self:AddEffects( EF_NODRAW )
		else
			self:RemoveSolidFlags( FSOLID_NOT_SOLID )
			self:RemoveEffects( EF_NODRAW )
		end
	elseif key == "removeontrigger" then
		self.m_bRemoveOnTrigger = tobool(value) or self.m_bRemoveOnTrigger
	elseif key == "description" then
		self:SetDescription(value)
	elseif string.Left(key, 2) == "on" then
		self:StoreOutput(key, value)
	end
end

function ENT:AcceptInput(name, caller, activator, arg)
	name = string.lower(name)
	if name == "toggle" then
		self:InputToggle()
		return true
	elseif name == "hide" then
		self:InputHide()
		return true
	elseif name == "unhide" then
		self:InputUnhide()
		return true
	elseif string.Left(name, 2) == "on" then
		self:TriggerOutput(name, activator, args)
	end
end

function ENT:InputToggle()
	if self:GetActive() then
		self:SetActive(false)
		self:AddSolidFlags( FSOLID_NOT_SOLID )
		self:AddEffects( EF_NODRAW )
	else
		self:SetActive(true)
		self:RemoveSolidFlags( FSOLID_NOT_SOLID )
		self:RemoveEffects( EF_NODRAW )
	end
end

function ENT:InputHide()
	if self:GetActive() then
		self:SetActive(false)
		self:AddSolidFlags( FSOLID_NOT_SOLID )
		self:AddEffects( EF_NODRAW )
	end
end

function ENT:InputUnhide()
	self:SetActive(true)
	self:RemoveSolidFlags( FSOLID_NOT_SOLID )
	self:RemoveEffects( EF_NODRAW )
end

function ENT:Trigger(activator)
	if not self:GetActive() then return end

	if self.m_bRemoveOnTrigger then
		self:Remove()
	end
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end