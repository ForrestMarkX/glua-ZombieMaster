AddCSLuaFile()
DEFINE_BASECLASS("weapon_zm_base")

if CLIENT then
	SWEP.PrintName = "Mac 10"

	SWEP.ViewModelFlip = false
	SWEP.ViewModelFOV = 60
	
	SWEP.WeaponSelectIconLetter	= "a"
end

SWEP.Author = "Mka0207 & Forrest Mark X"

SWEP.Slot = 3
SWEP.SlotPos = 0

SWEP.ViewModel	= "models/weapons/c_mac_zm.mdl"
SWEP.WorldModel	= Model( "models/weapons/smg_zm_3rd.mdl" )
SWEP.UseHands = true

SWEP.ReloadSound = Sound("Weapon_SMG_ZM.Reload1")
SWEP.Primary.Sound = Sound("Weapon_SMG_ZM.Single")
SWEP.EmptySound = Sound("Weapon_SMG_ZM.Empty")

SWEP.HoldType = "pistol"

SWEP.Primary.ClipSize			= 30
SWEP.Primary.DefaultClip		= 30
SWEP.Primary.Damage				= 17
SWEP.Primary.NumShots 			= 1
SWEP.Primary.Delay 				= 0.1
SWEP.Primary.Cone 				= 0.028

SWEP.ReloadDelay = 0.4

SWEP.Primary.Automatic   		= true
SWEP.Primary.Ammo         		= "smg1"

SWEP.Secondary.Delay = 0.3
SWEP.Secondary.ClipSize = 1
SWEP.Secondary.DefaultClip = 1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "dummy"