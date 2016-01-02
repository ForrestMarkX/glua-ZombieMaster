ENT.Type = "point"

function ENT:Initialize()
	self:SetSolid( SOLID_NONE )
	self:AddEffects( EF_NODRAW )
	self:SetMoveType( MOVETYPE_NONE )
end

function ENT:AcceptInput(name, caller, activator, arg)
	name = string.lower(name)
	if name == "giveresources" then
		self:InputGiveResources(tonumber(arg))
		return true
	end
end

function ENT:InputGiveResources(amount)
	local ply = GAMEMODE:FindZM()
	if IsValid(ply) then
		ply:SetZMPoints(ply:GetZMPoints() + amount)
	end
end