AddCSLuaFile()
DEFINE_BASECLASS("weapon_zm_base")

if CLIENT then
    SWEP.PrintName             = "Molotovs"

    SWEP.ViewModelFlip         = false
    SWEP.ViewModelFOV          = 55
    
    SWEP.WeaponSelectIconLetter = "k"
end

SWEP.Author                    = "Mka0207 & Forrest Mark X"

SWEP.Slot                      = 4
SWEP.SlotPos                   = 0

SWEP.ViewModel                 = "models/weapons/c_molotov_zm.mdl"
SWEP.WorldModel                = Model( "models/weapons/molotov3rd_zm.mdl" )
SWEP.UseHands                  = true
SWEP.WeaponIsAmmo              = true

SWEP.HoldType                  = "grenade"
SWEP.DontDrawSpare             = true

SWEP.Primary.Recoil            = 0
SWEP.Primary.Delay             = 0
SWEP.Primary.Damage            = 0
SWEP.Primary.ClipSize          = -1
SWEP.Primary.DefaultClip       = -1
SWEP.Primary.Reload            = 0
SWEP.Primary.Automatic         = false
SWEP.Primary.Ammo              = "molotov"

SWEP.Secondary.Delay           = 0.3
SWEP.Secondary.ClipSize        = -1
SWEP.Secondary.DefaultClip     = -1
SWEP.Secondary.Automatic       = false
SWEP.Secondary.Ammo            = "dummy"

SWEP.Undroppable               = true
SWEP.CantThrowAmmo             = true

function SWEP:SetupDataTables()
    self:NetworkVar("Float", 0, "NextIdle")
    self:NetworkVar("Float", 1, "FireTimer")
    self:NetworkVar("Bool", 0, "Firing")
end

function SWEP:Initialize()
    BaseClass.Initialize(self)
    
    self.m_bLighterFlame = false
    self.m_bClothFlame = false
    
    self:SetNextIdle(0)
    self:SetFireTimer(0)
    self:SetFiring(false)
    
    self:SetCollisionBounds(self:OBBMins() * 4, self:OBBMaxs() * 4)
end

function SWEP:Deploy()
    self:SetNextIdle(CurTime() + self:SequenceDuration())
    self:EmitSound(self.DrawSound)
    return true
end

function SWEP:PrimaryAttack()
    if not self:CanPrimaryAttack() then return end
    
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK_1)
    self:SetNextPrimaryFire(CurTime() + self:SequenceDuration())
    self:SetFiring(true)
    self:SetFireTimer(CurTime() + self:SequenceDuration())
end

function SWEP:CanPrimaryAttack()
    if self.Owner:GetAmmoCount(self.Primary.Ammo) <= 0 then
        return false
    end

    return self:GetNextPrimaryFire() <= CurTime()
end

function SWEP:Reload()
    return false
end

function SWEP:Think()
    if self:GetFiring() and self:GetFireTimer() < CurTime() then
        local owner = self.Owner
        
        if SERVER then
            if owner:GetAmmoCount(self.Primary.Ammo) > 0 then
                local forward = owner:EyeAngles():Forward()
                local right = owner:EyeAngles():Right()
                local up = owner:EyeAngles():Up()
                
                self:CallOnClient("SpawnClothFlame", "false")
                self:CallOnClient("SpawnLighterFlame", "false")
                
                local ent = ents.Create("projectile_molotov")
                
                if IsValid(ent) then
                    ent:SetOwner(owner)
                    ent:SetPos(owner:GetShootPos() + forward * -8 + right * 6 + up * -8)
                    ent:Spawn()

                    local mPhys = ent:GetPhysicsObject()    
                    if IsValid(mPhys) then
                        local force = owner:GetAimVector() * 3000
                        mPhys:ApplyForceCenter(force)
                    end
                end
            end
        end
        self:SendWeaponAnim(ACT_VM_THROW)
        self:SetNextIdle(CurTime() + self:SequenceDuration())
        
        self:SetFireTimer(0)
        self:SetFiring(false)
        
        if not self.InfiniteAmmo then
            self:TakePrimaryAmmo(1)
        end
        owner:DoAttackEvent()
    end
    
    if SERVER and self.Owner:GetAmmoCount(self.Primary.Ammo) <= 0 then
        self:Remove()
    end
    
    if self:GetNextIdle() ~= 0 and self:GetNextIdle() < CurTime() then
        self:SendWeaponAnim(ACT_VM_IDLE)
        self:SetNextIdle(0)
    end
end

function SWEP:Equip(NewOwner)
    BaseClass.Equip(self, NewOwner)
    NewOwner:GiveAmmo(1, self.Primary.Ammo, true)
end

function SWEP:FireAnimationEvent(pos, ang, event, name)
    if event == 48 then
        self:CallOnClient("SpawnLighterFlame", "true")
    elseif event == 3900 then
        self:CallOnClient("SpawnClothFlame", "true")
    end
end

if SERVER then return end

function SWEP:SpawnLighterFlame(b)
    b = tobool(b)
    
    if b then self:SetJiggerVars() end
    self.m_bLighterFlame = b
end

function SWEP:SpawnClothFlame(b)
    b = tobool(b)
    
    if b then self:SetJiggerVars() end
    self.m_bClothFlame = b
end

function SWEP:SetJiggerVars()
    self.m_fNextJiggerTime = CurTime()
    self.m_iLastJiggerX = 2
    self.m_iLastJiggerY = 4
end

local flamemat = Material("sprites/fire_vm_grey")
function SWEP:ViewModelDrawn(ViewModel)
    if self.m_bLighterFlame then
        local id = ViewModel:LookupBone("ValveBiped.LighterFlame")
        if id ~= 0 then
            local m = ViewModel:GetBoneMatrix(id)
            local pos, ang = m:GetTranslation(), m:GetAngles()
            
            render.SetMaterial(flamemat)
            self:DrawJiggeringSprite(pos + (ang:Forward() * 2))        
        end
    end
    
    if self.m_bClothFlame then
        local id = ViewModel:LookupBone("cloth5")
        if id ~= 0 then
            local m = ViewModel:GetBoneMatrix(id)
            local pos, ang = m:GetTranslation(), m:GetAngles()
            
            render.SetMaterial(flamemat)
            self:DrawJiggeringSprite(pos)            
        end
    end
end

function SWEP:DrawJiggeringSprite(vecAttach)
    local green = 165 - math.random(0, 64)
    local flamecolor = Color(255, green, 0)

    if CurTime() >= self.m_fNextJiggerTime then
        self.m_iLastJiggerX = math.Rand(1.0, 2.0)
        self.m_iLastJiggerY = math.Rand(3.8, 4.2)
        self.m_fNextJiggerTime = CurTime() + math.Rand(0.2, 1.0)
    end

    render.DrawSprite(vecAttach, self.m_iLastJiggerX, self.m_iLastJiggerY, flamecolor)
end

function SWEP:DrawHUD()
    if cvars.Number("zm_maxammo_molotov") > 1 then
        BaseClass.DrawHUD(self)
    end
end