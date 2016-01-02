AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:KeyValue(key, value)
	key = string.lower(key)
	if key == "method" then
		self.m_iMethod = tonumber(value) or self.m_iMethod
	end
end

function ENT:FillWeaponLists()
	if GetConVar("zm_loadout_disable"):GetBool() then
		print("info_loadout entities have been disabled with zm_loadout_disable\n")
		return
	end
	
	if self.m_iMethod == 1 then
		table.Empty(self.weaponsCategorised)
		
		self.weaponsCategorised = {
			[0] = { "Improvised", "Sledgehammers"},
			[1] = { "Pistols", "Revolvers" },
			[2] = { "Shotguns", "Rifles", "Mac10s" },
			[3] = { "Molotovs" },
		}
	else
		self.m_iWeaponsAll = { "Improvised", "Sledgehammers", "Pistols", "Revolvers", "Shotguns", "Rifles", "Mac10s", "Molotovs" }
	end
end

function ENT:DistributeToPlayer(ply)
	if not IsValid(ply) and GetConVar("zm_loadout_disable"):GetBool() and ply:Team() ~= TEAM_SURVIVOR then return end

	if self.m_iMethod == 1 then
		for i=1, 4 do
			local tab = self.weaponsCategorised[math.random(#self.weaponsCategorised)]
			
			if tab then
				local pick = tab[math.random(#tab)]
				self:CreateAndGiveWeapon(ply, pick)
				table.RemoveByValue(self.weaponsCategorised, tab)
			end
		end
	else
		local pick = self.m_iWeaponsAll[math.random(#self.m_iWeaponsAll)]
		self:CreateAndGiveWeapon(ply, pick)
		table.RemoveByValue(self.m_iWeaponsAll, pick)
	end
end

function ENT:Distribute()
	if GetConVar("zm_loadout_disable"):GetBool() then
		print("info_loadout entities have been disabled with zm_loadout_disable\n")
		return
	end

	for _, ply in pairs(team.GetPlayers(TEAM_SURVIVOR)) do
		self:DistributeToPlayer(ply)
	end
end

function ENT:CreateAndGiveWeapon(ply, weapon_type)
	if not IsValid(ply) then return end
    
	local WeaponTypeToName = {
		["Improvised"] = "weapon_zm_improvised",
		["Sledgehammers"] = "weapon_zm_sledge",
		["Pistols"] = "weapon_zm_pistol",
		["Shotguns"] = "weapon_zm_shotgun",
		["Rifles"] = "weapon_zm_rifle",
		["Mac10s"] = "weapon_zm_mac10",
		["Revolvers"] = "weapon_zm_revolver",
		["Molotovs"] = "weapon_zm_molotov"
	}

	local weapon_name = WeaponTypeToName[weapon_type]

	local add_ammo = true

	if weapon_type == "Molotovs" then
		add_ammo = false
	end
	
	ply:Give(weapon_name)
	if add_ammo then
		local stored = weapons.GetStored(weapon_name)
		if stored and stored.Primary.Ammo and stored.Primary.DefaultClip then
			ply:GiveAmmo(stored.Primary.DefaultClip, stored.Primary.Ammo)
		end
	end
end