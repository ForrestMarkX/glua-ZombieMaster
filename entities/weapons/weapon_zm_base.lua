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
SWEP.DoViewPunch				= false

SWEP.Primary.Sound				= ""
SWEP.Primary.NumShots			= 1
SWEP.Primary.Recoil				= 0

SWEP.DrawSound    				= ""
SWEP.IsMelee					= false

SWEP.Primary.ClipSize			= -1
SWEP.Primary.DefaultClip		= -1
SWEP.Primary.Ammo			    = "none"
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
		self:SetNextPrimaryFire(CurTime() + 0.2)
		self:Reload()
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
	
	self:SetWeaponHoldType(self.HoldType)

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
	
	local damage = Either(self.Primary.Damage ~= nil, self.Primary.Damage, math.random(self.Primary.MinDamage or 0, self.Primary.MaxDamage or 0))
	self:ShootBullet(damage, self.Primary.NumShots, self.Primary.Cone)
	
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

function SWEP:GetBulletSpread(cone)
	return Vector(cone, cone, 0)
end

function SWEP:ShootBullet(dmg, numbul, cone)
	local owner = self:GetOwner()
	
	numbul 	= numbul or 1
	cone 	= cone or 0.01

	local bullet = {}
	bullet.Num 		= numbul
	bullet.Src 		= owner:GetShootPos()
	bullet.Dir 		= owner:GetAimVector()
	bullet.Spread 	= self:GetBulletSpread(cone)
	bullet.Tracer	= self.TracerFreq
	bullet.TracerName = self.TracerType
	bullet.Force	= dmg * 0.1
	bullet.Damage	= dmg
	bullet.Callback = self.DefaultCallBack
	
	if self.DoViewPunch then
		owner:ViewPunch(self:GetViewPunch())
	end

	local PlayerPos = owner:GetShootPos()
	local PlayerAim = owner:GetAimVector()

	local fx = EffectData()
	fx:SetEntity(self)
	fx:SetOrigin(PlayerPos)
	fx:SetNormal(PlayerAim)
	fx:SetAttachment(self.MuzzleAttachment)
	if self.UseCustomMuzzleFlash then
		util.Effect(self.MuzzleEffect,fx)
	else
		owner:MuzzleFlash()
	end

	owner:FireBullets(bullet)
	
	if not IsValid(owner) then return end
	
	if owner.DoAttackEvent then
		owner:DoAttackEvent()
	else
		owner:SetAnimation(PLAYER_ATTACK1)
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
	self.Dropped = true
end

local ActIndex = {
	[ "pistol" ] 		= ACT_HL2MP_IDLE_PISTOL,
	[ "smg" ] 			= ACT_HL2MP_IDLE_SMG1,
	[ "grenade" ] 		= ACT_HL2MP_IDLE_GRENADE,
	[ "ar2" ] 			= ACT_HL2MP_IDLE_AR2,
	[ "shotgun" ] 		= ACT_HL2MP_IDLE_SHOTGUN,
	[ "rpg" ]	 		= ACT_HL2MP_IDLE_RPG,
	[ "physgun" ] 		= ACT_HL2MP_IDLE_PHYSGUN,
	[ "crossbow" ] 		= ACT_HL2MP_IDLE_CROSSBOW,
	[ "melee" ] 		= ACT_HL2MP_IDLE_MELEE,
	[ "slam" ] 			= ACT_HL2MP_IDLE_SLAM,
	[ "normal" ]		= ACT_HL2MP_IDLE,
	[ "fist" ]			= ACT_HL2MP_IDLE_FIST,
	[ "melee2" ]		= ACT_HL2MP_IDLE_MELEE2,
	[ "passive" ]		= ACT_HL2MP_IDLE_PASSIVE,
	[ "knife" ]			= ACT_HL2MP_IDLE_KNIFE,
	[ "duel" ]      = ACT_HL2MP_IDLE_DUEL,
	[ "revolver" ]		= ACT_HL2MP_IDLE_REVOLVER
}
function SWEP:SetWeaponHoldType(t)
	t = string.lower(t)
	local index = ActIndex[t]
	
	if index == nil then
		Msg( "SWEP:SetWeaponHoldType - ActIndex[ \""..t.."\" ] isn't set! (defaulting to normal)\n" )
		t = "normal"
		index = ActIndex[t]
	end

	self.ActivityTranslate = {}
	self.ActivityTranslate[ACT_MP_STAND_IDLE] 					= index
	self.ActivityTranslate[ACT_MP_WALK] 						= index+1
	self.ActivityTranslate[ACT_MP_RUN] 							= index+2
	self.ActivityTranslate[ACT_MP_CROUCH_IDLE] 					= index+3
	self.ActivityTranslate[ACT_MP_CROUCHWALK] 					= index+4
	self.ActivityTranslate[ACT_MP_ATTACK_STAND_PRIMARYFIRE] 	= index+5
	self.ActivityTranslate[ACT_MP_ATTACK_CROUCH_PRIMARYFIRE]	= index+5
	self.ActivityTranslate[ACT_MP_RELOAD_STAND]		 			= index+6
	self.ActivityTranslate[ACT_MP_RELOAD_CROUCH]		 		= index+6
	self.ActivityTranslate[ACT_MP_JUMP] 						= index+7
	self.ActivityTranslate[ACT_RANGE_ATTACK1] 					= index+8
	self.ActivityTranslate[ACT_MP_SWIM_IDLE] 					= index+8
	self.ActivityTranslate[ACT_MP_SWIM] 						= index+9
	
	if t == "normal" then
		self.ActivityTranslate [ ACT_MP_JUMP ] = ACT_HL2MP_JUMP_SLAM
	end
	
	if t == "knife" or t == "melee2" then
		self.ActivityTranslate [ ACT_MP_CROUCH_IDLE ] = nil
	end
