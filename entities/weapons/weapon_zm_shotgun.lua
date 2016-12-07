AddCSLuaFile()
DEFINE_BASECLASS("weapon_zm_shotgunbase")

if CLIENT then
	SWEP.PrintName = "Shotgun"

	SWEP.ViewModelFlip = false
	SWEP.ViewModelFOV = 55
	
	SWEP.WeaponSelectIconLetter	= "b"
end

SWEP.Author = "Mka0207 & Forrest Mark X"

SWEP.Slot = 3
SWEP.SlotPos = 0

SWEP.ViewModel	= "models/weapons/c_shotgun_zm.mdl"
SWEP.WorldModel	= Model( "models/weapons/w_shotgun_zm.mdl" )
SWEP.UseHands = true

SWEP.HoldType = "shotgun"

SWEP.Primary.ClipSize			= 8
SWEP.Primary.DefaultClip		= 8
SWEP.Primary.Damage				= 9
SWEP.Primary.NumShots 			= 10
SWEP.Primary.Delay 				= 1.1
SWEP.Primary.Cone				= 0.048

SWEP.ReloadDelay = 0.3