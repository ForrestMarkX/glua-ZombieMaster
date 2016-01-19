AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

ENT.models = {
	"models/zombie/zm_classic.mdl",
	"models/zombie/zm_classic_01.mdl",
	"models/zombie/zm_classic_02.mdl",
	"models/zombie/zm_classic_03.mdl",
	"models/zombie/zm_classic_04.mdl",
	"models/zombie/zm_classic_05.mdl",
	"models/zombie/zm_classic_06.mdl",
	"models/zombie/zm_classic_07.mdl",
	"models/zombie/zm_classic_08.mdl",
	"models/zombie/zm_classic_09.mdl"
}
	
function ENT:Initialize()
	self:SetModel(self.models[math.random(1, #self.models)]);
	
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
	
	self.damage = 13
	self.nextAttack = 0.8
	self.nextPhysics = CurTime() + 1
	
	self.attackSounds = {
		"npc/shamblie/zo_attack1.wav",
		"npc/shamblie/zo_attack2.wav"
	}
	
	self.deathSounds = {
		"npc/shamblie/zombie_die1.wav",
		"npc/shamblie/zombie_die2.wav",
		"npc/shamblie/zombie_die3.wav"
	}
	
	self.painSounds = {
		"npc/shamblie/Hit_0.wav",
		"npc/shamblie/Hit_1.wav",
		"npc/shamblie/Hit_2.wav",
		"npc/shamblie/Hit_3.wav",
		"npc/shamblie/Hit_4.wav",
		"npc/shamblie/hit_5.wav",
		"npc/shamblie/Hit_6.wav",
		"npc/shamblie/Hit_7.wav"
	}
	
	self.tauntSounds = {
		"npc/shamblie/Growl_0.wav",
		"npc/shamblie/Growl_1.wav",
		"npc/shamblie/Growl_2.wav",
		"npc/shamblie/Growl_3.wav",
		"npc/shamblie/Growl_4.wav",
		"npc/shamblie/Growl_5.wav",
		"npc/shamblie/Growl_6.wav",
		"npc/shamblie/Growl_7.wav",
		"npc/shamblie/Growl_8.wav"
	}
	
	self.clawHitSounds = {
		"npc/shamblie/claw_strike1.wav",
		"npc/shamblie/claw_strike2.wav",
		"npc/shamblie/claw_strike3.wav"
	}

	self.clawMissSounds = {
		"npc/shamblie/claw_miss1.wav",
		"npc/shamblie/claw_miss2.wav"
	}
	
	self.doorHitSound	= "npc/shamblie/zombie_pound_door.wav"
	
	self.moveSounds = {
		"npc/shamblie/foot1.wav",
		"npc/shamblie/foot2.wav",
		"npc/shamblie/foot3.wav"
	}
end