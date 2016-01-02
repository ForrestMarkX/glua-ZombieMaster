ENT.Type = "anim"

function ENT:HumanHoldable(pl)
	return pl:KeyDown(IN_USE)
end
