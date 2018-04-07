AddCSLuaFile()
DEFINE_BASECLASS("weapon_zm_base")

if CLIENT then
    SWEP.PrintName                 = "Pistol"

    SWEP.ViewModelFlip             = false
    SWEP.ViewModelFOV             = 60
    
    SWEP.WeaponSelectIconLetter    = "d"
end

SWEP.Author                     = "Mka0207 & Forrest Mark X"

SWEP.Slot                         = 1
SWEP.SlotPos                     = 0

SWEP.ViewModel                    = "models/weapons/c_pistol_zm.mdl"
SWEP.WorldModel                    = Model( "models/weapons/pistol3rd_zm.mdl" )
SWEP.UseHands                     = true

SWEP.ReloadSound                 = Sound("Weapon_pistol_zm.Reload")
SWEP.Primary.Sound                = Sound("Weapon_pistol_zm.Single")
SWEP.EmptySound                 = Sound("Weapon_pistol_zm.Empty")

SWEP.HoldType                     = "pistol"

SWEP.Primary.ClipSize            = 20
SWEP.Primary.DefaultClip        = 20
SWEP.Primary.MinDamage            = 11
SWEP.Primary.MaxDamage            = 16
SWEP.Primary.NumShots             = 1
SWEP.Primary.Delay                 = 0.255

SWEP.Primary.Automatic           = true
SWEP.Primary.Ammo                 = "pistol"

SWEP.Secondary.Delay             = 0.3
SWEP.Secondary.ClipSize         = 1
SWEP.Secondary.DefaultClip         = 1
SWEP.Secondary.Automatic         = false
SWEP.Secondary.Ammo             = "dummy"

SWEP.DoViewPunch                = true

local PISTOL_ACCURACY_SHOT_PENALTY_TIME        = 0.2
local PISTOL_ACCURACY_MAXIMUM_PENALTY_TIME    = 1.5

function SWEP:Initialize()
    BaseClass.Initialize(self)
    self.flAccuracyPenalty = 0
end

function SWEP:Think()
    BaseClass.Think(self)
    
    local owner = self:GetOwner()
    if IsValid(owner) and owner:KeyDown(IN_ATTACK) and self:GetNextPrimaryFire() < CurTime() then
        self.flAccuracyPenalty = self.flAccuracyPenalty - FrameTime()
        self.flAccuracyPenalty = math.Clamp(self.flAccuracyPenalty, 0.0, PISTOL_ACCURACY_MAXIMUM_PENALTY_TIME)
    end
end

function SWEP:Reload()
    if self:DefaultReload(ACT_VM_RELOAD) then
        self.flAccuracyPenalty = 0
        self.bClickedOnce = false
        self:PlayReloadSound()
        self:SetNextIdle(CurTime() + self:SequenceDuration())
    end
end

function SWEP:ShootBullet(dmg, numbul, cone)
    BaseClass.ShootBullet(self, dmg, numbul, cone)
    self.flAccuracyPenalty = self.flAccuracyPenalty + PISTOL_ACCURACY_SHOT_PENALTY_TIME
end

function SWEP:GetBulletSpread(cone)
    local ramp = math.Remap(self.flAccuracyPenalty, 0.0, PISTOL_ACCURACY_MAXIMUM_PENALTY_TIME, 0.0, 1.0)
    return LerpVector(ramp, Vector(0, 0, 0), VECTOR_CONE_2DEGREES)
end

function SWEP:GetViewPunch()
    math.randomseed(UnPredictedCurTime())
    return Angle(math.Rand(-2.5, -1.75), math.Rand(-0.6, 0.6), 0.0)
end