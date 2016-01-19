AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	hook.Add("Move", self, self.Move)

	self:DrawShadow(false)

	local owner = self:GetOwner()
	if owner:IsValid() and owner:IsPlayer() then
		owner.status_human_holding = self

		owner:DrawWorldModel(false)

		local wep = owner:GetActiveWeapon()
		if wep:IsValid() then
			wep:SendWeaponAnim(ACT_VM_HOLSTER)
		end
	end

	local object = self:GetObject()
	if object:IsValid() then
		for _, ent in pairs(ents.FindByClass("logic_pickupdrop")) do
			if ent.EntityToWatch == object:GetName() and ent:IsValid() then
				ent:Input("onpickedup", owner, object, "")
			end
		end
		
		local objectphys = object:GetPhysicsObject()
		if objectphys:IsValid() then
			objectphys:AddGameFlag(FVPHYSICS_NO_IMPACT_DMG)
			objectphys:AddGameFlag(FVPHYSICS_NO_NPC_IMPACT_DMG)

			self:SetObjectMass(objectphys:GetMass())

			if objectphys:GetMass() < CARRY_DRAG_MASS and (object:OBBMins():Length() + object:OBBMaxs():Length() < CARRY_DRAG_VOLUME or object.NoVolumeCarryCheck) then
				objectphys:AddGameFlag(FVPHYSICS_PLAYER_HELD)
				object._OriginalMass = objectphys:GetMass()
				object._OriginalCG = object:GetCollisionGroup()

				objectphys:EnableGravity(false)
				objectphys:SetMass(2)

				object:SetCollisionGroup(COLLISION_GROUP_WEAPON)
				object:SetOwner(owner)
			end
		end
	end
end

function ENT:OnRemove()
	local owner = self:GetOwner()
	if owner:IsValid() then
		--owner.status_human_holding = nil

		owner:DrawWorldModel(true)

		if owner:Alive() and owner:Team() == TEAM_HUMAN then
			local wep = owner:GetActiveWeapon()
			if wep:IsValid() then
				wep:SendWeaponAnim(ACT_VM_DRAW)
			end
		end
	end

	local object = self:GetObject()
	if object:IsValid() then
		local objectphys = object:GetPhysicsObject()
		if objectphys:IsValid() then
			objectphys:ClearGameFlag(FVPHYSICS_PLAYER_HELD)
			objectphys:ClearGameFlag(FVPHYSICS_NO_IMPACT_DMG)
			objectphys:ClearGameFlag(FVPHYSICS_NO_NPC_IMPACT_DMG)
			objectphys:EnableGravity(true)
			if object._OriginalMass then
				objectphys:SetMass(object._OriginalMass)
				object._OriginalMass = nil
			end
			
			if object._OriginalCG then
				object:SetCollisionGroup(object._OriginalCG == COLLISION_GROUP_INTERACTIVE and COLLISION_GROUP_NONE or object._OriginalCG)
				object._OriginalCG = nil
			end

			object:SetOwner(NULL)
		end

		object._LastDroppedBy = owner
		object._LastDropped = CurTime()

		for _, ent in pairs(ents.FindByClass("logic_pickupdrop")) do
			if ent.EntityToWatch == object:GetName() and ent:IsValid() then
				ent:Input("ondropped", owner, object, "")
			end
		end
	end
end

local ShadowParams = {secondstoarrive = 0.01, maxangular = 1000, maxangulardamp = 10000, maxspeed = 500, maxspeeddamp = 1000, dampfactor = 0.65, teleportdistance = 0}
function ENT:Think()
	local ct = CurTime()

	local frametime = ct - (self.LastThink or ct)
	self.LastThink = ct

	local object = self:GetObject()
	local owner = self:GetOwner()
	if not object:IsValid() or not owner:IsValid() or not owner:Alive() or not owner:Team() == TEAM_HUMAN then
		self:Remove()
		return
	end

	local shootpos = owner:GetShootPos()
	local nearestpoint = object:NearestPoint(shootpos)

	local objectphys = object:GetPhysicsObject()
	if object:GetMoveType() ~= MOVETYPE_VPHYSICS or not objectphys:IsValid() or owner:GetGroundEntity() == object then
		self:Remove()
		return
	end

	if 64 < nearestpoint:Distance(shootpos) then
		self:Remove()
		return
	end

	objectphys:Wake()

	if owner:KeyPressed(IN_ATTACK) then
		object:SetPhysicsAttacker(owner)

		self:Remove()
		return
	elseif owner:KeyDown(IN_ATTACK2) and not owner:GetActiveWeapon().NoPropThrowing then
		owner:ConCommand("-attack2")
		objectphys:ApplyForceCenter(objectphys:GetMass() * math.Clamp(1.25 - math.min(1, (object:OBBMins():Length() + object:OBBMaxs():Length()) / CARRY_DRAG_VOLUME), 0.25, 1) * 500 * owner:GetAimVector())
		object:SetPhysicsAttacker(owner)

		self:Remove()
		return
	else
		if not self.ObjectPosition or not owner:KeyDown(IN_SPEED) then
			local obbcenter = object:OBBCenter()
			local objectpos = shootpos + owner:GetAimVector() * 48
			objectpos = objectpos - obbcenter.z * object:GetUp()
			objectpos = objectpos - obbcenter.y * object:GetRight()
			objectpos = objectpos - obbcenter.x * object:GetForward()
			self.ObjectPosition = objectpos
			if not self.ObjectAngles then
				self.ObjectAngles = object:GetAngles()
			end
		end

		ShadowParams.pos = self.ObjectPosition
		ShadowParams.angle = self.ObjectAngles
		ShadowParams.deltatime = frametime
		objectphys:ComputeShadowControl(ShadowParams)
	end

	object:SetPhysicsAttacker(owner)

	self:NextThink(ct)
	return true
end
