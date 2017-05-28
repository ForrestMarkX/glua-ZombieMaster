AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

ENT.AttackSounds = "Zombie.Attack"
ENT.DeathSounds = "Zombie.Die"
ENT.PainSounds = "Zombie.Pain"
ENT.MoanSounds = "Zombie.Idle"
ENT.DoorHitSound = "npc/shamblie/zombie_pound_door.wav"
ENT.OnFireSound = {
	"NPC_BaseZombie.Moan1",
	"NPC_BaseZombie.Moan2",
	"NPC_BaseZombie.Moan3",
	"NPC_BaseZombie.Moan4"
}

function ENT:PlayOnFireSound()
	if self.bPlayingFireSound then return end
	
	self.FireSoundLoop = CurTime()
	timer.Create("OnFireMoanLoop."..self:EntIndex(), 0, 0, function()
		if not self:IsOnFire() then  
			timer.Remove("OnFireMoanLoop."..self:EntIndex())
			self.bPlayingFireSound = false
			return
		end
		
		if self.FireSoundLoop < CurTime() then
			local sndfile = self:PlayVoiceSound(self.OnFireSound)
			self.FireSoundLoop = CurTime() + SoundDuration(sndfile)
		end
	end)
	
	self.bPlayingFireSound = true
end

function ENT:CustomThink()
	if self:IsOnFire() and self:GetMovementActivity() ~= ACT_WALK_ON_FIRE then
		self:SetMovementActivity(ACT_WALK_ON_FIRE)
		self:PlayOnFireSound()
	end
end