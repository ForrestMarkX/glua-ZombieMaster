AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

DEFINE_BASECLASS("zm_npc_base")

ENT.AttackDamage = 10
ENT.AttackRange	 = 120
ENT.NextDoorFind = CurTime()
ENT.NextSpit	 = CurTime()
ENT.CanSwatPhysicsObjects = false

ENT.DeathSounds  = "NPC_DragZombie.Die"
ENT.PainSounds   = "NPC_DragZombie.Pain"
ENT.MoanSounds   = "NPC_DragZombie.Idle"
ENT.AlertSounds  = "NPC_DragZombie.Alert"
ENT.ClawHitSounds = ""
ENT.ClawMissSounds = ""

function ENT:Initialize()
	BaseClass.Initialize(self)
	self:CapabilitiesAdd(bit.bor(CAP_MOVE_GROUND, CAP_INNATE_MELEE_ATTACK1, CAP_SQUAD))
end

function ENT:FindDoor()
	local position = self:GetPos() + Vector(0, 0, 25)
	local doors = {}
	doors = table.Add(doors, ents.FindByClass("func_door"))
	doors = table.Add(doors, ents.FindByClass("func_door_rotating"))
	doors = table.Add(doors, ents.FindByClass("prop_door_rotating"))
	
	for k, v in pairs(doors) do
		if v:GetPos():Distance(position) < 80 then
			return v
		end
	end
	
	return NULL
end

function ENT:CustomThink()
	if not self.IsAttacking and self.NextDoorFind + 4 < CurTime() then
		local door = self:FindDoor()
		
		if IsValid(door) then
			door:Fire("open", "", 0.1)
			self:PlayVoiceSound(self.MoanSounds)
			self.NextIdleMoan = CurTime() + math.random(15, 25)
		end
		
		self.NextDoorFind = CurTime()
	end
	
	if self.NextSpit < CurTime() then
		local enemy = self:GetEnemy()
		if IsValid(enemy) and enemy:GetPos():Distance(self:GetPos()) <= self:GetClawAttackRange() then
			local pHurt = self:CheckTraceHullAttack(self:EyePos(), self:EyePos() + self:EyeAngles():Forward() * (self:GetClawAttackRange() + 10), -Vector(16, 16, 32), Vector(16, 16, 32), GetConVar("zm_dragzombie_damage"):GetInt(), DMG_ACID, 5.0)
			if IsValid(pHurt) then
				local obj = self:LookupAttachment("Mouth")
				local attachment = self:GetAttachment(obj)
				local vSpitPos, vSpitAngle = attachment.Pos, attachment.Ang
			
				if pHurt:IsPlayer() then
					pHurt:ViewPunch(Angle(math.Rand(-50.0, 50.0), math.Rand(-50.0, 50.0), math.Rand(-50.0, 50.0)))
					pHurt:SetAbsVelocity(Vector(0, 0, 0))
					
					local pangle = pHurt:GetAngles()
					pHurt:SetAngles(Angle(pangle.p + math.random(-10, 10), pangle.y + math.random(-10, 10), pangle.r))
				end
				
				local effect = EffectData()
					effect:SetOrigin(vSpitPos)
					effect:SetScale(math.random(4, 16))
					effect:SetColor(BLOOD_COLOR_RED)
				util.Effect("BloodImpact", effect)
				
				self:EmitSound("NPC_DragZombie.MeleeAttack")
			end
		end
		
		self.NextSpit = CurTime() + 0.8
	end
end