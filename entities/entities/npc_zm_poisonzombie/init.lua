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
	--self:DropToFloor()
	
	self:UpdateEnemy(self:FindEnemy())
	self:SetSchedule(SCHED_IDLE_STAND)
	self:SetRenderMode(RENDERMODE_TRANSALPHA)
	self:SetColor(Color(255, 255, 255, 0))
	
	self.startVal = 0
	self.endVal = 255
	self.fadeSpeed = 1500
	self.fadeAlpha = 0
	self.acolor = Color(255, 255, 255)
	
	self.damage = 25
	self.nextAttack = 0.8
	self.hitDistance = 85
	self.nextPhysics = CurTime() + 1
	
	self.attackSounds = {
		"npc/zombie_poison/pz_throw2.wav",
		"npc/zombie_poison/pz_throw3.wav",
		"npc/zombie_poison/pz_alert2.wav"
	}
	
	self.deathSounds = {
		"npc/zombie_poison/pz_die1.wav",
		"npc/zombie_poison/pz_die2.wav",
		"npc/zombie_poison/pz_idle2.wav",
		"npc/zombie_poison/pz_warn2.wav"
	}
	
	self.painSounds = {
		"npc/zombie_poison/pz_idle3.wav",
		"npc/zombie_poison/pz_idle4.wav",
		"npc/zombie_poison/pz_pain1.wav",
		"npc/zombie_poison/pz_pain2.wav",
		"npc/zombie_poison/pz_pain3.wav",
		"npc/zombie_poison/pz_warn1.wav"
	}
	
	self.tauntSounds = {
		"npc/zombie_poison/pz_alert1.wav",
		"npc/zombie_poison/pz_alert2.wav",
		"npc/zombie_poison/pz_call1.wav",
		"npc/zombie_poison/pz_throw2.wav",
		"npc/zombie_poison/pz_throw3.wav"
	}
end