end

SWEP:SetWeaponHoldType("fist")

function SWEP:TranslateActivity(act)
	return self.ActivityTranslate and self.ActivityTranslate[act] or -1
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
	local wid, hei = ScreenScale(60), ScreenScale(21)
	local x, y = ScrW() * 0.865, ScrH() * 0.91
	local clip = self.DontDrawSpare and self.Owner:GetAmmoCount(self:GetPrimaryAmmoType()) or self:Clip1()
	local spare = self.Owner:GetAmmoCount(self:GetPrimaryAmmoType())
	local maxclip = self.Primary.ClipSize
	
	if self.CurrentSpare ~= spare then
		self.CurrentSpare = spare
		
		self.LastAmmoTaken = CurTime()
		self.AmmoTimer = CurTime() + 5
	end
	
	if self.CurrentClip1 ~= clip then
		self.CurrentClip1 = clip
		
		self.LastClipTaken = CurTime()
		self.ClipTimer = CurTime() + 5
	end

	draw.RoundedBox(ScreenScale(5), x + 2, y + 2, wid, hei, colBG)

	local displayspare = maxclip > 0 and self.Primary.DefaultClip ~= 99999
	if displayspare or not self.DontDrawSpare then
		draw.SimpleTextBlurry(spare, spare >= 1000 and "zm_hud_font_small" or "zm_hud_font_normal", x + wid * 0.75, y + hei * 0.5, spare == 0 and colRed or spare <= maxclip and colYellow or colWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, self.LastAmmoTaken, self.AmmoTimer)
	end

	GetAmmoColor(clip, maxclip)
	draw.SimpleTextBlurry(clip, clip >= 100 and "zm_hud_font_normal" or "zm_hud_font_big", x + wid * (displayspare and 0.25 or 0.5), y + hei * 0.5, colAmmo, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, self.LastClipTaken, self.ClipTimer)
end

function SWEP:DrawWeaponSelection( x, y, wide, tall, alpha )
	draw.SimpleTextBlurry(self.WeaponSelectIconLetter, "ZMDeathFonts", x + wide / 2, y + tall * 0.2, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER)

	if self.ShakeWeaponSelectIcon then
		draw.SimpleTextBlurry(self.WeaponSelectIconLetter, "ZMDeathFonts", x + wide / 2 + math.Rand(-4, 4), y + tall * 0.2 + math.Rand(-14, 14), Color(255, 255, 255, math.Rand(10, 120)), TEXT_ALIGN_CENTER)
		draw.SimpleTextBlurry(self.WeaponSelectIconLetter, "ZMDeathFonts", x + wide / 2 + math.Rand(-4, 4), y + tall * 0.2 + math.Rand(-9, 9), Color(255, 255, 255, math.Rand(10, 120)), TEXT_ALIGN_CENTER)
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