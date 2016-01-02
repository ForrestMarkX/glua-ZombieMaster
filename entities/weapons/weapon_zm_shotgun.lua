AddCSLuaFile()

if CLIENT then
	SWEP.PrintName = "Shotgun"

	SWEP.ViewModelFlip = false
	SWEP.DrawCrosshair = true
	SWEP.ViewModelFOV = 55
end

SWEP.Author = "Mka0207 & Forrest Mark X"

SWEP.Base	= "weapon_zs_base"

SWEP.Slot = 3
SWEP.SlotPos = 0

SWEP.Weight = 25
SWEP.ViewModel	= "models/weapons/c_shotgun_zm.mdl"
SWEP.WorldModel	= Model( "models/weapons/w_shotgun_zm.mdl" )
SWEP.UseHands = true

SWEP.ReloadSound = Sound("Weapon_Shotgun_ZM.Reload")
SWEP.Primary.Sound = Sound("Weapon_Shotgun_ZM.Single")
SWEP.PumpSound = Sound("Weapon_Shotgun_ZM.Special1")
SWEP.EmptySound = Sound("Weapon_Shotgun_ZM.Empty")


SWEP.HoldType = "shotgun"

SWEP.Primary.ClipSize			 = 8
SWEP.Primary.Damage				= 9
SWEP.Primary.NumShots 			= 10
SWEP.Primary.Delay 				= 1.1

SWEP.ReloadDelay = 0.4
SWEP.RequiredClip = 1

SWEP.Primary.Automatic   		= false
SWEP.Primary.Ammo         		= "buckshot"

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

function SWEP:SetupDataTables()
	self:NetworkVar( "Float", 0, "ShotgunPump" )
end

function SWEP:Initialize()
	self.BaseClass.Initialize(self)
	
	self:SetShotgunPump( 0 )
	self.pumpend = 0
end

function SWEP:Deploy()
	self.Weapon:SendWeaponAnim( ACT_VM_DRAW )
	can_reload = true
end

function SWEP:Reload()
	if self.Owner:IsHolding() then return end
	if self.reloading or self.pumping then return end

	if self:Clip1() < self.Primary.ClipSize and 0 < self.Owner:GetAmmoCount(self.Primary.Ammo) then
		self:SetNextPrimaryFire(CurTime() + self.ReloadDelay)
		self.reloading = true
		self.reloadtimer = CurTime() + self.ReloadDelay
		self:SendWeaponAnim(ACT_SHOTGUN_RELOAD_START)
		self.Owner:DoReloadEvent()
	end
end

function SWEP:Think()
	if self.reloading and self.reloadtimer < CurTime() then
		self.reloadtimer = CurTime() + self.ReloadDelay
		self:SendWeaponAnim(ACT_VM_RELOAD)

		self.Owner:RemoveAmmo(1, self.Primary.Ammo, false)
		self:SetClip1(self:Clip1() + 1)
		self:EmitSound(self.ReloadSound)

		if self.Primary.ClipSize <= self:Clip1() or self.Owner:GetAmmoCount(self.Primary.Ammo) <= 0 then
			self.nextreloadfinish = CurTime() + self.ReloadDelay
			self.reloading = false
			self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
		end
	end

	local nextreloadfinish = self.nextreloadfinish
	if nextreloadfinish ~= 0 and nextreloadfinish < CurTime() then
		self:EmitSound(self.PumpSound)
		self:SendWeaponAnim(ACT_SHOTGUN_PUMP)
		self.nextreloadfinish = 0
	end

	if self:GetShotgunPump() ~= 0 and self:GetShotgunPump() < CurTime() then
		self:SendWeaponAnim(ACT_SHOTGUN_PUMP) 
		self:EmitSound(self.PumpSound)
		self:SetShotgunPump( 0 )
	end
	
	if self.pumpend ~= 0 and self.pumpend < CurTime() then
		self.pumping = false
		self.pumpend = 0
	end
end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

	self:EmitFireSound()
	--self:MuzzleFlash()
	self:TakeAmmo()
	self:ShootBullets(self.Primary.Damage, self.Primary.NumShots, self:GetCone())
	if self.Owner:IsValid() then
		self.Owner:ViewPunch( Angle( -5, 0, 0 ) )
	end	
	self.IdleAnimation = CurTime() + self:SequenceDuration()
	self:SetShotgunPump( CurTime() + 0.5 )
	self.pumpend = CurTime() + 1.3
	self.pumping = true
end

function SWEP:CanPrimaryAttack()
	if self.Owner:IsHolding() then return false end
	
	if self:Clip1() <= 0 then
		self:EmitSound(self.EmptySound)
		self:SetNextPrimaryFire(CurTime() + 0.25)
		self:Reload()
		return false
	end

	if self.reloading then
		if self:Clip1() < self.Primary.ClipSize then
			self:SendWeaponAnim(ACT_SHOTGUN_RELOAD_FINISH)
		else
			self:SendWeaponAnim(ACT_VM_IDLE)
		end
		self.reloading = false
		self:SetNextPrimaryFire(CurTime() + 0.25)
		return false
	end

	return true
end
