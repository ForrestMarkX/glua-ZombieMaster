AddCSLuaFile()

if CLIENT then
	SWEP.PrintName = "Rifle"

	SWEP.ViewModelFlip = false
	SWEP.DrawCrosshair = true
	SWEP.ViewModelFOV = 50
end

SWEP.Author = "Mka0207 & Forrest Mark X"

SWEP.Base	= "weapon_zs_base"

SWEP.Slot = 3
SWEP.SlotPos = 0

SWEP.Weight = 25
SWEP.ViewModel	= "models/weapons/c_rifle_zm.mdl"
SWEP.WorldModel	= Model( "models/weapons/rifle_zm_3rd.mdl" )
SWEP.UseHands = true

SWEP.ReloadSound = Sound("Weapon_Rifle_ZM.Reload")
SWEP.Primary.Sound = Sound("Weapon_Rifle_ZM.Single")
SWEP.EmptySound = Sound("Weapon_Rifle_ZM.Empty")
SWEP.PumpSound = Sound("Weapon_Rifle_ZM.Special1")

SWEP.HoldType = "ar2"

SWEP.Primary.ClipSize			 = 11
SWEP.Primary.Damage				= 90
SWEP.Primary.NumShots 			= 1
SWEP.Primary.Delay 				= 1.6

SWEP.ReloadDelay = 0.8

SWEP.Primary.Automatic   		= true
SWEP.Primary.Ammo         		= "357"

GAMEMODE:SetupDefaultClip(SWEP.Primary)

SWEP.Secondary.Delay = 0.3
SWEP.Secondary.ClipSize = 1
SWEP.Secondary.DefaultClip = 1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "dummy"

SWEP.ConeMax = 0
SWEP.ConeMin = 0

SWEP.reloadtimer = 0
SWEP.nextreloadfinish = 0

SWEP.NextZoom = 0
SWEP.SecondaryDelay = 0.25

function SWEP:SetupDataTables()
	self:NetworkVar( "Float", 0, "RiflePump" )
end

function SWEP:Initialize()
	self.BaseClass.Initialize(self)
	
	self:SetRiflePump( 0 )
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

	if self:GetRiflePump() ~= 0 and self:GetRiflePump() < CurTime() then
		self:SendWeaponAnim(ACT_SHOTGUN_PUMP) 
		self:EmitSound(self.PumpSound)
		self:SetRiflePump( 0 )
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
		self.Owner:ViewPunch( Angle( -2, 0, 0 ) )
	end	
	self:SetRiflePump( CurTime() + 0.7 )
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

if SERVER then
	function SWEP:SecondaryAttack()
		if self.Owner:IsHolding() then return end
		if CurTime() < self.NextZoom then return end
		 
		local owner = self.Owner

		self.NextZoom = CurTime() + self.SecondaryDelay

		local zoomed = self:GetDTBool(1)
		self:SetDTBool(1, not zoomed)

		if zoomed then
			owner:SetFOV(owner:GetInfo("fov_desired"), 0.15)
		else
			owner:SetFOV(owner:GetInfo("fov_desired") * 0.25, 0.15)
		end
	end
else
	function SWEP:SecondaryAttack()
		if self.Owner:IsHolding() then return end
		if CurTime() < self.NextZoom then return end
		self.NextZoom = CurTime() + self.SecondaryDelay

		local zoomed = self:GetDTBool(1)
		self:SetDTBool(1, not zoomed)
	end
	
	function SWEP:PreDrawViewModel(vm, wep, ply)
		if self.ShowViewModel == false then render.SetBlend(0) end
		if self:GetDTBool(1) then render.SetBlend(0) end
	end
end

function SWEP:Holster()
	if self:GetDTBool(1) then
		local owner = self.Owner
		owner:SetFOV(owner:GetInfo("fov_desired"), 0.5)
		self:EmitSound("weapons/sniper/sniper_zoomout.wav", 50, 100)
		self:SetDTBool(1, false)
	end

	return true
end

function SWEP:OnRemove()
	local owner = self.Owner
	if owner:IsValid() and self:GetDTBool(1) then
		owner:SetFOV(owner:GetInfo("fov_desired"), 0.5)
	end
end