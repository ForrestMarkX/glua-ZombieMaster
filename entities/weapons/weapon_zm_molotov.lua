AddCSLuaFile()
DEFINE_BASECLASS("weapon_zm_base")

if CLIENT then
	SWEP.PrintName = "Molotovs"

	SWEP.ViewModelFlip = false
	SWEP.ViewModelFOV = 55
	
	SWEP.WeaponSelectIconLetter	= "k"
end

SWEP.Author = "Mka0207 & Forrest Mark X"

SWEP.Slot = 4
SWEP.SlotPos = 0

SWEP.ViewModel	= "models/weapons/c_molotov_zm.mdl"
SWEP.WorldModel	= Model( "models/weapons/molotov3rd_zm.mdl" )
SWEP.UseHands = true
SWEP.WeaponIsAmmo = true

SWEP.HoldType = "grenade"
SWEP.DontDrawSpare = true

SWEP.Primary.Recoil			= 0
SWEP.Primary.Delay 			= 0
SWEP.Primary.Damage			= 0
SWEP.Primary.ClipSize		= 0
SWEP.Primary.DefaultClip	= 1
SWEP.Primary.Reload 		= 0
SWEP.Primary.Automatic   		= false
SWEP.Primary.Ammo         		= "molotov"

SWEP.Secondary.Delay = 0.3
SWEP.Secondary.ClipSize = 1
SWEP.Secondary.DefaultClip = 1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "dummy"

SWEP.Undroppable = true
SWEP.CantThrowAmmo = true

function SWEP:SetupDataTables()
	self:NetworkVar("Float", 0, "NextIdle")
	self:NetworkVar("Float", 1, "FireTimer")
	self:NetworkVar("Bool", 0, "Firing")
end

function SWEP:Initialize()
	self.BaseClass.Initialize(self)
	
	self.m_bLighterFlame = false
	self.m_bClothFlame = false
	
	self:SetNextIdle(0)
	self:SetFireTimer(0)
	self:SetFiring(false)
end

function SWEP:PreDrawViewModel()
	if self.noammo then
		render.SetBlend(0)
	end
end

function SWEP:PostDrawViewModel(vm)
	if self.noammo then
		render.SetBlend(1)
	end
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
	
	if self.noammo and self.Owner:GetAmmoCount(self.Primary.Ammo) > 0 then
		self:SendWeaponAnim(ACT_VM_DEPLOY)
		self:SetNextIdle(CurTime() + self:SequenceDuration())
		self.noammo = false
	end
	
	if self.Owner:GetAmmoCount(self.Primary.Ammo) <= 0 and not self.noammo then
		self.noammo = true
	end
	
	if self:GetNextIdle() ~= 0 and self:GetNextIdle() < CurTime() then
		self:SendWeaponAnim(ACT_VM_IDLE)
		self:SetNextIdle(0)
	end
end