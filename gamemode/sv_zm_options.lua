CreateConVar("zm_physexp_forcedrop_radius", "128", FCVAR_NOTIFY, "Radius in which players are forced to drop what they carry so that the physexp can affect the objects.")
CreateConVar("zm_loadout_disable", "0", FCVAR_NOTIFY, "If set to 1, any info_loadout entity will not hand out weapons. Not recommended unless you're intentionally messing with game balance and playing on maps that support this move.")

CreateConVar("zm_debug_nozombiemaster", "0", FCVAR_NOTIFY, "Used for debug, will not cause players to become the ZM.")
cvars.AddChangeCallback( "zm_debug_nozombiemaster", function( convar_name, value_old, value_new )
	gamemode.Call("PreRestartRound")
	gamemode.Call("RestartRound")
end )

CreateConVar("zm_roundlimit","2", FCVAR_NOTIFY, "Sets the number of rounds before the server changes map\n" )
CreateConVar("zm_banshee_limit", "-1", { FCVAR_ARCHIVE, FCVAR_NOTIFY }, "Sets maximum number of banshees per survivor that the ZM is allowed to have active at once. Set to 0 or lower to remove the cap. Disabled by default since new population system was introduced that in practice includes a banshee limit.")
CreateConVar("zm_trap_triggerrange", "96", FCVAR_NONE, "The range trap trigger points have.")
CreateConVar("zm_spawndelay", "0.75", FCVAR_NOTIFY, "Delay between creation of zombies at zombiespawn.")
CreateConVar("zm_incometime", "10", FCVAR_NOTIFY, "Amount of time in seconds the Zombie Master gains resources.")
CreateConVar("zm_resourcegainperplayerdeathmin", "50", FCVAR_NOTIFY, "Min amount of resources the Zombie Master gains per player death.")
CreateConVar("zm_resourcegainperplayerdeathmax", "100", FCVAR_NOTIFY, "Max amount of resources the Zombie Master gains per player death.")

local function ZM_Power_PhysExplode_SV(ply, command, arguments)
	if (not IsValid(ply)) or (IsValid(ply) and not ply:IsZM()) then
		return
	end

	local vec = string.Explode(" ", arguments[1])
	local mousepos = Vector(vec[1], vec[2], vec[3])
	local tr = util.TraceLine({start = ply:EyePos(), endpos = ply:EyePos() + mousepos * (75 ^ 2), filter = player.GetAll(), mask = MASK_SOLID})
	if not tr.Hit then
		ply:PrintMessage(HUD_PRINTTALK, "Couldn't find a surface to place the explosion.")
		return
	end
	
	local location = tr.HitPos
	
	if not ply:CanAfford(GetConVar("zm_physexp_cost"):GetInt()) then
		ply:PrintMessage(HUD_PRINTTALK, "Insufficient resources.\n")
		return
	end

	ply:PrintMessage(HUD_PRINTTALK, "Explosion created")
	
	ply:SetZMPoints(ply:GetZMPoints() - GetConVar("zm_physexp_cost"):GetInt())

	local ent = ents.Create("env_delayed_physexplosion")
	if IsValid(ent) then
		ent:Spawn()
		ent:SetPos(location)
		ent:Activate()
		ent:DelayedExplode( ZM_PHYSEXP_DELAY )
		ply:PrintMessage(HUD_PRINTTALK, "Explosion created.")
	end
end
concommand.Add("_place_physexplode_zm", ZM_Power_PhysExplode_SV)

local function ZM_Power_KillZombies(ply)
	if (not IsValid(ply)) or (IsValid(ply) and not ply:IsZM()) then return end
	
	for _, ent in pairs(ents.FindByClass("npc_*")) do
		if ent:GetNWBool("selected") then
			local d = DamageInfo()
			d:SetDamage(ent:Health())
			d:SetDamageType(DMG_DISSOLVE)
		
			ent:TakeDamageInfo(d)
		end
	end
	
	ply:PrintMessage(HUD_PRINTTALK, "Expiring selected zombies...")
end
concommand.Add("zm_power_killzombies", ZM_Power_KillZombies, nil, "Kills all selected zombies")

