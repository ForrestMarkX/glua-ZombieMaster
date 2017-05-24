AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

ENT.bWasLarge = false

function ENT:Initialize()
	self:SetModel("models/Items/item_item_crate.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)

	local phys = self:GetPhysicsObject()
	if phys:IsValid() then
		phys:EnableMotion(true)
		phys:Wake()
	end

	self:SetMaxObjectHealth(30)
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

function ENT:SetObjectHealth(health)
	self:SetDTFloat(0, health)
	if health <= 0 and not self.Destroyed then
		self.Destroyed = true

		local ent = ents.Create("prop_physics")
		if ent:IsValid() then
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
	end
end

function ENT:OnTakeDamage(dmginfo)
	self:TakePhysicsDamage(dmginfo)

	local attacker = dmginfo:GetAttacker()
	if not (attacker:IsValid() and attacker:IsPlayer() and attacker:Team() == TEAM_HUMAN) then
		self:SetObjectHealth(self:GetObjectHealth() - dmginfo:GetDamage())
	end
end

ENT.IsAmmo = false
function ENT:Think()
	if self.Destroyed then
		local playercount = player.GetCount()
		if playercount > 64 then
			self.itemcount = math.Round(self.itemcount * 4)
		elseif playercount > 32 then
			self.itemcount = math.Round(self.itemcount * 3)
		elseif playercount > 16 then
			self.itemcount = math.Round(self.itemcount * 2.5)
		elseif playercount > 8 then
			self.itemcount = math.Round(self.itemcount * 1.5)
		end
		
		if bWasLarge then
			self.itemcount = self.itemcount * 2
		end
		
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

				pSpawn:Spawn()
				
				local mins, maxs = self:OBBMins() * 0.85, self:OBBMaxs() * 0.85
				local pos = self:LocalToWorld(Vector(math.Rand(mins.x, maxs.x), math.Rand(mins.y, maxs.y), math.Rand(mins.z, maxs.z)))
				pSpawn:SetPos( pos )
				
				pSpawn:SetAngles( self:GetAngles() + AngleRand() )
				pSpawn:SetAbsVelocity( VectorRand() * 3 )
			end
		end
		
		self:Remove()
	end
end