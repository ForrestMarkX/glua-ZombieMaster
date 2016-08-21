DEFINE_BASECLASS("weapon_zm_base")

SWEP.ReloadSound = Sound("Weapon_Shotgun_ZM.Reload")
SWEP.Primary.Sound = Sound("Weapon_Shotgun_ZM.Single")
SWEP.PumpSound = Sound("Weapon_Shotgun_ZM.Special1")
SWEP.EmptySound = Sound("Weapon_Shotgun_ZM.Empty")

SWEP.Primary.Automatic   		= false
SWEP.Primary.Ammo         		= "buckshot"

SWEP.Secondary.Delay = 0.3
SWEP.Secondary.ClipSize = 1
SWEP.Secondary.DefaultClip = 1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "dummy"

function SWEP:SetupDataTables()
	BaseClass.SetupDataTables(self)
	
	self:NetworkVar( "Float", 1, "ShotgunPump" )
	self:NetworkVar( "Float", 2, "PumpEnd" )
	self:NetworkVar( "Float", 3, "ReloadTimer" )
	self:NetworkVar( "Float", 4, "NextReloadFinish" )
	self:NetworkVar( "Bool", 0, "Pumping" )
	self:NetworkVar( "Bool", 1, "Reloading" )
end

function SWEP:Initialize()
	BaseClass.Initialize(self)
	
	self:SetShotgunPump(0)
	self:SetPumpEnd(0)
	self:SetReloadTimer(0)
	self:SetPumping(false)
	self:SetReloading(false)
end

function SWEP:Deploy()
	self:SendWeaponAnim( ACT_VM_DRAW )
	can_reload = true
end

function SWEP:Reload()
	if self:GetReloading() or self:GetPumping() then return end

	if self:Clip1() < self.Primary.ClipSize and 0 < self.Owner:GetAmmoCount(self.Primary.Ammo) then
		self:SetNextPrimaryFire(CurTime() + self.ReloadDelay)
		self:SetReloading(true)
		self:SetReloadTimer(CurTime() + self.ReloadDelay)
		self:SendWeaponAnim(ACT_SHOTGUN_RELOAD_START)
		self.Owner:DoReloadEvent()
	end
end

function SWEP:Think()
	if self:GetReloading() and self:GetReloadTimer() < CurTime() then
		self:SetReloadTimer(CurTime() + self.ReloadDelay)
		self:SendWeaponAnim(ACT_VM_RELOAD)

		self.Owner:RemoveAmmo(1, self.Primary.Ammo, false)
		self:SetClip1(self:Clip1() + 1)
		self:EmitSound(self.ReloadSound)

		if self.Primary.ClipSize <= self:Clip1() or self.Owner:GetAmmoCount(self.Primary.Ammo) <= 0 then
			self:SetNextReloadFinish(CurTime() + self.ReloadDelay)
			self:SetReloading(false)
			self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
		end
	end

	local nextreloadfinish = self:GetNextReloadFinish()
	if nextreloadfinish ~= 0 and nextreloadfinish < CurTime() then
		self:EmitSound(self.PumpSound)
		self:SendWeaponAnim(ACT_SHOTGUN_PUMP)
		self:SetNextReloadFinish(0)
	end

	if self:GetShotgunPump() ~= 0 and self:GetShotgunPump() < CurTime() then
		self:SendWeaponAnim(ACT_SHOTGUN_PUMP) 
		self:EmitSound(self.PumpSound)
		self:SetShotgunPump(0)
	end
	
	local pumpend = self:GetPumpEnd()
	if pumpend ~= 0 and pumpend < CurTime() then
		self:SetPumping(false)
		self:SetPumpEnd(0)
	end
end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end
	
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

	self:EmitSound(self.Primary.Sound)
	
	if not self.InfiniteAmmo then
		self:TakePrimaryAmmo(1)
	end
	
	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	self:ShootBullet(self.Primary.Damage, self.Primary.NumShots, self.Primary.Cone)
	
	if self.Owner:IsValid() then
		self.Owner:ViewPunch( Angle( -5, 0, 0 ) )
	end	
	
	self:SetNextIdle(CurTime() + self:SequenceDuration())
	
	self:SetShotgunPump(CurTime() + 0.5)
	self:SetPumpEnd(CurTime() + 1.3)
	self:SetPumping(true)
end

function SWEP:CanPrimaryAttack()
	if self:Clip1() <= 0 then
		self:EmitSound(self.EmptySound)
		self:SetNextPrimaryFire(CurTime() + 0.25)
		self:Reload()
		return false
	end

	if self:GetReloading() then
		if self:Clip1() < self.Primary.ClipSize then
			self:SendWeaponAnim(ACT_SHOTGUN_RELOAD_FINISH)
		else
			self:SendWeaponAnim(ACT_VM_IDLE)
		end
		self:SetReloading(false)
		self:SetNextPrimaryFire(CurTime() + 0.25)
		return false
	end

	return true
end