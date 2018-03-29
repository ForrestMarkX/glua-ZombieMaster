AddCSLuaFile()
DEFINE_BASECLASS("player_basezm")

local PLAYER = {}

PLAYER.WalkSpeed 			= 170
PLAYER.RunSpeed				= 170
PLAYER.CrouchedWalkSpeed	= 0.65

PLAYER.AvoidPlayers			= false
PLAYER.TeammateNoCollide	= false

function PLAYER:Spawn()
	BaseClass.Spawn(self)
	
	self.Player:CrosshairEnable()
	self.Player:SetMoveType(MOVETYPE_WALK)
	self.Player:SetCollisionGroup(COLLISION_GROUP_PLAYER)
	self.Player:ResetHull()
	self.Player:UnSpectate()
	
	self.Player:StripWeapons()
	self.Player:SetColor(color_white)

	if self.Player:GetMaterial() ~= "" then
		self.Player:SetMaterial("")
	end
	
	if GetConVar("zm_disableplayercollision"):GetBool() then
		self.Player:SetCustomCollisionCheck(true)
	end
	
	self.Player:SendLua([[
		gamemode.Call("RemoveZMPanels")
		
		local ply = LocalPlayer()
		if not IsValid(ply.QuickInfo) then
			ply.QuickInfo = vgui.Create("CHudQuickInfo")
			ply.QuickInfo:Center()
		end	
	]])
end

function PLAYER:Loadout()
	self.Player:Give("weapon_zm_fists")
	self.Player:Give("weapon_zm_carry")
end

function PLAYER:Think()
	BaseClass.Think(self)
	
	if SERVER then
		GAMEMODE:CheckIfPlayerStuck(self.Player)
		
		if self.Player:WaterLevel() == 3 then
			if self.Player:IsOnFire() then
				self.Player:Extinguish()
			end

			if self.Player.Drowning then
				if self.Player.Drowning < CurTime() then
					local dmginfo = DamageInfo()
					dmginfo:SetDamage(15)
					dmginfo:SetDamageType(DMG_DROWN)
					dmginfo:SetAttacker(game.GetWorld())

					self.Player:TakeDamageInfo(dmginfo)

					self.Player.Drowning = CurTime() + 1
				end
			else
				self.Player.Drowning = CurTime() + 15
			end
		else
			if self.Player.DrownDamage then
				local timername = "zm_playerdrown_regen."..self.Player:EntIndex()
				if timer.Exists(timername) then return end
				
				timer.Create(timername, 2, 0, function()
					if not IsValid(self.Player) or self.Player:Health() == self.Player:GetMaxHealth() then 
						self.Player.DrownDamage = nil
						timer.Remove(timername) 
						return 
					end
					
					local d = DamageInfo()
					d:SetAttacker(self.Player)
					d:SetInflictor(self.Player)
					d:SetDamageType(DMG_DROWNRECOVER)
					self.Player:TakeDamageInfo(d)
					
					self.Player:SetHealth(self.Player:Health() + 5)
					self.Player.DrownDamage = self.Player.DrownDamage - 5
					
					if self.Player.DrownDamage <= 0 then
						self.Player.DrownDamage = nil
						timer.Remove(timername)
					end
				end)
			end
			
			self.Player.Drowning = nil
		end
	end
end

function PLAYER:AllowPickup(ent)
	if not ent:IsValid() or ent:IsPlayerHolding() or not self.Player:Alive() then return false end
	
	local phys = ent:GetPhysicsObject()
	local objectMass = 0
	if IsValid(phys) then
		objectMass = phys:GetMass()
		if phys:HasGameFlag(FVPHYSICS_NO_PLAYER_PICKUP) or not phys:IsMotionEnabled() then
			return false
		end
	else
		return false
	end
	
	if ent.AllowPickup and not ent:AllowPickup(self.Player) then 
		return false 
	end
	
	if CARRY_MASS > 0 and objectMass > CARRY_MASS then
		return false
	end

	--[[
	if sizeLimit > 0 then
		local size = ent:OBBMaxs() - ent:OBBMins()
		if size.x > sizeLimit or size.y > sizeLimit or size.z > sizeLimit then
			return false
		end
	end
	--]]
	
	return true
end