local function ZM_Power_SpotCreate_SV(ply, command, arguments)
	if (not IsValid(ply)) or (IsValid(ply) and not ply:IsZM()) then
		return
	end

	local vec = string.Explode(" ", arguments[1])
	local mousepos = Vector(vec[1], vec[2], vec[3])
	local tr = util.TraceLine({start = ply:EyePos(), endpos = ply:EyePos() + mousepos * (75 ^ 2), filter = player.GetAll(), mask = MASK_SOLID})
	local location = tr.HitPos

	local tr_floor = util.TraceHull({start = location + Vector(0, 0, 25), endpos = location - Vector(0, 0, 25), filter = player.GetAll(), mins = Vector(-64, -64, 0), maxs = Vector(64, 64, 24), mask = MASK_NPCSOLID})
	if tr_floor.Fraction == 1.0 then
		ply:PrintMessage(HUD_PRINTCENTER, "The zombie does not fit in that location!\n")
		return
	end

	location = tr_floor.HitPos

	if not ply:CanAfford(GetConVar("zm_spotcreate_cost"):GetInt()) then
		ply:PrintMessage(HUD_PRINTTALK, "Insufficient resources.\n")
		return
	end

	local vecSpot = Vector(0,0,0)
	local vecHeadTarget = location

	vecHeadTarget.z = vecHeadTarget.z + 64
	
	for k, v in pairs( ents.FindByClass( "trigger_blockspotcreate" ) ) do
		if IsValid(v) then
			if v.m_bActive then
				local vecMins = v:OBBMins()
				local vecMaxs = v:OBBMaxs()
				if vecMins.x <= location.x and vecMins.y <= location.y and vecMins.z <= location.z and vecMaxs.x >= location.x and vecMaxs.y >= location.y and vecMaxs.z >= location.z then
					ply:PrintMessage( HUD_PRINTTALK, "No hidden zombie may be created there\n" )
					return
				end
			end
		end
	end
	
	for _, pl in pairs(player.GetAll()) do
		if IsValid(pl) then
			vecSpot = pl:GetPos()
			
			local tr = util.TraceLine( {
				start = location,
				endpos = vecSpot,
				filter = player.GetAll(),
				mask = MASK_OPAQUE
			} )

			local visible = false
			if tr.fraction == 1.0 and pl:Team() == TEAM_HUMAN then
				visible = true
			end

			local tr = util.TraceLine( {
				start = vecHeadTarget,
				endpos = vecSpot,
				filter = player.GetAll(),
				mask = MASK_OPAQUE
			} )

			if tr.fraction == 1.0 and pl:Team() == TEAM_HUMAN then
				visible = true
			end
			
			if visible then
				ply:PrintMessage(HUD_PRINTCENTER, "One of the survivors can see this location!\n" )
				return
			end
		end
	end
	
	local pZombie = GAMEMODE:SpawnZombie("npc_zombie", location, ply:EyeAngles(), cost)
	if IsValid(pZombie) then
		pZombie:DropToFloor()
		ply:SetZMPoints(ply:GetZMPoints() - GetConVar("zm_spotcreate_cost"):GetInt())
		ply:PrintMessage(HUD_PRINTTALK, "Hidden zombie spawned.")
	end
end
concommand.Add("_place_zombiespot_zm", ZM_Power_SpotCreate_SV)

local function ZM_Drop_Ammo(ply)
	local wep = ply:GetActiveWeapon()
	
	if not IsValid(wep) then return end
	
	local ammotype = wep.Primary.Ammo
	
	if wep.IsMelee or ammotype == nil or ammotype == "none" then return end
	
	local amount = GAMEMODE.AmmoCache[ammotype]
	
	if ply:GetAmmoCount(ammotype) == 0 then return end
	
	if ply:GetAmmoCount(ammotype) < amount then
		amount = ply:GetAmmoCount(ammotype)
	end
	
	local ent = ents.Create("prop_ammo")
	if IsValid(ent) then
		local vecEye = ply:EyePos()
		local angEye = ply:EyeAngles()
		local vForward = angEye:Forward()

		local vecSrc = vecEye + vForward * 60.0
	
		ent:SetPos(vecSrc)
		ent:SetAmmoType(ammotype)
		ent:SetAmmo(amount)
		ent:Spawn()
		
		local pObj = ent:GetPhysicsObject()
		
		local vecVelocity = ply:GetAimVector() * 200
		
		if IsValid(pObj) then
			pObj:AddVelocity(vecVelocity)
		else
			ent:SetVelocity(vecVelocity)
		end

		ply:RemoveAmmo(amount, ammotype)
	end
end
concommand.Add("zm_dropammo", ZM_Drop_Ammo, nil, "Drops your current weapons ammo")

