AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

ENT.bWasLarge = false

function ENT:Initialize()
	self:SetModel("models/Items/item_item_crate.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:EnableMotion(true)
		phys:Wake()
	end
	
	self:AddEFlags(EFL_NO_ROTORWASH_PUSH)

	self:SetMaxObjectHealth(20)
	self:SetObjectHealth(self:GetMaxObjectHealth())
	
	self.cratetype = self.cratetype or nil
	self.itemclass = self.itemclass or nil
	self.itemcount = self.itemcount or 0
end

function ENT:KeyValue(key, value)
	key = string.lower(key)
	if key == "cratetype" then
		self.cratetype = value or self.cratetype
	elseif key == "itemclass" then
		local ammotype = string.Replace(value, "_large", "")
		self.itemclass = ammotype or self.itemclass
		
		if string.find(value, "_large") then
			bWasLarge = true
		end
	elseif key == "itemcount" then
		self.itemcount = tonumber(value)
	end
end

function ENT:AcceptInput(name, activator, caller, args)
	name = string.lower(name)
	if name == "kill" then
		self:Remove()
		return true
	end
end

function ENT:Use(activator, caller)
	if self:IsPlayerHolding() or IsValid(caller.HeldObject) then return end
	
	if hook.Call("AllowPlayerPickup", GAMEMODE, caller, self) then
		caller:PickupObject(self)
	end
end

ENT.IsAmmo = false
function ENT:SetObjectHealth(health)
	self:SetDTFloat(0, health)
	if health <= 0 and not self.Destroyed then
		self.Destroyed = true
		
		local playercount = player.GetCount()
		if playercount >= 64 then
			self.itemcount = math.Round(self.itemcount * 2.5)
		elseif playercount >= 32 then
			self.itemcount = math.Round(self.itemcount * 2)
		elseif playercount >= 16 then
			self.itemcount = math.Round(self.itemcount * 1.5)
		end
		
		if bWasLarge then
			self.itemcount = self.itemcount * 2
		end
		
		self.itemcount = math.min(self.itemcount, 32)
		
		for i=1, self.itemcount do
			local pSpawn
			if string.find(self.itemclass, "item_ammo") or string.find(self.itemclass, "item_box") then
				pSpawn = ents.Create("item_zm_ammo")
				self.IsAmmo = true
			else
				pSpawn = ents.Create(self.itemclass)
				self.IsAmmo = false
			end
			if IsValid(pSpawn) then
				if self.IsAmmo then
					local class = self.itemclass
					
					pSpawn.Model = GAMEMODE.AmmoModels[class]
					pSpawn.AmmoAmount = GAMEMODE.AmmoCache[GAMEMODE.AmmoClass[class]]
					pSpawn.AmmoType = GAMEMODE.AmmoClass[class]
					pSpawn.ClassName = class
					
					pSpawn = hook.Call("CreateCustomAmmo", GAMEMODE, pSpawn, true)
				else
					pSpawn = hook.Call("CreateCustomWeapons", GAMEMODE, pSpawn, true)
				end
				
				local vecOrigin = self:RandomPointInBounds(Vector(0.25, 0.25, 0.25), Vector(0.75, 0.75, 0.75))
				pSpawn:SetPos(vecOrigin)

				local vecAngles = Angle(math.Rand(-20.0, 20.0), math.Rand(0.0, 360.0), math.Rand(-20.0, 20.0))
				pSpawn:SetAngles(vecAngles)
				
				pSpawn:Spawn()
			end
		end
		
		local ent = ents.Create("prop_physics")
		if IsValid(ent) then
			ent:SetModel(self:GetModel())
			ent:SetMaterial(self:GetMaterial())
			ent:SetAngles(self:GetAngles())
			ent:SetPos(self:GetPos())
			ent:SetSkin(self:GetSkin() or 0)
			ent:SetColor(self:GetColor())
			ent:Spawn()
			ent:Fire("break", "", 0)
			ent:Fire("kill", "", 0.1)
		end
		
		self:Remove()
	end
end

function ENT:OnTakeDamage(dmginfo)
	if self.Destroyed then return true end
	
	self:TakePhysicsDamage(dmginfo)

	local attacker = dmginfo:GetAttacker()
	if not (attacker:IsValid() and attacker:IsPlayer() and attacker:Team() == TEAM_HUMAN) then
		self:SetObjectHealth(self:GetObjectHealth() - dmginfo:GetDamage())
	end
end