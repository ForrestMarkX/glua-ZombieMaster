AddCSLuaFile()

if CLIENT then
	SWEP.PrintName = "Mac 10"

	SWEP.ViewModelFlip = false
	SWEP.DrawCrosshair = true
	SWEP.ViewModelFOV = 60
end

SWEP.Author = "Mka0207 & Forrest Mark X"

SWEP.Base	= "weapon_zs_base"

SWEP.Slot = 3
SWEP.SlotPos = 0

SWEP.Weight = 25
SWEP.ViewModel	= "models/weapons/c_mac_zm.mdl"
SWEP.WorldModel	= Model( "models/weapons/smg_zm_3rd.mdl" )
SWEP.UseHands = true

SWEP.ReloadSound = Sound("Weapon_SMG_ZM.Reload1")
SWEP.Primary.Sound = Sound("Weapon_SMG_ZM.Single")
SWEP.EmptySound = Sound("Weapon_SMG_ZM.Empty")

SWEP.HoldType = "pistol"

SWEP.Primary.ClipSize			 = 30
SWEP.Primary.Damage				= 17
SWEP.Primary.NumShots 			= 1
SWEP.Primary.Delay 				= 0.1

SWEP.ReloadDelay = 0.4

SWEP.Primary.Automatic   		= true
SWEP.Primary.Ammo         		= "smg1"

GAMEMODE:SetupDefaultClip(SWEP.Primary)

SWEP.Secondary.Delay = 0.3
SWEP.Secondary.ClipSize = 1
SWEP.Secondary.DefaultClip = 1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "dummy"

SWEP.ConeMax = 0.055
SWEP.ConeMin = 0.0200