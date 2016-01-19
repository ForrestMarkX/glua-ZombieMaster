AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/zombie/hulk.mdl")
	
	self:SetHullSizeNormal()
	self:SetHullType(HULL_HUMAN)
	
	self:SetSolid(SOLID_BBOX)
	self:SetMoveType(MOVETYPE_STEP)
	self:CapabilitiesAdd(bit.bor(CAP_MOVE_GROUND, CAP_INNATE_MELEE_ATTACK1))

	self:SetMaxYawSpeed(5000)
	self:SetHealth(100)
	
	self:ClearSchedule()
	
	self:UpdateEnemy(self:FindEnemy())
	self:SetSchedule(SCHED_IDLE_STAND)
	
	self.damage = 25
	self.nextAttack = 0.8
	self.hitDistance = 85
	self.nextPhysics = CurTime() + 1
	
	self.attackSounds = {
		"NPC_PoisonZombie.Attack"
	}
	
	self.deathSounds = {
		"NPC_PoisonZombie.Die"
	}
	
	self.painSounds = {
		"NPC_PoisonZombie.Pain"
	}
	
	self.tauntSounds = {
		"NPC_PoisonZombie.Moan1"
	}
end