AddCSLuaFile()
DEFINE_BASECLASS("weapon_zm_base")

if CLIENT then
    SWEP.PrintName             = "Revolver"

    SWEP.ViewModelFlip         = false
    SWEP.ViewModelFOV          = 50
    
    SWEP.WeaponSelectIconLetter = "e"
end

SWEP.Author                    = "Mka0207 & Forrest Mark X"

SWEP.Slot                      = 1
SWEP.SlotPos                   = 0

SWEP.ViewModel                 = "models/weapons/c_revolver_zm.mdl"
SWEP.WorldModel                = Model( "models/weapons/w_357.mdl" )
SWEP.UseHands                  = true

SWEP.ReloadSound               = Sound("weapons/revolver_zm/revolver_reload.wav")
SWEP.Primary.Sound             = Sound("weapons/revolver_zm/revolver_fire.wav")
SWEP.EmptySound                = Sound("weapons/pistol_zm/pistol_zm_empty.wav")

SWEP.HoldType                  = "revolver"

SWEP.Primary.ClipSize           = 6
SWEP.Primary.DefaultClip        = 6
SWEP.Primary.MinDamage          = 20
SWEP.Primary.MaxDamage          = 30
SWEP.Primary.NumShots           = 1
SWEP.Primary.Delay              = 1.2

SWEP.Primary.Automatic          = false
SWEP.Primary.Ammo               = "revolver"

SWEP.Secondary.Delay            = 0.3
SWEP.Secondary.ClipSize         = 1
SWEP.Secondary.DefaultClip      = 1
SWEP.Secondary.Automatic        = false
SWEP.Secondary.Ammo             = "dummy"

function SWEP:Think()
    if self.firing and self.firetimer < CurTime() then
        self:PlayPrimaryFireSound()
        
        local damage = Either(self.Primary.Damage ~= nil, self.Primary.Damage, math.random(self.Primary.MinDamage or 0, self.Primary.MaxDamage or 0))
        self:ShootBullet(damage, self.Primary.NumShots, self.Primary.Cone)
        
        self.Owner:ViewPunch(Angle(-8, math.Rand(-2, 2), 0))
        
        if not self.InfiniteAmmo then
            self:TakePrimaryAmmo(1)
        end
        
        self.firing = false
        self.firetimer = 0
    end
    
    if self.IdleAnimation and self.IdleAnimation <= CurTime() then
        self.IdleAnimation = nil
        self:SendWeaponAnim(ACT_VM_IDLE)
    end
end

function SWEP:SecondaryAttack()
    if not self:CanPrimaryAttack() then return end
    
    self:SetNextPrimaryFire(CurTime() + self.Secondary.Delay)
    
    self:PlayPrimaryFireSound()
    self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
    
    local damage = Either(self.Primary.Damage ~= nil, self.Primary.Damage, math.random(self.Primary.MinDamage or 0, self.Primary.MaxDamage or 0))
    self:ShootBullet(damage, self.Primary.NumShots, self.Primary.Cone)
    
    self.Owner:ViewPunch(Angle(math.Rand(-8, 2), math.Rand(-2, 2), 0))
    
    if not self.InfiniteAmmo then
        self:TakePrimaryAmmo(1)
    end
    
    self:SetNextIdle(CurTime() + self:SequenceDuration())
end

function SWEP:PrimaryAttack()
    if not self:CanPrimaryAttack() then return end
    
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    self.firing = true
    self.firetimer = CurTime() + 0.38
    
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self.Owner:DoAttackEvent()
    
    self:SetNextIdle(CurTime() + self:SequenceDuration())
end

function SWEP:Reload()
    if self:GetNextReload() <= CurTime() and self:DefaultReload(ACT_VM_RELOAD) then
        self:SetNextIdle(CurTime() + self:SequenceDuration())
        self:SetNextReload(self:GetNextIdle())
        self.Owner:DoReloadEvent()
        if self.ReloadSound then
            timer.Simple(1.5, function() self:EmitSound(self.ReloadSound) end)
        end
    end
end

function SWEP:GetBulletSpread(cone)
    return VECTOR_CONE_1DEGREES
end