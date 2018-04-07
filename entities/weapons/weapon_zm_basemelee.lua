AddCSLuaFile()
DEFINE_BASECLASS("weapon_zm_base")

SWEP.ViewModel                 = "models/weapons/v_crowbar.mdl"
SWEP.WorldModel                = "models/weapons/w_crowbar.mdl"

SWEP.Primary.ClipSize          = -1
SWEP.Primary.DefaultClip       = -1
SWEP.Primary.Automatic         = true
SWEP.Primary.Ammo              = "none"

SWEP.Secondary.ClipSize        = -1
SWEP.Secondary.DefaultClip     = -1
SWEP.Secondary.Automatic       = false
SWEP.Secondary.Ammo            = "none"

SWEP.Slot                      = 0
SWEP.SlotPos                   = 4

SWEP.DrawAmmo                  = false
SWEP.DrawCrosshair             = true

SWEP.IsMelee                   = true
SWEP.HoldType                  = "melee"

function SWEP:DefaultCallBack(tr, dmginfo)
    BaseClass.DefaultCallBack(self, tr, dmginfo)
    dmginfo:SetDamageType(DMG_CLUB)
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    
    local owner = self.Owner
    owner:DoAttackEvent()
    
    local damage = Either(self.Primary.Damage ~= nil, self.Primary.Damage, math.random(self.Primary.MinDamage or 0, self.Primary.MaxDamage or 0))
    local trace = util.TraceLine( {
        start = owner:GetShootPos(),
        endpos = owner:GetShootPos() + (self.Owner:GetAimVector() * self.Primary.Reach),
        filter = owner
    } )
    if trace.Hit then
        self:SendWeaponAnim(ACT_VM_HITCENTER)
        
        bullet        = {}
        bullet.Num    = 1
        bullet.Src    = owner:GetShootPos()
        bullet.Dir    = owner:GetAimVector()
        bullet.Distance = self.Primary.Reach
        bullet.Spread = Vector(0, 0, 0)
        bullet.Tracer = 0
        bullet.Force  = self.Primary.Force
        bullet.Damage = damage
        bullet.Callback = self.DefaultCallBack
        
        owner:FireBullets(bullet)
        
        if trace.MatType == MAT_GRATE then
            local ent = trace.Entity
            if IsValid(ent) and ent.TakeDamage then
                ent:TakeDamage(damage, owner, self)
            end
        end
        
        if trace.MatType == MAT_FLESH then
            self:EmitSound(self.Primary.HitFleshSound)
        else
            self:EmitSound(self.Primary.HitSound)
        end
    else
        self:SendWeaponAnim(ACT_VM_HITCENTER)
        self:EmitSound(self.Primary.MissSound)
    end
    
    self:SetNextIdle(CurTime() + self:SequenceDuration())
end

if not CLIENT then return end

function SWEP:DrawHUD()
end

function SWEP:DoDrawCrosshair(x, y)
    surface.SetDrawColor(Color(200, 0, 0))
    surface.DrawRect(x - 1.75, y - 1.75, 4, 4)
    surface.SetDrawColor(0, 0, 0, 220)
    surface.DrawOutlinedRect(x - 1.75, y - 1.75, 4, 4)
    
    return true
end