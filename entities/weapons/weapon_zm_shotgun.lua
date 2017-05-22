AddCSLuaFile()
DEFINE_BASECLASS("weapon_zm_shotgunbase")

if CLIENT then
	SWEP.PrintName				= "Shotgun"

	SWEP.ViewModelFlip 			= false
	SWEP.ViewModelFOV 			= 55
	
	SWEP.WeaponSelectIconLetter	= "b"
end

SWEP.Author 					= "Mka0207 & Forrest Mark X"

SWEP.Slot 						= 3
SWEP.SlotPos 					= 0

SWEP.ViewModel					= "models/weapons/c_shotgun_zm.mdl"
SWEP.WorldModel					= Model( "models/weapons/w_shotgun_zm.mdl" )
SWEP.UseHands	 				= true

SWEP.HoldType 					= "shotgun"

SWEP.Primary.ClipSize			= 8
SWEP.Primary.DefaultClip		= 8
SWEP.Primary.MinDamage			= 6
SWEP.Primary.MaxDamage			= 8
SWEP.Primary.NumShots 			= 8
SWEP.Primary.Delay 				= 1.1
SWEP.Primary.Cone				= 0.048

SWEP.ReloadDelay 				= 0.3

function SWEP:Initialize()
	BaseClass.Initialize(self)
	
	local mins, maxs = self:OBBMins(), self:OBBMaxs()
	mins.x = mins.x * 2
	mins.y = mins.y * 2
	maxs.x = maxs.x * 2
	maxs.y = maxs.y * 2
	
	self:SetCollisionBounds(mins, maxs)
end