function PLAYER:CanPickupWeapon(ent)
	if SERVER and self.Player.DelayPickup and self.Player.DelayPickup > CurTime() then 
		self.Player.DelayPickup = 0
		return false 
	end
	
	if self.Player:Alive() then
		if ent.ThrowTime and ent.ThrowTime > CurTime() then return false end

		if self.Player:HasWeapon(ent:GetClass()) then 
			if ent.WeaponIsAmmo then
				return hook.Call("PlayerCanPickupItem", GAMEMODE, self.Player, ent)
			end
			
			return false 
		end
		
		local weps = self.Player:GetWeapons()
		for index, wep in pairs(weps) do
			local slot = wep:GetSlot()
			if slot == 0 then continue end
			
			if slot == ent:GetSlot() then
				return false
			end
		end
		
		if SERVER and (ent:CreatedByMap() or ent.Dropped) then
			local class = ent:GetClass()
			
			self.Player:Give(class)
			
			local wep = self.Player:GetWeapon(class)
			if not wep.IsMelee and wep:GetClass() == class then
				wep:SetClip1(ent:Clip1())
				wep:SetClip2(ent:Clip2())
			end
			
			ent:Remove()
			return false
		end
		
		return true
	end
	
	self.Player.DelayPickup = CurTime() + 0.2
	
	return false
end

function PLAYER:CanPickupItem(item)
	if self.Player.DelayItemPickup and self.Player.DelayItemPickup > CurTime() then 
		self.Player.DelayItemPickup = 0
		return false 
	end
	
	if self.Player:Alive() and item:GetClassName() ~= nil then
		if item.ThrowTime and item.ThrowTime > CurTime() then return false end
		
		for _, wep in pairs(self.Player:GetWeapons()) do
			local primaryammo = wep.Primary and wep.Primary.Ammo or ""
			local secondaryammo = wep.Secondary and wep.Secondary.Ammo or ""
			local ammotype = GAMEMODE.AmmoClass[item:GetClassName()] or ""
			
			if string.lower(primaryammo) == string.lower(ammotype) or string.lower(secondaryammo) == string.lower(ammotype) then
				local ammovar = GetConVar("zm_maxammo_"..primaryammo or secondaryammo)
				
				if ammovar == nil then return end
				
				if self.Player:GetAmmoCount(ammotype) < ammovar:GetInt() then
					if item:IsWeapon() then
						self.Player:GiveAmmo(GAMEMODE.AmmoCache[ammotype], ammotype, false)
						item:Remove()
						
						return false
					end
					
					return true
				end
			end
		end
		
		return false
	end
	
	self.Player.DelayItemPickup = CurTime() + 0.2
	
	return false
end

function PLAYER:SetupMove(mv, cmd)
	if IsValid(self.Player.HeldObject) and bit.band(cmd:GetButtons(), IN_ATTACK) ~= 0 then
		local ent = self.Player.HeldObject
		if ent:IsPlayerHolding() then 
			DropEntityIfHeld(ent)
			
			local ang = Angle(util.SharedRandom("physpax", 0.2, 1.0), util.SharedRandom("physpay", -0.5, 0.5), 0.0)
			self.Player:ViewPunch(ang)
			
			local phys = ent:GetPhysicsObject()
			if IsValid(phys) then
				local massFactor = math.Remap(math.Clamp(phys:GetMass(), 0.5, 15), 0.5, 15, 0.5, 4)
				phys:ApplyForceCenter(self.Player:GetAimVector() * (2000 * massFactor))
				ent:SetPhysicsAttacker(self.Player)
			end
			
			return true
		end
	end
end

function PLAYER:ButtonDown(button)
	if SERVER then return end
	
	if button == cvars.Number("zm_dropweaponkey", 0) then
		RunConsoleCommand("zm_dropweapon")
	elseif button == cvars.Number("zm_dropammokey", 0) then
		RunConsoleCommand("zm_dropammo")
	end
end

