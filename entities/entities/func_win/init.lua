ENT.Type = "point"

function ENT:Initialize()
	self:SetSolid( SOLID_NONE )
	self:AddEffects( EF_NODRAW )
	self:SetMoveType( MOVETYPE_NONE )
end

function ENT:AcceptInput(name, caller, activator, arg)
	name = string.lower(name)
	if name == "win" then
		self:InputHumanWin()
		return true
	elseif name == "lose" then
		self:InputHumanLose()
		return true
	end
end

function ENT:InputHumanWin()
	if GAMEMODE:GetRoundEnd() then return end
	gamemode.Call("TeamVictorious", true, "humans_have_won")
end

function ENT:InputHumanLose()
	if GAMEMODE:GetRoundEnd() then return end
	gamemode.Call("TeamVictorious", false, "humans_failed_obj")
end
