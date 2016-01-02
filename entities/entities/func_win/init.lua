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
	gamemode.Call("TeamVictorious", true, "The living have prevailed!\n")
end

function ENT:InputHumanLose()
	gamemode.Call("TeamVictorious", false, "The living have failed their objectives!\n")
end
