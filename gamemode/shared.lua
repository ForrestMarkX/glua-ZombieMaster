GM.Name = "Zombie Master"
GM.Author = "Mka0207 & Forrest Mark X"
GM.Email = "N/A"
GM.Website = "N/A"

TEAM_SURVIVOR = 1
TEAM_ZOMBIEMASTER = 2

team.SetUp(TEAM_SURVIVOR, "Survivors", Color(255, 64, 64, 255)) 
team.SetUp(TEAM_ZOMBIEMASTER, "Zombie Master", Color(153, 255, 153, 255)) 
team.SetUp(TEAM_SPECTATOR, "Spectators", Color(120, 120 , 120, 255))

include("sh_sounds.lua")
include("sh_zm_globals.lua")
include("sh_utility.lua")

include("sh_zm_options.lua")

include("sh_weapons.lua")
include("sh_players.lua")
include("sh_entites.lua")

function GM:Initialize()
	self:PrecacheResources()
	self:AddCustomAmmo()
	
	gamemode.Call("BuildZombieDataTable")
	
	if CLIENT then
		self:CreateFonts()
	else
		self:AddResources()
		self:AddNetworkStrings()
		game.ConsoleCommand("fire_dmgscale 1\nmp_flashlight 1\nsv_gravity 600\n")
		
		local mapinfo = "maps/"..game.GetMap()..".txt"
		if file.Exists(mapinfo, "GAME") then
			self.MapInfo = file.Read(mapinfo, "GAME")
		else
			self.MapInfo = "No objectives found!"
		end
	end
end

function GM:GetPopulationCost(type)
	if type == "npc_zm_fastzombie" then
		return GetConVar("zm_popcost_banshee"):GetInt()
	elseif type == "npc_zm_zombie" then
		return GetConVar("zm_popcost_shambler"):GetInt()
	elseif type == "npc_zm_poisonzombie" then
		return GetConVar("zm_popcost_hulk"):GetInt()
	elseif type == "npc_burnzombie" then
		return GetConVar("zm_popcost_immolator"):GetInt()
	elseif type == "npc_dragzombie" then
		return GetConVar("zm_popcost_drifter"):GetInt()
	end
	
	return 0
end

function GM:GetResourceCost(type)
	if type == "npc_zm_fastzombie" then
		return GetConVar("zm_cost_banshee"):GetInt()
	elseif type == "npc_zm_zombie" then
		return GetConVar("zm_cost_shambler"):GetInt()
	elseif type == "npc_zm_poisonzombie" then
		return GetConVar("zm_cost_hulk"):GetInt()
	elseif type == "npc_burnzombie" then
		return GetConVar("zm_cost_immolator"):GetInt()
	elseif type == "npc_dragzombie" then
		return GetConVar("zm_cost_drifter"):GetInt()
	end
	
	return 0
end

function GM:AddCustomAmmo()
	game.AddAmmoType({ name = "revolver", dmgtype = DMG_BULLET, tracer = TRACER_LINE_AND_WHIZ, plydmg = 0, npcdmg = 0, maxcarry = 24, force = 5000 })
	game.AddAmmoType({ name = "molotov", dmgtype = DMG_BURN, tracer = TRACER_NONE, plydmg = 0, npcdmg = 0, maxcarry = 3, force = 0 })
	game.AddAmmoType({name = "unused"})
end

function GM:PlayerIsAdmin(pl)
	return pl:IsAdmin()
end

function GM:GetFallDamage(pl, fallspeed)
	return 0
end

--Control global default clips here.
function GM:SetupDefaultClip(tab)
	tab.DefaultClip = tab.ClipSize
end

function GM:PrecacheResources()
	for name, mdl in pairs(player_manager.AllValidModels()) do
		util.PrecacheModel(mdl)
	end
	
	for _, mdl in pairs(file.Find("models/zombie/*.mdl", "GAME")) do
		util.PrecacheModel(mdl)
	end
end

--[[
	- Angry Lawyer: April 17, 2007 -
	
	Note about ZombieFlags 
	These are set by adding the following numbers together: 

	0 - Everything 
	1 - Shamblers 
	2 - Banshees 
	4 - Hulks 
	8 - Drifters
	16 - Immolators
	
	Max: 31
]]

function GM:CanSpawnZombie(flag)
	local allowed = {}
	allowed[1] = false
	allowed[2] = false
	allowed[4] = false
	allowed[8] = false
	allowed[16] = false
	
	if flag == 0 then
		return true
	else
		for i = 1, 5 do
			if (flag - 16) >= 0 then
				flag = flag -16
				allowed[16] = true
			end

			if (flag - 8) >= 0 then
				flag = flag -8
				allowed[8] = true
			end

			if (flag - 4) >= 0 then
				flag = flag -4
				allowed[4] = true
			end

			if (flag - 2) >= 0 then
				flag = flag -2
				allowed[2] = true
			end

			if (flag - 1) >= 0 then
				flag = flag -1
				allowed[1] = true
			end
		end
		
		return allowed
	end
	
	return false
end

function GM:FindZM()
	return team.GetPlayers(TEAM_ZOMBIEMASTER)[1]
end

function GM:GetHandsModel(pl)
    local simplemodel = player_manager.TranslateToPlayerModelName( pl:GetModel() )
    return player_manager.TranslatePlayerHands(simplemodel)
end

function GM:OnPlayerHitGround(pl, inwater, hitfloater, speed)
    if inwater then return true end

	local damage = (0.1 * (speed - 525)) ^ 1.2

	if math.floor(damage) > 0 then
		if SERVER then
			pl:TakeSpecialDamage(damage, DMG_FALL, game.GetWorld(), game.GetWorld(), pl:GetPos())
			pl:EmitSound("player/pl_fallpain"..(math.random(2) == 1 and 3 or 1)..".wav")
		end
	end

    return true
