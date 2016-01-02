include("shared.lua")

ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

ENT.AnimTime = 0.25

function ENT:OnRemove()
	local owner = self:GetOwner()
	if owner == MySelf then
		if self.Rotating then
			hook.Remove("CreateMove", "HoldingCreateMove")
		end

		local wep = owner:GetActiveWeapon()
		if wep:IsValid() then
			if wep.NoHolsterOnCarry then
				self.NoHolster = true
			else
				wep:SendWeaponAnim(ACT_VM_DRAW)
			end
		end
	end

	self.BaseClass.OnRemove(self)
end

function ENT:Initialize()
	hook.Add("Move", self, self.Move)

	self.Created = CurTime()

	if not self.NoHolster then
		local owner = self:GetOwner()
		if owner == MySelf then
			local wep = owner:GetActiveWeapon()
			if wep:IsValid() then
				wep:SendWeaponAnim(ACT_VM_HOLSTER)
			end
		end
	end

	self.BaseClass.Initialize(self)
end