function PLAYER:DrawHUD()
	local wid, hei = ScreenScale(75), ScreenScale(24)
	local x, y = ScrW() * 0.035, ScrH() * 0.9
	
	draw.RoundedBox(ScreenScale(5), x + 2, y + 2, wid, hei, Color(60, 0, 0, 200))
	
	local health = self.Player:Health()
	if self.Player.CurrentHP ~= health then
		self.Player.CurrentHP = health
		
		LocalPlayer().LastHurtTime = CurTime()
		LocalPlayer().HurtTimer = CurTime() + 5
	end
	
	local health = self.Player:Health()
	local healthCol = health <= 10 and Color(185, 0, 0, 255) or health <= 30 and Color(150, 50, 0) or health <= 60 and Color(255, 200, 0) or color_white
	draw.SimpleTextBlurry(health, "zm_hud_font_big", x + wid * 0.72, y + hei * 0.5, healthCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, self.Player.LastHurtTime, self.Player.HurtTimer)
	draw.SimpleTextBlurry("#Valve_Hud_HEALTH", "zm_hud_font_small", x + wid * 0.25, y + hei * 0.7, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function PLAYER:PreDeath(inflictor, attacker)
	BaseClass.PreDeath(self, inflictor, attacker)
	
	self.Player:SendLua([[
		if IsValid(LocalPlayer().QuickInfo) then
			LocalPlayer().QuickInfo:Remove()
		end
	]])
	
	for _, wep in pairs(self.Player:GetWeapons()) do
		if IsValid(wep) and not wep.Undroppable then
			self.Player:DropWeapon(wep)
		end
	end
end

function PLAYER:OnDeath(attacker, dmginfo)
	BaseClass.OnDeath(self, attacker, dmginfo)
	
	local pZM = GAMEMODE:FindZM()
	if IsValid(pZM) then
		local income = math.random(GetConVar("zm_resourcegainperplayerdeathmin"):GetInt(), GetConVar("zm_resourcegainperplayerdeathmax"):GetInt())
		
		pZM:AddZMPoints(income)
		pZM:SetZMPointIncome(pZM:GetZMPointIncome() - 5)
	end
	
	self.Player:Flashlight(false)
	self.Player:RemoveEffects(EF_DIMLIGHT)
end

function PLAYER:PostOnDeath(inflictor, attacker)
	if player.GetCount() == 1 then return end
	
	timer.Simple(0.15, function()
		if team.NumPlayers(TEAM_SURVIVOR) == 0 then
			hook.Call("TeamVictorious", GAMEMODE, false, "undead_has_won")
		end
	end)
end

function PLAYER:OnTakeDamage(attacker, dmginfo)
	local inflictor = dmginfo:GetInflictor()
	if IsValid(attacker) and attacker:GetClass() == "projectile_molotov" then
		return true
	end
	
	if IsValid(inflictor) and inflictor:GetClass() == "projectile_molotov" then
		return true
	end
	
	if attacker:GetClass() == "env_fire" and attacker:GetOwner() == self.Player then
		dmginfo:ScaleDamage(0.25)
	end
	
	if bit.band(dmginfo:GetDamageType(), DMG_DROWN) ~= 0 and dmginfo:GetDamage() > 0 then
		self.Player.DrownDamage = (self.Player.DrownDamage or 0) + dmginfo:GetDamage()
	end
	
	if dmginfo:GetDamage() > 0 and self.Player:Health() > 0 and bit.band(dmginfo:GetDamageType(), DMG_DROWN) == 0 and self:ShouldTakeDamage(attacker) and not self.Player:HasGodMode() then
		self.Player:PlayPainSound()
	end
end

function PLAYER:ShouldTakeDamage(attacker)
	if attacker.PBAttacker and attacker.PBAttacker:IsValid() and CurTime() < attacker.NPBAttacker then -- Protection against prop_physbox team killing. physboxes don't respond to SetPhysicsAttacker()
		attacker = attacker.PBAttacker
	end
	
	if IsValid(attacker) then
		local entteam = attacker.OwnerTeam
		if attacker:GetClass() == "env_fire" and entteam == self.Player:Team() and attacker:GetOwner() ~= self.Player then
			return false
		elseif attacker:GetClass() == "env_delayed_physexplosion" then
			return false
		end
	end

	if attacker:IsPlayer() and attacker ~= self.Player and not attacker.AllowTeamDamage and not self.Player.AllowTeamDamage and attacker:Team() == self.Player:Team() then return false end
	
	local entclass = attacker:GetClass()
	if string.find(entclass, "item_") then
		return false
	end

	return true
end

player_manager.RegisterClass("player_survivor", PLAYER, "player_basezm")