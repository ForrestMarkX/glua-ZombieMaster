AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

ENT.AttackDamage = 10
ENT.AttackRange	 = 64
ENT.NextDoorFind = CurTime()
ENT.CanSwatPhysicsObjects = false

ENT.DeathSounds  = "NPC_DragZombie.Die"
ENT.PainSounds   = "NPC_DragZombie.Pain"
ENT.MoanSounds   = "NPC_DragZombie.Idle"
ENT.AlertSounds  = "NPC_DragZombie.Alert"

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

function ENT:PerformAttack()
	if self.IsAttacking then
		local enemy = self:GetEnemy()
		if IsValid(enemy) and enemy:GetPos():Distance(self:GetPos()) <= self:GetClawAttackRange() then
			local effect = EffectData()
				effect:SetOrigin(enemy:GetPos() + Vector(0, 0, 40))
				effect:SetScale(4)
				effect:SetEntity(enemy)
				effect:SetColor(enemy:GetBloodColor())
			util.Effect("BloodImpact", effect, true, true)
		
			enemy:TakeDamage(self.AttackDamage, self)
			self:EmitSound("NPC_DragZombie.MeleeAttack")
		end
	end
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
end