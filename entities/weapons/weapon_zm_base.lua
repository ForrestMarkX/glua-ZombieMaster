SWEP.Category 					= "Zombie Master SWEPs"

SWEP.AutoSwitchTo 				= false
SWEP.AutoSwitchFrom				= false
SWEP.WeaponSelectIconLetter		= "c"
SWEP.DrawAmmo 					= false
SWEP.DrawWeaponInfoBox		 	= false
SWEP.BounceWeaponIcon 			= false
SWEP.SwayScale 					= 1.0
SWEP.BobScale 					= 1.0
SWEP.ViewModelFOV 				= 75
SWEP.ViewModelFlip 				= false
SWEP.CSMuzzleFlashes 			= false
SWEP.UseHands				 	= true
SWEP.DrawCrosshair 				= true

SWEP.Author	 					= "???"
SWEP.Contact 					= ""
SWEP.Purpose 					= ""
SWEP.Instructions 				= ""

SWEP.Spawnable					= false
SWEP.AdminSpawnable				= false

SWEP.UseCustomMuzzleFlash 		= false
SWEP.MuzzleEffect  				= "CSSMuzzleFlashX"
SWEP.MuzzleAttachment 			= "1"

SWEP.ShakeWeaponSelectIcon		= false

SWEP.TracerType                 = "Tracer"

SWEP.InfiniteAmmo               = false
SWEP.DeploySpeed                = 1

SWEP.Primary.Sound				= "Weapon_AK47.Single"
SWEP.Primary.NumShots			= 1
SWEP.Primary.Recoil				= 0

SWEP.DrawSound    				= ""
SWEP.IsMelee					= false

SWEP.Primary.ClipSize			= -1
SWEP.Primary.DefaultClip		= -1
SWEP.Primary.Ammo			    = "smg1"
SWEP.Primary.RandomPitch		= false
SWEP.Primary.MinPitch			= 100
SWEP.Primary.MaxPitch			= 100

SWEP.Secondary.ClipSize			= -1
SWEP.Secondary.DefaultClip		= -1
SWEP.Secondary.Automatic		= false
SWEP.Secondary.Ammo				= "none"

function SWEP:SetupDataTables()
	self:NetworkVar("Float" , 0 , "NextIdle")
end

function SWEP:CanPrimaryAttack()
	if self:Clip1() <= 0 then
		self:EmitSound(self.EmptySound or "Weapon_Pistol.Empty")
		self:SetNextPrimaryFire(CurTime() + math.max(0.25, self.Primary.Delay))
		return false
	end

	return self:GetNextPrimaryFire() <= CurTime()
end

function SWEP:Deploy()
	self:SetNextIdle(CurTime() + self:SequenceDuration())
	self:EmitSound(self.DrawSound)
	return true
end

function SWEP:Initialize()
	if SERVER then
		self:SetNPCMinBurst(30)
		self:SetNPCMaxBurst(30)
		self:SetNPCFireRate(0.01)
	end
	
	self:SetHoldType(self.HoldType)

	self:SetNextIdle(0)
    self:SetDeploySpeed(self.DeploySpeed)
end

function SWEP:PlayPrimaryFireSound()
	self:EmitSound(self.Primary.Sound, 75, Either(self.Primary.RandomPitch, math.random(self.Primary.MinPitch, self.Primary.MaxPitch), 100))
end

function SWEP:PlayReloadSound()
	self:EmitSound(self.ReloadSound)
end

function SWEP:Reload()
	if self:DefaultReload(ACT_VM_RELOAD) then
		self:PlayReloadSound()
		self:SetNextIdle(CurTime() + self:SequenceDuration())
	end
end

function SWEP:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end
	
	self:SetNextSecondaryFire(CurTime() + self.Primary.Delay)
	self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
	
	self:PlayPrimaryFireSound()
	self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
	self:ShootBullet(self.Primary.Damage, self.Primary.NumShots, self.Primary.Cone)
	
	if not self.InfiniteAmmo then
		self:TakePrimaryAmmo(1)
	end
end

function SWEP:DefaultCallBack(tr, dmginfo)
	local ent = tr.Entity
	if IsValid(ent) and not ent:IsPlayer() then
		local phys = ent:GetPhysicsObject()
		if ent:GetMoveType() == MOVETYPE_VPHYSICS and IsValid(phys) and phys:IsMoveable() then
			ent:SetPhysicsAttacker(dmginfo:GetAttacker())
		end
	end
end

function SWEP:ShootBullet(dmg, numbul, cone)
	numbul 	= numbul or 1
	cone 	= cone or 0.01

	local bullet = {}
	bullet.Num 		= numbul
	bullet.Src 		= self.Owner:GetShootPos()
	bullet.Dir 		= self.Owner:GetAimVector()
	bullet.Spread 	= Vector(cone, cone, 0)
	bullet.Tracer	= self.TracerFreq
	bullet.TracerName = self.TracerType
	bullet.Force	= dmg * 0.1
	bullet.Damage	= dmg
	bullet.Callback = self.DefaultCallBack

	local PlayerPos = self.Owner:GetShootPos()
	local PlayerAim = self.Owner:GetAimVector()

	local fx = EffectData()
	fx:SetEntity(self)
	fx:SetOrigin(PlayerPos)
	fx:SetNormal(PlayerAim)
	fx:SetAttachment(self.MuzzleAttachment)
	if self.UseCustomMuzzleFlash then
		util.Effect(self.MuzzleEffect,fx)
	else
		self.Owner:MuzzleFlash()
	end

	self.Owner:FireBullets(bullet)
	
	if self.Owner.DoAttackEvent then
		self.Owner:DoAttackEvent()
	else
		self.Owner:SetAnimation(PLAYER_ATTACK1)
	end
	
	self:SetNextIdle(CurTime() + self:SequenceDuration())
