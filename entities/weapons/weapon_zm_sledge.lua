AddCSLuaFile()
DEFINE_BASECLASS("weapon_zm_basemelee")

if CLIENT then
	SWEP.PrintName 			= "Sledge"
	SWEP.ViewModelFOV 		= 65
	
	SWEP.WeaponSelectIconLetter	= "i"
end

SWEP.ViewModel 				= "models/weapons/c_sledgehammer_zm.mdl"
SWEP.WorldModel 			= "models/weapons/sledgehammer3rd_zm.mdl"
SWEP.UseHands 				= true

SWEP.Slot 					= 2
SWEP.HoldType 				= "melee2"

SWEP.Primary.MinDamage 		= 45
SWEP.Primary.MaxDamage 		= 55
SWEP.Primary.Force 			= SWEP.Primary.Damage
SWEP.Primary.Reach 			= 85
SWEP.Primary.HitSound 		= Sound("physics/metal/metal_canister_impact_hard1.wav")
SWEP.Primary.HitFleshSound  = Sound("physics/body/body_medium_break2.wav")
SWEP.Primary.MissSound 		= Sound("weapons/iceaxe/iceaxe_swing1.wav")
SWEP.Primary.Delay 			= 2.8

SWEP.Secondary.MinDamage	= 15
SWEP.Secondary.MaxDamage 	= 25
SWEP.Secondary.HitSound 	= "Weapon_Crowbar.Melee_Hit"
SWEP.Secondary.HitFleshSound = "Weapon_Crowbar.Melee_Hit"
SWEP.Secondary.MissSound 	= "Weapon_Crowbar.Single"

function SWEP:SetupDataTables()
	BaseClass.SetupDataTables(self)
	self:NetworkVar("Float", 1, "AttackTime")
	self:NetworkVar("Bool", 1, "IsSecondary")
end

function SWEP:Initialize()
	BaseClass.Initialize(self)
	self:SetAttackTime(0)
	self:SetIsSecondary(false)
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
	self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
	
	self:SetHoldType("melee")
	self:SendWeaponAnim(ACT_VM_HITCENTER2)
	self:SetAttackTime(CurTime() + 1.75)
	
	self:SetIsSecondary(false)
	
	self:SetNextIdle(CurTime() + self:SequenceDuration())
end

function SWEP:SecondaryAttack()
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
    self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
	
	self:SetHoldType("melee")
	self:SendWeaponAnim(ACT_VM_HITCENTER)
	self:SetAttackTime(CurTime() + 1.5)
	
	self:SetIsSecondary(true)
	
	self:SetNextIdle(CurTime() + self:SequenceDuration())
end

function SWEP:CanSecondaryAttack()
	return self:GetNextSecondaryFire() <= CurTime()
end

function SWEP:Swing(alt)
	local owner = self.Owner
	owner:SetAnimation(PLAYER_ATTACK1)
	
	self:SetHoldType("melee2")
	
	local hitsound = Either(alt, self.Secondary.HitSound, self.Primary.HitSound)
	local hitfleshsound = Either(alt, self.Secondary.HitFleshSound, self.Primary.HitFleshSound)
	local misssound = Either(alt, self.Secondary.MissSound, self.Primary.MissSound)
	local mindamage, maxdamage = Either(alt, self.Secondary.MinDamage or 0, self.Primary.MinDamage or 0), Either(alt, self.Secondary.MaxDamage or 0, self.Primary.MaxDamage or 0)
	local damage = Either(self.Primary.Damage ~= nil, self.Primary.Damage, math.random(mindamage, maxdamage))
	
	local trace = util.TraceLine( {
		start = owner:GetShootPos(),
		endpos = owner:GetShootPos() + (self.Owner:GetAimVector() * self.Primary.Reach),
		filter = owner
	} )
    if trace.Hit then
		bullet 		  = {}
		bullet.Num    = 1
		bullet.Src    = owner:GetShootPos()
		bullet.Dir    = owner:GetAimVector()
		bullet.Spread = Vector(0, 0, 0)
		bullet.Tracer = 0
		bullet.Force  = self.Primary.Force
		bullet.Damage = math.random(mindamage, maxdamage)
		bullet.Callback = self.DefaultCallBack
		
		owner:FireBullets(bullet)
		
		if trace.MatType == MAT_FLESH then
			self:EmitSound(hitfleshsound)
		else
			self:EmitSound(hitsound)
		end
    else
        self:EmitSound(misssound, 75, math.random(35, 45))
    end
end

function SWEP:Think()
	BaseClass.Think(self)
	
	if self:GetAttackTime() ~= 0 and self:GetAttackTime() < CurTime() then
		self:SetAttackTime(0)
		self:Swing(self:GetIsSecondary())
	end
end