AddCSLuaFile()
DEFINE_BASECLASS("weapon_zm_basemelee")

if CLIENT then
	SWEP.PrintName = "Sledge"
	SWEP.ViewModelFOV = 65
	
	SWEP.WeaponSelectIconLetter	= "i"
end

SWEP.ViewModel = "models/weapons/c_sledgehammer_zm.mdl"
SWEP.WorldModel = "models/weapons/sledgehammer3rd_zm.mdl"
SWEP.UseHands = true

SWEP.Slot = 2

SWEP.HoldType = "melee2"

SWEP.MeleeDamage = 50
SWEP.MeleeRange = 64
SWEP.MeleeSize = 1.75

SWEP.Primary.Delay = 2.8

SWEP.StartSwingAnimation = ACT_VM_HITCENTER2

SWEP.SwingTime = 1.75
SWEP.SwingHoldType = "melee"

SWEP.HitAnim = false
SWEP.MissAnim = false

function SWEP:PlaySwingSound()
	self:EmitSound("weapons/iceaxe/iceaxe_swing1.wav", 75, math.random(35, 45))
end

function SWEP:PlayHitSound()
	self:EmitSound("physics/metal/metal_canister_impact_hard"..math.random(3)..".wav", 75, math.Rand(86, 90))
end

function SWEP:PlayHitFleshSound()
	self:EmitSound("physics/body/body_medium_break"..math.random(2, 4)..".wav", 75, math.Rand(86, 90))
end