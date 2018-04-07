AddCSLuaFile()
DEFINE_BASECLASS("weapon_zm_shotgunbase")

if CLIENT then
    SWEP.PrintName             = "Rifle"

    SWEP.ViewModelFlip         = false
    SWEP.ViewModelFOV          = 50
    
    SWEP.WeaponSelectIconLetter = "f"
end

SWEP.Author                    = "Mka0207 & Forrest Mark X"

SWEP.Slot                      = 3
SWEP.SlotPos                   = 0

SWEP.ViewModel                 = "models/weapons/c_rifle_zm.mdl"
SWEP.WorldModel                = Model( "models/weapons/rifle_zm_3rd.mdl" )
SWEP.UseHands                  = true

SWEP.ReloadSound               = Sound("Weapon_Rifle_ZM.Reload")
SWEP.Primary.Sound             = Sound("Weapon_Rifle_ZM.Single")
SWEP.EmptySound                = Sound("Weapon_Rifle_ZM.Empty")
SWEP.PumpSound                 = Sound("Weapon_Rifle_ZM.Special1")

SWEP.HoldType                  = "ar2"

SWEP.Primary.ClipSize          = 11
SWEP.Primary.DefaultClip       = 11
SWEP.Primary.MinDamage         = 55
SWEP.Primary.MaxDamage         = 65
SWEP.Primary.NumShots          = 1
SWEP.Primary.Delay             = 1.6
SWEP.Primary.Cone              = 0
SWEP.Primary.DamageType        = DMG_BULLET

SWEP.ReloadDelay               = 0.8

SWEP.Primary.Automatic         = true
SWEP.Primary.Ammo              = "357"

SWEP.Secondary.Delay           = 0.25
SWEP.DoViewPunch               = true

function SWEP:SetupDataTables()
    BaseClass.SetupDataTables(self)
    self:NetworkVar( "Bool", 2, "Zoomed" )
end

function SWEP:Initialize()
    BaseClass.Initialize(self)
    self:SetZoomed(false)
end

function SWEP:SecondaryAttack()
    if not self:CanSecondaryAttack() then return end
     
    local owner = self.Owner

    self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)

    local zoomed = self:GetZoomed()
    self:SetZoomed(not zoomed)

    if zoomed then
        owner:SetFOV(owner:GetInfo("fov_desired"), 0.35)
    else
        owner:SetFOV(owner:GetInfo("fov_desired") * 0.25, 0.5)
    end
end

function SWEP:CanSecondaryAttack()
    return self:GetNextSecondaryFire() <= CurTime()
end

function SWEP:Holster()
    if self:GetZoomed() then
        local owner = self.Owner
        owner:SetFOV(owner:GetInfo("fov_desired"), 0.5)
        self:EmitSound("weapons/sniper/sniper_zoomout.wav", 50, 100)
        self:SetZoomed(false)
    end

    return true
end

function SWEP:OnRemove()
    local owner = self.Owner
    if owner:IsValid() and self:GetZoomed() then
        owner:SetFOV(owner:GetInfo("fov_desired"), 0.5)
    end
end

function SWEP:AdjustMouseSensitivity()
    if self:GetZoomed() then
        return 0.5
    end
    
    return 1.0
end

function SWEP:GetViewPunch()
    return Angle(math.Rand(-10, -4), math.Rand(-2, 2), 0)
end

if not CLIENT then return end

function SWEP:PreDrawViewModel(vm, wep, ply)
    if self.ShowViewModel == false then render.SetBlend(0) end
    if self:GetZoomed() then render.SetBlend(0) end
end