AddCSLuaFile()

if CLIENT then
	SWEP.PrintName = "Revolver"

	SWEP.ViewModelFlip = false
	SWEP.DrawCrosshair = true
	SWEP.ViewModelFOV = 50
end

SWEP.Author = "Mka0207 & Forrest Mark X"

SWEP.Base	= "weapon_zs_base"

SWEP.Slot = 1
SWEP.SlotPos = 0

SWEP.Weight = 25
SWEP.ViewModel	= "models/weapons/c_revolver_zm.mdl"
SWEP.WorldModel	= Model( "models/weapons/w_357.mdl" )
SWEP.UseHands = true

SWEP.ReloadSound = Sound("weapons/revolver_zm/revolver_reload.wav")
SWEP.Primary.Sound = Sound("weapons/revolver_zm/revolver_fire.wav")
SWEP.EmptySound = Sound("weapons/pistol_zm/pistol_zm_empty.wav")

SWEP.HoldType = "revolver"

SWEP.Primary.ClipSize			 = 6
SWEP.Primary.Damage				= 48
SWEP.Primary.NumShots 			= 1
SWEP.Primary.Delay 				= 1.2

SWEP.ReloadDelay = 0.4

SWEP.Primary.Automatic   		= false
SWEP.Primary.Ammo         		= "revolver"

GAMEMODE:SetupDefaultClip(SWEP.Primary)

SWEP.Secondary.Delay = 0.3
SWEP.Secondary.ClipSize = 1
SWEP.Secondary.DefaultClip = 1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "dummy"

SWEP.ConeMax = 0.055
SWEP.ConeMin = 0.0200

function SWEP:Think()
	if self.firing and self.firetimer < CurTime() then
		local owner = self.Owner
		owner:DoAttackEvent()
		self:EmitFireSound()
		
		self:TakeAmmo()
		owner:FireBullets({Num = self.Primary.NumShots, Src = owner:GetShootPos(), Dir = owner:GetAimVector(), Spread = Vector(self:GetCone(), self:GetCone(), 0), Tracer = 1, TracerName = self.TracerName, Force = self.Primary.Damage * 0.1, Damage = self.Primary.Damage, Callback = self.BulletCallback})
		if owner:IsValid() then
			owner:ViewPunch( Angle(-8, math.Rand(-2, 2), 0) )
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
	local owner = self.Owner
	self:SetNextPrimaryFire(CurTime() + self.Secondary.Delay)

	self:EmitFireSound()
	self:TakeAmmo()
	self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
	owner:FireBullets({Num = self.Primary.NumShots, Src = owner:GetShootPos(), Dir = owner:GetAimVector(), Spread = Vector(self:GetCone(), self:GetCone(), 0), Tracer = 1, TracerName = self.TracerName, Force = self.Primary.Damage * 0.1, Damage = self.Primary.Damage, Callback = self.BulletCallback})
	if owner:IsValid() then
		owner:ViewPunch( Angle(-8, math.Rand(-2, 2), 0) )
	end
	self.IdleAnimation = CurTime() + self:SequenceDuration()
end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
	self.firing = true
	self.firetimer = CurTime() + 0.38
	self:SendWeaponAnimation()
	self.IdleAnimation = CurTime() + self:SequenceDuration()
end

function SWEP:Reload()
	if self.Owner:IsHolding() then return end
	
	if self:GetNextReload() <= CurTime() and self:DefaultReload(ACT_VM_RELOAD) then
		self.IdleAnimation = CurTime() + self:SequenceDuration()
		self:SetNextReload(self.IdleAnimation)
		self.Owner:DoReloadEvent()
		if self.ReloadSound then
			timer.Simple(1.5, function() self:EmitSound(self.ReloadSound) end)
		end
	end
end