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

function SWEP:Initialize()
	self.BaseClass.Initialize(self)
	
	self.m_bLighterFlame = false
	self.m_bClothFlame = false
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
	self.firing = true
	self.firetimer = CurTime() + self:SequenceDuration()
end

if SERVER then
	function SWEP:ThrowMolotov(ply)
		if ply:GetAmmoCount(self.Primary.Ammo) > 0 then
			local forward = ply:EyeAngles():Forward()
			local right = ply:EyeAngles():Right()
			local up = ply:EyeAngles():Up()
			
			local ent = ents.Create("projectile_molotov")
			
			if IsValid(ent) then
				ent:SetOwner(ply)
				ent:SetPos(ply:GetShootPos() + forward * -8 + right * 6 + up * -8)
				ent:Spawn()

				local mPhys = ent:GetPhysicsObject()	
				if IsValid(mPhys) then
					local force = ply:GetAimVector() * 3000
					mPhys:ApplyForceCenter(force)
				end
			end
		end
	end
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
	if self.firing and self.firetimer < CurTime() then
		local owner = self.Owner
		
		if SERVER then
			self:ThrowMolotov(owner)
		end
		self:SendWeaponAnim(ACT_VM_THROW)
		self.IdleAnimation = CurTime() + self:SequenceDuration()
		
		self.firing = false
		self.firetimer = 0
		
		if not self.InfiniteAmmo then
			self:TakePrimaryAmmo(1)
		end
		owner:DoAttackEvent()
	end
	
	if self.noammo and self.Owner:GetAmmoCount(self.Primary.Ammo) > 0 then
		self:SendWeaponAnim(ACT_VM_DEPLOY)
		self.IdleAnimation = CurTime() + self:SequenceDuration()
		self.noammo = false
	end
	
	if self.Owner:GetAmmoCount(self.Primary.Ammo) <= 0 and not self.noammo then
		self.noammo = true
	end
	
	if self.IdleAnimation and self.IdleAnimation <= CurTime() then
		self.IdleAnimation = nil
		self:SendWeaponAnim(ACT_VM_IDLE)
	end
end