AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Think()
	local owner = self:GetOwner()
	if not owner:IsValid() or not owner:Alive() then return end

	if owner:Team() ~= TEAM_SURVIVOR then self:Remove() return end

	if self:IsUnderwater() then
		if owner:WaterLevel() < 3 then
			self:SetUnderwater(false)
		end
	elseif owner:WaterLevel() >= 3 then
		self:SetUnderwater(true)
	end

	if self:IsDrowning() then
		local dmginfo = DamageInfo()
		dmginfo:SetAttacker(game.GetWorld())
		dmginfo:SetDamageType(DMG_DROWN)
		dmginfo:SetDamage(10)
		
		owner:TakeDamageInfo(dmginfo)

		self:NextThink(CurTime() + 1)
		return true
	elseif not self:IsUnderwater() and self:GetDrown() == 0 then
		self:Remove()
	end
end
