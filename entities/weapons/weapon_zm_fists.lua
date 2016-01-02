AddCSLuaFile()

if CLIENT then
	SWEP.PrintName = "Fists"
	SWEP.ViewModelFOV = 50
end

SWEP.Base = "weapon_zs_basemelee"

SWEP.ViewModel = "models/weapons/c_fists_zm.mdl"
SWEP.WorldModel = ""
SWEP.UseHands = true

SWEP.Slot = 0

SWEP.HoldType = "fist"
SWEP.SwingHoldType = "fist"

SWEP.MeleeDamage = 5
SWEP.MeleeRange = 32
SWEP.MeleeSize = 1

SWEP.SwingTime = 0.5

SWEP.Primary.Delay = 0.8

SWEP.Undroppable = true

function SWEP:PlaySwingSound()
	self:EmitSound("Weapon_Fists_ZM.Melee_Hit")
end

function SWEP:PlayHitSound()
	self:EmitSound("Flesh.ImpactHard")
end

function SWEP:PlayHitFleshSound()
	self:EmitSound("Flesh.ImpactHard")
end