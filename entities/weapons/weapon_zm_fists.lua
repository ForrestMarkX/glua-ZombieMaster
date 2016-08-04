AddCSLuaFile()
DEFINE_BASECLASS("weapon_zm_basemelee")

if CLIENT then
	SWEP.PrintName = "Fists"
	SWEP.ViewModelFOV = 50
end

SWEP.ViewModel = "models/weapons/c_fists_zm.mdl"
SWEP.WorldModel = ""
SWEP.UseHands = true

SWEP.Slot = 0

SWEP.HoldType = "fist"

SWEP.Primary.Damage = 5
SWEP.Primary.Force = SWEP.Primary.Damage
SWEP.Primary.Reach = 32
SWEP.Primary.HitSound = "Flesh.ImpactHard"
SWEP.Primary.HitFleshSound = "Flesh.ImpactHard"
SWEP.Primary.MissSound = "Weapon_Fists_ZM.Melee_Hit"
SWEP.Primary.Delay = 0.8

SWEP.Undroppable = true

function SWEP:ShouldDropOnDie()
	return false
end