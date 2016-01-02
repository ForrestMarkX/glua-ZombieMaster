AddCSLuaFile()

if CLIENT then
	SWEP.PrintName = "Pistol"

	SWEP.ViewModelFlip = false
	SWEP.DrawCrosshair = true
	SWEP.ViewModelFOV = 60
end

SWEP.Author = "Mka0207 & Forrest Mark X"

SWEP.Base	= "weapon_zs_base"

SWEP.Slot = 1
SWEP.SlotPos = 0

SWEP.Weight = 25
SWEP.ViewModel	= "models/weapons/c_pistol_zm.mdl"
SWEP.WorldModel	= Model( "models/weapons/pistol3rd_zm.mdl" )
SWEP.UseHands = true

SWEP.ReloadSound = Sound("Weapon_pistol_zm.Reload")
SWEP.Primary.Sound = Sound("Weapon_pistol_zm.Single")
SWEP.EmptySound = Sound("Weapon_pistol_zm.Empty")

SWEP.HoldType = "pistol"

SWEP.Primary.ClipSize			 = 20
SWEP.Primary.Damage				= 16
SWEP.Primary.NumShots 			= 1
SWEP.Primary.Delay 				= 0.26

SWEP.ReloadDelay = 0.4
SWEP.RequiredClip = 1

SWEP.Primary.Automatic   		= false
SWEP.Primary.Ammo         		= "pistol"

GAMEMODE:SetupDefaultClip(SWEP.Primary)

SWEP.Secondary.Delay = 0.3
SWEP.Secondary.ClipSize = 1
SWEP.Secondary.DefaultClip = 1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "dummy"

SWEP.ConeMax = 0.055
SWEP.ConeMin = 0.0200

SWEP.reloadtimer = 0
SWEP.nextreloadfinish = 0