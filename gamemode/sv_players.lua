local meta = FindMetaTable("Player")
if not meta then return end

meta.m_iZMPriority = 0

function meta:SetZMPoints(points)
	if points < 0 then points = 0 end
	self:SetDTInt(1, points)
end

function meta:SetZMPointIncome(amount)
	if amount < 0 then amount = 0 end
	self:SetDTInt(2, amount)
end

function meta:AddZMPoints(amount)
	local resources = self:GetZMPoints()
	self:SetZMPoints(resources + amount)
end

function meta:TakeZMPoints(amount)
	local resources = self:GetZMPoints()
	self:SetZMPoints(resources - amount)
end

function meta:ChangeTeamDelayed(delay, teamid)
	timer.Simple(delay, function() hook.Call("PlayerJoinTeam", GAMEMODE, self, teamid) end)
end

function meta:Gib()
	local pos = self:LocalToWorld(self:OBBCenter())

	local effectdata = EffectData()
		effectdata:SetEntity(self)
		effectdata:SetOrigin(pos)
	util.Effect("gib_player", effectdata, true, true)

	self.Gibbed = CurTime()

	timer.Simple(0, function()
		GAMEMODE.CreateGibs(GAMEMODE, pos, self:LocalToWorld(self:OBBMaxs()).z - pos.z)
	end)
end

function meta:DropAllAmmo()
	local ammotbl = {}
	for _, wep in pairs(self:GetWeapons()) do
		if wep.WeaponIsAmmo then continue end
		
		local ammotype = wep.Primary and wep.Primary.Ammo or ""
		if ammotype ~= "" and ammotype ~= "none" and not ammotbl[ammotype] then
			ammotbl[ammotype] = self:GetAmmoCount(ammotype)
		end
	end
	
	if ammotbl == {} then return end
	
	for ammotype, ammoamount in pairs(ammotbl) do
		local ent = ents.Create("item_zm_ammo")
		if IsValid(ent) then
			local vecOrigin = Vector(math.Rand(-0.25, 0.25), math.Rand(-0.25, 0.25), math.Rand(-0.25, 0.25))
			ent:SetPos(self:GetPos() + vecOrigin)

			local vecAngles = Angle(math.Rand( -20.0, 20.0 ), math.Rand( 0.0, 360.0 ), math.Rand( -20.0, 20.0 ))
			ent:SetAngles(self:GetAngles() + vecAngles)

			local vecActualVelocity = Vector(math.random(-10.0, 10.0), math.random(-10.0, 10.0), math.random(-10.0, 10.0))
			ent:SetVelocity(self:GetVelocity() + vecActualVelocity)
			
			local ammoclass = Either(ammotype == "buckshot", "item_box_"..ammotype, "item_ammo_"..ammotype)
			
			ent.ClassName = ammoclass
			ent.Model = GAMEMODE.AmmoModels[ammoclass]
			ent.AmmoAmount = ammoamount
			ent.AmmoType = ammotype
			ent:Spawn()
		end
	end
end