local function ZM_Drop_Weapon(ply)
	local wep = ply:GetActiveWeapon()
	if IsValid(wep) and not wep.Undroppable then
		local class = wep:GetClass()
		local ent = ents.Create("prop_weapon")
		if IsValid(ent) then
			local vecEye = ply:EyePos()
			local angEye = ply:EyeAngles()
			local vForward = angEye:Forward()

			local vecSrc = vecEye + vForward * 60.0
			
			ent:SetWeaponType(class)
			ent:SetPos(vecSrc)
			ent:Spawn()
			ent:SetClip1(wep:Clip1())
			ent:SetClip2(wep:Clip2())
			
			local pObj = ent:GetPhysicsObject()
			
			local vecVelocity = ply:GetAimVector() * 200
			
			if IsValid(pObj) then
				pObj:AddVelocity(vecVelocity)
			else
				ent:SetVelocity(vecVelocity)
			end

			ply:StripWeapon(class)
			
			local weps = ply:GetWeapons()
			local randwep = weps[math.random(#weps)]
			
			if randwep then
				ply:SelectWeapon(randwep:GetClass())
			end
		end
	end
end
concommand.Add("zm_dropweapon", ZM_Drop_Weapon, nil, "Drops your current weapon")

local function ZM_TraceSelect(ply, command, arguments)
	if ply:IsZM() then
		-- Let's try a shitty method with ents.FindInSphere

		local d, c 				= string.Explode(" ", arguments[1]), string.Explode(" ", arguments[2])
		local vectorA, vectorB 	= Vector(d[1], d[2], d[3]), Vector(c[1], c[2], c[3])
		local distance 			= (vectorA:Distance(vectorB)) / 2 -- The distance between vectorA and vectorB for sphere.
		local middle		 	= (vectorA + vectorB) / 2 -- Hopefully this is the right position.
		
		-- Chewgum: Find the entities inside the selection.
		local entities = ents.FindInSphere(middle, distance);

		for _, entity in ipairs(entities) do
			if entity:IsNPC() then
				entity:SetNWBool("selected", true)
			end
		end
	end
end
concommand.Add("zm_traceselect", ZM_TraceSelect, nil, "Shouldn't be used from console")

local function ZM_Select(ply, command, arguments)
	if ply:IsZM() then
		local entity = ents.GetByIndex(tonumber(arguments[1]))
		
		if not ply:KeyDown(IN_DUCK) then
			for _, npc in pairs(ents.FindByClass("npc_*")) do
				if npc:GetNWBool("selected") then
					npc:SetNWBool("selected", false)
				end
			end
		end
	
		if IsValid(entity) and entity:IsNPC() then
			local selected = entity:GetNWBool("selected")
			
			if selected then
				entity:SetNWBool("selected", false)
			else
				entity:SetNWBool("selected", true)
			end
		end
	end
end
concommand.Add("zm_selectnpc", ZM_Select, nil, "Select a group of/single NPC(s)")

local function ZM_Command_NPC(ply, command, arguments)
	if ply:IsZM() then
		local vec = string.Explode(" ", arguments[1])
		local position = Vector(vec[1], vec[2], vec[3])
		
		for _, entity in pairs(ents.FindByClass("npc_*")) do
			if IsValid(entity) and entity:GetNWBool("selected", false) and entity:IsNPC() then
				entity:SetLastPosition(position)
				entity:SetSchedule(SCHED_FORCED_GO_RUN)
				
				entity.isMoving = true
			end
		end
	end
end
concommand.Add("zm_command_npcgo", ZM_Command_NPC, nil, "Marks the position the selected NPCs should go")

local function ZM_Deselect(ply)
	if ply:IsZM() then
		for _, entity in pairs(ents.FindByClass("npc_*")) do
			entity:SetNWBool("selected", false)
		end
	end
end
concommand.Add("zm_deselect", ZM_Deselect, nil, "Deselects all NPCs")

concommand.Add("zm_clicktrap", function(ply, command, arguments)
	if ply:IsZM() then
		local entity = ents.GetByIndex(tonumber(arguments[1]))

		if IsValid(entity) then
			entity:Trigger(ply)
			ply:TakeZMPoints(entity:GetCost())
		end
	end
end)

concommand.Add("zm_selectall_zombies", function(ply, command, arguments)
	if ply:IsZM() then
		for _, entity in pairs(ents.FindByClass("npc_*")) do
			if entity.isZombie and entity:IsNPC() then
				entity:SetNWBool("selected", true)
			end
		end
		
		ply:PrintMessage(HUD_PRINTTALK, "Selected all zombies")
	end
end)

concommand.Add("zm_placetrigger", function(ply, command, arguments)
	if ply:IsZM() then
		local position = Vector(arguments[1], arguments[2], arguments[3])
		local entity = ents.GetByIndex(tonumber(arguments[4]))
		local cost = entity:GetTrapCost()
		
		if ply:CanAfford(cost) then
			local trigger = ents.Create("info_manipulate_trigger")
			trigger:SetPos(position)
			trigger:Spawn()
			trigger:SetParent(entity)
		
			ply:TakeZMPoints(cost)
			
			ply:PrintMessage(HUD_PRINTTALK, "Creating trap trigger...")
		end
	end
end)

concommand.Add("zm_spawnzombie", function(ply, command, arguments)
	if ply:IsZM() then
		local entity = ents.GetByIndex(tonumber(arguments[1]))
		local type = arguments[2]
		local amount = tonumber(arguments[3])
	
		if IsValid(entity) then
			entity:AddQuery(ply, type, amount)
		end
	end
end)

concommand.Add("zm_rqueue", function(ply, command, arguments)
	if ply:IsZM() then
		local entity = ents.GetByIndex(tonumber(arguments[1]))
		local clear = arguments[2]
	
		if IsValid(entity) then
			if clear == "1" then
				entity:ClearQueue(true)
			else
				entity:ClearQueue()
			end
		end
	end
end)

concommand.Add("zm_placerally", function(ply, command, arguments)
	if ply:IsZM() then
		local position = Vector(arguments[1], arguments[2], arguments[3]) + Vector(0, 0, 7)
		local entity = ents.GetByIndex(tonumber(arguments[4]))
		
		if IsValid(entity) then
			local rally = entity:GetRallyEntity()
			if IsValid(rally) then
				rally:Remove()
			end
			
			local rallyPoint = ents.Create("info_rallypoint")
			rallyPoint:SetPos(position)
			rallyPoint:Spawn()
			rallyPoint:ActivateRallyPoint()

			entity:SetRallyEntity(rallyPoint)
			
			ply:PrintMessage(HUD_PRINTTALK, "Creating rally point...")
		end
	end
end)

GM.groups = {}
GM.currentmaxgroup = 0
GM.selectedgroup = 0
concommand.Add("zm_creategroup", function(ply, command, arguments)
	if ply:IsZM() then
		if GAMEMODE.currentmaxgroup >= 9 then return end
		
		table.Empty(GAMEMODE.groups)
		
		currentmaxgroup = GAMEMODE.currentmaxgroup + 1
		GAMEMODE.groups[currentmaxgroup] = {}
		
		local groupadd = GAMEMODE.groups[currentmaxgroup]
		for _, npc in pairs(ents.FindByClass("npc_*")) do
			if npc:GetNWBool("selected", false) then
				table.insert(groupadd, npc)
			end
		end
		
		GAMEMODE.selectedgroup = currentmaxgroup
		
		ply:PrintMessage(HUD_PRINTTALK, "Creating group...")

		net.Start("zm_sendcurrentgroups")
			net.WriteTable(GAMEMODE.groups)
		net.Send(ply)
		
		net.Start("zm_sendselectedgroup")
			net.WriteUInt(GAMEMODE.selectedgroup, 8)
		net.Send(ply)
	end
end)

concommand.Add("zm_setselectedgroup", function(ply, command, arguments)
	if ply:IsZM() then
		local groupnum = string.Replace(arguments[1], "Group ", "")
		for i, group in pairs(groups) do
			if groupnum == i then
				GAMEMODE.selectedgroup = i
				break
			end
		end
		
		net.Start("zm_sendselectedgroup")
			net.WriteUInt(GAMEMODE.selectedgroup, 8)
		net.Send(ply)
	end
end)

concommand.Add("zm_selectgroup", function(ply, command, arguments)
	if ply:IsZM() then
		local selection = GAMEMODE.groups[GAMEMODE.selectedgroup]
		for i, npc in pairs(selection) do
			if IsValid(npc) and npc:IsNPC() then
				npc:SetNWBool("selected", true)
			end
		end
		
		ply:PrintMessage(HUD_PRINTTALK, "Selecting group...")
	end
end)