end

function GM:PlayerShouldTakeDamage(pl, attacker)
	if attacker.PBAttacker and attacker.PBAttacker:IsValid() and CurTime() < attacker.NPBAttacker then -- Protection against prop_physbox team killing. physboxes don't respond to SetPhysicsAttacker()
		attacker = attacker.PBAttacker
	end
	
	if IsValid(attacker) then
		local attowner = attacker.Team
		if IsValid(attowner) then
			if attacker:GetClass() == "env_fire" and attowner and pl:Team() == attowner then
				return false
			end
		end
	end

	if attacker:IsPlayer() and attacker ~= pl and not attacker.AllowTeamDamage and not pl.AllowTeamDamage and attacker:Team() == pl:Team() then return false end

	return pl:IsSurvivor()
end

function GM:PlayerTraceAttack(pl, dmginfo, dir, trace)
end

function GM:FindUseEntity(pl, ent)
	if not ent:IsValid() then
		local e = pl:TraceLine(90, MASK_SOLID, {pl}).Entity
		if e:IsValid() then return e end
	end

	return ent
end

function GM:IsSpecialPerson(pl, image)
	local img, tooltip
	local steamid = pl:SteamID()

	if steamid == "STEAM_0:1:3307510" then
		img = "icon16/heart.png"
		tooltip = "JetBoom\nContributor!"
	elseif steamid == "STEAM_0:0:8232794" then
		img = "icon16/heart.png"
		tooltip = "Chewgum\nContributor!"
	elseif steamid == "STEAM_0:0:18000855" then
		img = "icon16/heart.png"
		tooltip = "Mka0207\nContributor!"
	elseif pl:IsAdmin() then
		img = "icon16/shield.png"
		tooltip = "Admin"
	end

	if img then
		if CLIENT then
			image:SetImage(img)
			image:SetTooltip(tooltip)
		end

		return true
	end

	return false
end

function GM:SetRoundActive(active)
    SetGlobalBool("roundactive", active)
end

function GM:SetRoundStart(active)
    SetGlobalBool("roundstart", active)
end

function GM:SetRoundEnd(active)
    SetGlobalBool("roundended", active)
end

function GM:GetRoundStart()
    return GetGlobalBool("roundstart", false)
end

function GM:GetRoundActive()
    return GetGlobalBool("roundactive", false)
end

function GM:GetRoundEnd()
    return GetGlobalBool("roundended", false)
end

function GM:GetCurZombiePop()
	return GetGlobalInt("m_iZombiePopCount", 0)
end

function GM:GetMaxZombiePop()
	return GetConVar("zm_zombiemax"):GetInt()
end

function GM:ShouldCollide(enta, entb)
	if enta.ShouldNotCollide and enta:ShouldNotCollide(entb) or entb.ShouldNotCollide and entb:ShouldNotCollide(enta) then
		return false
	end

	return true
end

local zombieData = {}
function GM:AddZombieType(data)
	table.insert(zombieData, data)
end

function GM:GetZombieTable()
	return zombieData
end

function GM:GetZombieData(class)
	for _, data in ipairs(zombieData) do
		if data.class == class then
			return data
		end
	end
end

function GM:BuildZombieDataTable()
	-- Shambler.
	local shambler = {}
	shambler.class = "npc_zm_zombie"
	shambler.name = "Shambler"
	shambler.description = "Weak and slow, but packs a punch and smashes barricades."
	shambler.icon = "VGUI/zombies/info_shambler"
	shambler.flag = 1
	shambler.cost = gamemode.Call("GetResourceCost", shambler.class)
	shambler.popCost = gamemode.Call("GetPopulationCost", shambler.class)

	self:AddZombieType(shambler)

	-- Banshee.
	local banshee = {}
	banshee.class = "npc_zm_fastzombie"
	banshee.name = "Banshee"
	banshee.description = "A fast zombie, it's faster than the rest. But it can't take that much damage."
	banshee.icon = "VGUI/zombies/info_banshee"
	banshee.flag = 2
	banshee.cost = gamemode.Call("GetResourceCost", banshee.class)
	banshee.popCost = gamemode.Call("GetPopulationCost", banshee.class)

	self:AddZombieType(banshee)

	-- Hulk.
	local hulk = {}
	hulk.class = "npc_zm_poisonzombie"
	hulk.name = "Hulk"
	hulk.description = "Big. Strong. Hulks smash humans to bits."
	hulk.icon = "VGUI/zombies/info_hulk"
	hulk.flag = 4
	hulk.cost = gamemode.Call("GetResourceCost", hulk.class)
	hulk.popCost = gamemode.Call("GetPopulationCost", hulk.class)

	self:AddZombieType(hulk)

	-- Drifter.
	local drifter = {}
	drifter.class = "npc_dragzombie"
	drifter.name = "Drifter"
	drifter.description = "Spits disorienting acid over a short distance."
	drifter.icon = "VGUI/zombies/info_drifter"
	drifter.flag = 8
	drifter.cost = gamemode.Call("GetResourceCost", drifter.class)
	drifter.popCost = gamemode.Call("GetPopulationCost", drifter.class)

	self:AddZombieType(drifter)

	-- Immolator.
	local immolator = {}
	immolator.class = "npc_burnzombie"
	immolator.name = "Immolator"
	immolator.description = "Burns itself and everything around it in combat."
	immolator.icon = "VGUI/zombies/info_immolator"
	immolator.flag = 16
	immolator.cost = gamemode.Call("GetResourceCost", immolator.class)
	immolator.popCost = gamemode.Call("GetPopulationCost", immolator.class)

	self:AddZombieType(immolator)
end