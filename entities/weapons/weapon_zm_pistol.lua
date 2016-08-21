AddCSLuaFile()
DEFINE_BASECLASS("weapon_zm_base")

if CLIENT then
	SWEP.PrintName = "Pistol"

	SWEP.ViewModelFlip = false
	SWEP.ViewModelFOV = 60
	
	SWEP.WeaponSelectIconLetter	= "d"
end

SWEP.Author = "Mka0207 & Forrest Mark X"

SWEP.Slot = 1
SWEP.SlotPos = 0

SWEP.ViewModel	= "models/weapons/c_pistol_zm.mdl"
SWEP.WorldModel	= Model( "models/weapons/pistol3rd_zm.mdl" )
SWEP.UseHands = true

SWEP.ReloadSound = Sound("Weapon_pistol_zm.Reload")
SWEP.Primary.Sound = Sound("Weapon_pistol_zm.Single")
SWEP.EmptySound = Sound("Weapon_pistol_zm.Empty")

SWEP.HoldType = "pistol"

SWEP.Primary.ClipSize			= 20
SWEP.Primary.DefaultClip		= 20
SWEP.Primary.Damage				= 16
SWEP.Primary.NumShots 			= 1
SWEP.Primary.Delay 				= 0.26
SWEP.Primary.Cone 				= 0.023

SWEP.Primary.Automatic   		= false
SWEP.Primary.Ammo         		= "pistol"

SWEP.Secondary.Delay = 0.3
SWEP.Secondary.ClipSize = 1
SWEP.Secondary.DefaultClip = 1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "dummy"