end

function SWEP:Think()
	if self:GetNextIdle() ~= 0 and self:GetNextIdle() < CurTime() then
		self:SendWeaponAnim(ACT_VM_IDLE)
		self:SetNextIdle(0)
	end
end

function SWEP:CanSecondaryAttack()
	return false
end

function SWEP:SecondaryAttack()
end

function SWEP:Equip(NewOwner)
	self.Dropped = false
	NewOwner:EmitSound("items/ammo_pickup.wav", 75, math.random(95, 105), 0.8, CHAN_ITEM)
end

function SWEP:EquipAmmo(ply)
	ply:EmitSound("items/ammo_pickup.wav", 75, 100, 0.8, CHAN_ITEM)
end

function SWEP:OnDrop()
	self:SetSolid(SOLID_BBOX)
	self:SetCollisionBounds(self:OBBMins() * 4, self:OBBMaxs() * 4)
end

if not CLIENT then return end

local colBG = Color(60, 0, 0, 200)
local colRed = Color(220, 0, 0, 230)
local colYellow = Color(220, 220, 0, 230)
local colWhite = Color(220, 220, 220, 230)
local colAmmo = Color(255, 255, 255, 230)
local function GetAmmoColor(clip, maxclip)
	if clip == 0 then
		colAmmo.r = 255 colAmmo.g = 0 colAmmo.b = 0
	else
		local sat = clip / maxclip
		colAmmo.r = 255
		colAmmo.g = sat ^ 0.3 * 255
		colAmmo.b = sat * 255
	end
end

function SWEP:DrawHUD()
	local screenscale = BetterScreenScale()
	local wid, hei = 180 * screenscale, 64 * screenscale
	local x, y = ScrW() * 0.865, ScrH() * 0.91
	local clip = self.DontDrawSpare and self.Owner:GetAmmoCount(self:GetPrimaryAmmoType()) or self:Clip1()
	local spare = self.Owner:GetAmmoCount(self:GetPrimaryAmmoType())
	local maxclip = self.Primary.ClipSize

	draw.RoundedBox(16, x + 2, y + 2, wid, hei, colBG)

	local displayspare = maxclip > 0 and self.Primary.DefaultClip ~= 99999
	if displayspare or not self.DontDrawSpare then
		draw.SimpleTextBlurry(spare, spare >= 1000 and "ZMHUDFontSmall" or "ZMHUDFont", x + wid * 0.75, y + hei * 0.5, spare == 0 and colRed or spare <= maxclip and colYellow or colWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end

	GetAmmoColor(clip, maxclip)
	draw.SimpleTextBlurry(clip, clip >= 100 and "ZMHUDFont" or "ZMHUDFontBig", x + wid * (displayspare and 0.25 or 0.5), y + hei * 0.5, colAmmo, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function SWEP:DrawWeaponSelection( x, y, wide, tall, alpha )
	draw.SimpleText(self.WeaponSelectIconLetter, "ZMDeathFonts", x + wide / 2, y + tall * 0.2, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)

	if self.ShakeWeaponSelectIcon then
		draw.SimpleText(self.WeaponSelectIconLetter, "ZMDeathFonts", x + wide / 2 + math.Rand(-4, 4), y + tall * 0.2 + math.Rand(-14, 14), Color(255, 255, 255, math.Rand(10, 120)), TEXT_ALIGN_CENTER)
		draw.SimpleText(self.WeaponSelectIconLetter, "ZMDeathFonts", x + wide / 2 + math.Rand(-4, 4), y + tall * 0.2 + math.Rand(-9, 9), Color(255, 255, 255, math.Rand(10, 120)), TEXT_ALIGN_CENTER)
	end
end

function SWEP:DoDrawCrosshair(x, y)
	surface.SetDrawColor(0, 0, 0)
	
	surface.DrawRect(x - 23, y - 1, 10, 1)
	surface.DrawRect(x + 13, y - 1, 10, 1)
	surface.DrawRect(x - 1, y - 23, 1, 10)
	surface.DrawRect(x - 1, y + 13, 1, 10)
	
	surface.SetDrawColor(255, 255, 255)
	
	surface.DrawRect(x - 22, y, 8, 1)
	surface.DrawRect(x + 14, y, 8, 1)
	surface.DrawRect(x, y - 22, 1, 8)
	surface.DrawRect(x, y + 14, 1, 8)
	
	surface.SetDrawColor(Color(200, 0, 0))
	surface.DrawRect(x - 1.75, y - 1.75, 4, 4)
	surface.SetDrawColor(0, 0, 0, 220)
	surface.DrawOutlinedRect(x - 1.75, y - 1.75, 4, 4)
	
	return true
end