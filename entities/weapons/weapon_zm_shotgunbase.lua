DEFINE_BASECLASS("weapon_zm_base")

SWEP.Base = "weapon_zm_base"
SWEP.HoldType = "shotgun"

SWEP.Primary.Delay = 0.8
SWEP.ReloadDelay = 1
SWEP.ReloadSpeed = 1.0

SWEP.ReloadSound = Sound("Weapon_Shotgun_ZM.Reload")
SWEP.Primary.Sound = Sound("Weapon_Shotgun_ZM.Single")
SWEP.PumpSound = Sound("Weapon_Shotgun_ZM.Special1")
SWEP.EmptySound = Sound("Weapon_Shotgun_ZM.Empty")

SWEP.Primary.Ammo = "buckshot"

SWEP.CurReload = ACT_VM_RELOAD
SWEP.EndReloadPump = ACT_SHOTGUN_PUMP
SWEP.BeginReload = ACT_SHOTGUN_RELOAD_START

function SWEP:SetupDataTables()
	BaseClass.SetupDataTables(self)
	
	self:NetworkVar( "Float", 1, "ShotgunPump" )
	self:NetworkVar( "Float", 2, "PumpEnd" )
	self:NetworkVar( "Bool", 0, "Pumping" )
end

function SWEP:Initialize()
	BaseClass.Initialize(self)
	
	self:SetShotgunPump(0)
	self:SetPumpEnd(0)
	self:SetPumping(false)
end

function SWEP:Reload()
	if not self:IsReloading() and self:CanReload() then
		self:StartReloading()
	end
end

function SWEP:Think()
	if self:ShouldDoReload() then
		self:DoReloadThink()
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

	self:NextThink(CurTime())
	return true
end

function SWEP:StartReloading()
	local delay = self:GetReloadDelay()
	self:SetDTFloat(3, CurTime() + delay)
	if self.HoldForReload then
		self:SetDTBool(2, true)
	end
	self:SetNextPrimaryFire(CurTime() + math.max(self.Primary.Delay, delay))

	self:GetOwner():DoReloadEvent()

	if self.BeginReload then
		self:SendWeaponAnim(self.BeginReload)
	end
end

function SWEP:StopReloading()
	self:SetDTFloat(3, 0)
	if self.HoldForReload then
		self:SetDTBool(2, false)
	end
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)

	if self:Clip1() > 0 then
		if self.PumpSound then
			self:EmitSound(self.PumpSound)
		end
		if self.EndReloadPump then
			self:SendWeaponAnim(self.EndReloadPump)
		end
	end
end

function SWEP:GetReloadDelay()
	local reloadspeed = self.ReloadSpeed * (self.ReloadTimeMultiplier or 1)
	return self.ReloadDelay / reloadspeed
end

function SWEP:ShouldDoReload()
	return self:GetDTFloat(3) > 0 and CurTime() >= self:GetDTFloat(3)
end

function SWEP:IsReloading()
	return self:GetDTFloat(3) > 0
end

function SWEP:CanReload()
	return self:Clip1() < self.Primary.ClipSize and 0 < self:GetOwner():GetAmmoCount(self.Primary.Ammo)
end

function SWEP:SecondaryAttack()
end

function SWEP:DoReloadThink()
	local owner = self:GetOwner()
	if not self:CanReload() or owner:KeyDown(IN_ATTACK) or (self.HoldForReload and not self:GetDTBool(2) and not owner:KeyDown(IN_RELOAD)) then
		self:StopReloading()
		return
	end

	local delay = self:GetReloadDelay()
	if self.CurReload then
		self:SendWeaponAnim(self.CurReload)
	end

	if self.ReloadSound then
		self:EmitSound(self.ReloadSound)
	end

	owner:RemoveAmmo(1, self.Primary.Ammo, false)
	self:SetClip1(self:Clip1() + 1)

	if self.HoldForReload then
		self:SetDTBool(2, false)
	end
	self:SetDTFloat(3, CurTime() + delay)

	self:SetNextPrimaryFire(CurTime() + math.max(self.Primary.Delay, delay))
end

function SWEP:CanPrimaryAttack()
	if self:Clip1() <= 0 then
		self:EmitSound("weapons/shotgun/shotgun_empty.wav", 75, math.random(95,100))
		self:SetNextPrimaryFire(CurTime() + 0.25)
		return false
	end

	if self:IsReloading() then
		self:StopReloading()
		return false
	end

	return true
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