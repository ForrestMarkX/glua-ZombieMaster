-- Author: Bradenm1
-- Repo: https://github.com/Bradenm1/Zombie-master-ai
-- Saving while playing and editing the bot will break it

-- Constants
local MAPSETTINGSPATH = GM.FolderName.."/gamemode/modules/ai/maps"
local HUMANTEAM = 1
local ZOMBIEMASTERTEAM = 2
local SPECTATORTEAM = 3
local DAMAGEZOMBIEMULTIPLIER = 1.25

local names = include("sv_bot_names.lua")

-- Vars
local speedDelay, spawnDelay, commandDelay, killZombieDelay, spawnRangeDelay, explosionDelay = 0, 0, 0, 0, 0, 0 -- Delays
local zmBot = nil -- Where the player bot is stored, this is more effiencent since don't need to loop though all bots

-- Bot Options
-- Chance: 0.0 never use 1.0 always use
-- Radius/Range: Units
-- Theses are the default stats
local options = {
    MaxZombies             = 60, -- Max zombies this changes depending on the players
    SpawnRadius            = 3000, -- Max spawn distance
    DeleteRadius         = 3000, -- Min distance to delete zombies
    ZombiesPerPlayer    = 14, -- Zombies per player on the server
    MinTrapRange        = 92, -- Min range to use trap around players
    MaxTrapRange         = 224, -- Max range to use trap around players
    TrapUsageRadius        = 128, -- Max distance to use a trap when a player is near
    UseTrapChance          = 0.2, -- Use trap chance
    MinTrapChance          = -0.02, -- Min trap chance
    MaxTrapChance          = 1, -- Max trap chance
    SpawnZombieChance    = 0.5, -- Zombie spawn Chance
    MaxZombieTypeChance    = 10, -- Type of zombie to spawn chance
    MinSpawnChance        = 0.03, -- Min zombie spawn chance
    MaxSpawnChance        = 1, -- Max zombie spawn chance
    IncressSpawnRange    = 300, -- How much it should incress the range by
    UseExplosionChance    = 0.1, -- Min explosion chance
    MinExplosionChance    = -0.01, -- Max explosion chance
    MaxExplosionChance    = 0.01, -- Use explosion chance
    ExplosionSearchRange= 32, -- Range from player it searches
    ExplosionUseAmount    = 8, -- Number of Entites needed in range
    BotSpeed            = 1, -- Delay in seconds, speed of the bot as a whole
    ZombieSpawnDelay     = 3, -- Delay in seconds, zombie spawn delay
    CommandDelay         = 1, -- Delay in seconds, command zombie delay
    KillZombieDelay        = 1, -- Delay in seconds, killing zombies
    SpawnRangeDelay        = 10, -- Delay in seconds, incressing range if no zombies
    ExplosionDelay        = 35, -- Delay in seconds
    Playing                = true, -- If the bot is currently playing
    Debug                 = false, -- Used for basic debugging
    SetUp                 = true, -- Setup for the bot
    LastSpawned            = nil, -- Last spawner used
    LastTrapUsed        = nil, -- Last trap used
    LastZombieCommanded = nil, -- Last zombie commanded
    Traps                = {}, -- Used to stored the traps at round starts if dynamic is false
    Explosions            = {},
    PlayersToIgnore        = {} -- List of players to be ignored by the AI
}

----------------------------------------------------
-- get_amount_zm_bots()
-- Returns amount of Zombie Master bots
-- @return amount Integer: Amount of bots
----------------------------------------------------
local function get_amount_zm_bots()
    local amount = 0
    for _, bot in pairs(player.GetBots()) do 
        if (bot.IsZMBot) then amount = amount + 1 end
    end
    return amount
end

----------------------------------------------------
-- get_last_zombie_commanded()
-- Returns last zombie the AI commanded
-- @return options.LastZombieUsed Entity: Zombie
----------------------------------------------------
local function get_last_zombie_commanded()
    return options.LastZombieCommanded
end

----------------------------------------------------
-- get_zombie_amount()
-- Gets amount of zombies currently on the map
-- @return amount Integer: amount of zombies
----------------------------------------------------
local function get_zombie_population()
    return gamemode.Call("GetCurZombiePop")
end

----------------------------------------------------
-- get_max_zombies()
-- Gets the max zombies
-- @return maxZombies Integer: max zombies
----------------------------------------------------
local function get_max_zombies()
    return #team.GetPlayers(HUMANTEAM) * options.ZombiesPerPlayer
end

----------------------------------------------------
-- get_max_zombies()
-- Gets the max zombies
-- @return amount Integer: number of zombie types
----------------------------------------------------
local function get_zombie_type_amount()
    return table.Count(gamemode.Call("GetZombieTable", false))
end

----------------------------------------------------
-- get_zombie_chance()
-- Returns the chance of picking a zombie
-- @return chance Integer: chance
----------------------------------------------------
local function get_zombie_chance()
    return math.random(0, options.MaxZombieTypeChance) % get_zombie_type_amount()
end

----------------------------------------------------
-- get_chance_explosion()
-- Returns a random decimnal number
-- @return chance Float: chance
----------------------------------------------------
local function get_chance_explosion()
    return math.Rand(options.MinExplosionChance, options.MaxExplosionChance) -- Negative means trap won't get used
end

----------------------------------------------------
-- get_chance_trap()
-- Returns a random decimnal number
-- @return chance Float: chance
----------------------------------------------------
local function get_chance_trap()
    return math.Rand(options.MinTrapChance, options.MaxTrapChance) -- Negative means trap won't get used
end

----------------------------------------------------
-- get_chance_spawn()
-- Returns a random decimnal number
-- @return chance Float: chance
----------------------------------------------------
local function get_chance_spawn()
    return math.Rand(options.MinSpawnChance, options.MaxSpawnChance) -- 0.03 would be 3% and 1 would be 100%
end

----------------------------------------------------
-- get_trap_usage_radius()
-- Returns a random Integer number
-- @return radius Integer: returns an amount
----------------------------------------------------
local function get_trap_usage_radius()
    return math.random(options.MinTrapRange, options.MaxTrapRange) -- In units
end

----------------------------------------------------
-- get_last_trap_used()
-- Returns last trap the AI used
-- @return options.LastTrapUsed Entity: Trap
----------------------------------------------------
local function get_last_trap_used()
    return options.LastTrapUsed
end

----------------------------------------------------
-- remove_player_ignore()
-- Checks if player should be ignored by the AI
-- @param Boolean: If player should be ignored
----------------------------------------------------
local function get_player_in_ignore_table(ply)
    local ignorePlayer = table.KeyFromValue(options.PlayersToIgnore, ply:AccountID())
    if (ignorePlayer) then return true else return false end
end

----------------------------------------------------
-- get_players_within_radius()
-- Check for players within a given range at a certain position
-- @param pos Vector: Position to search from
-- @param pos Integer: Radius to search
-- @return players Table: Players within range
----------------------------------------------------
local function get_players_within_radius(pos, radius)
    local players = {}
    for ___, ply in pairs(ents.FindInSphere(pos, radius)) do 
        if (ply:IsPlayer()) then table.insert(players, ply) end
    end
    return players
end

----------------------------------------------------
-- get_players_within_box()
-- Check for players within a box at a certain position
-- @param pos01 Vector: First position
-- @param pos02 Vector: second position
-- @return players Table: Players within range
----------------------------------------------------
local function get_players_within_box(pos01, pos02)
    local players = {}
    for ___, ply in pairs(ents.FindInBox(pos01, pos02)) do 
        if (ply:IsPlayer()) then table.insert(players, ply) end
    end
    return players
end

----------------------------------------------------
-- add_player_ignore()
-- Adds player to a list in which AI will ignore
-- @param ply Player: Player to be added
----------------------------------------------------
local function add_player_ignore(ply)
    local playerID = ply:AccountID()
    local exists = table.KeyFromValue(options.PlayersToIgnore, playerID)
    if (exists) then return end
    table.insert(options.PlayersToIgnore, ply:AccountID())
end

----------------------------------------------------
-- remove_player_ignore()
-- Removes a player from list in which AI will ignore
-- @param ply Player: Player to be removed
----------------------------------------------------
local function remove_player_ignore(ply)
    table.RemoveByValue(options.PlayersToIgnore, ply:AccountID())
end

----------------------------------------------------    
-- get_creationid_within_range()
-- Displays creationID for a trap close to a player
----------------------------------------------------
local function get_creationid_within_range()
    for _, ent in pairs(ents.FindByClass("info_manipulate")) do  -- Gets all traps
        for ___, ply in pairs(get_players_within_radius(ent:GetPos(), 96)) do -- Checks if any players within given radius of the trap
            print("CreationID: " .. ent:MapCreationID())
        end
    end
end

----------------------------------------------------
-- debug_show_stats()
-- Shows stats of AI
----------------------------------------------------
local function debug_show_stats()
    zmBot:Say("Use Trap Chance: " .. options.UseTrapChance)
    zmBot:Say("Spawn Zombie Chance: " .. options.SpawnZombieChance)
    zmBot:Say("Trap Usage Radius: " .. options.TrapUsageRadius)
end

----------------------------------------------------
-- check_zombie_class()
-- Check if given ent is a zombie
----------------------------------------------------
local function check_zombie_class(ent)
    for _, zb in pairs(gamemode.Call("GetZombieTable", false)) do
        if (ent:GetClass() == zb.Class) then return true end
    end
    return false
end

----------------------------------------------------
-- get_zombie_too_far()
-- Checks for zombies too far away from players and deletes them
-- @return zombies Table: zombies too far away
----------------------------------------------------
local function get_zombie_too_far()
    local zombies = {}
    local index = 0
    for _, ply in pairs(team.GetPlayers(HUMANTEAM)) do -- Loop through survivors
        local ignorePlayer = get_player_in_ignore_table(ply)
        if (!ignorePlayer) then
            for __, zb in pairs(ents.FindByClass("npc_*")) do -- Loop through all zombies
                if (check_zombie_class(zb)) then
                    if (ply:GetPos():Distance(zb:GetPos()) >= options.DeleteRadius) then -- Get distance between zombie and survivor
                        zombies[index] = zb -- Adds zombie to list if not near player
                    else zombies[index] = nil end -- Removes zombie from the list if near player
                    index = index + 1 -- Increment index
                end
            end
            index = 0
        end
    end
    return zombies
end

----------------------------------------------------
-- kill_zombie()
-- Kills a given zombie
-- @param zb Entity: Zombie to be deleted
----------------------------------------------------
local function kill_zombie(zb)
    if (options.Debug) then zmBot:Say("Zombie Has been killed and removed, to far away from any players.") end
    local dmginfo = DamageInfo()
    dmginfo:SetDamage(zb:Health() * DAMAGEZOMBIEMULTIPLIER)
    zb:TakeDamageInfo(dmginfo) 
    zb:Remove()
end

----------------------------------------------------
-- kill_all_zombies()
-- Kills all zombies within a table
-- @param tb Table: table containting zombies
----------------------------------------------------
local function kill_all_zombies(tb)
    for _, zb in pairs(tb) do
        if (zb) then kill_zombie(zb) end
    end
end

----------------------------------------------------
-- move_zombies_to_players()
-- Moves random zombie to random player
----------------------------------------------------
local function move_zombie_to_player()
    local player = table.Random(team.GetPlayers(HUMANTEAM)) -- Get Random survivor
    local ignorePlayer = get_player_in_ignore_table(player)
    if (ignorePlayer) then return end
    local zb = table.Random(ents.FindByClass("npc_*")) -- Get random zombie
    if ((IsValid(player)) && (IsValid(zb)) && (check_zombie_class(zb))) then zb:ForceGo(player:GetPos()) end
    options.LastZombieCommanded = zb
end

----------------------------------------------------    
-- set_trap_settings()
-- Set custom stats for a certain trap
-- @param arg1 Integer: CreationID of the entity
-- @param arg2 Float: Trap usage chance
-- @param arg3 Integer: Trap usage radius
-- @param arg4 Table: Vector(s) position for trap or position of trigger box
-- @param arg5 Boolean: If a player needs to be in line of sight
-- @return Boolean: If CreationID exists and settings were applied
----------------------------------------------------
local function set_trap_settings(...) 
    local arguments = {...} -- Get passed in arguments as table
    for key, trap in pairs(options.Traps) do 
        if (trap.Trap == arguments[1] ) then
            -- HACK
            table.remove( options.Traps, key ) -- Has to be removed or it duplicates, cannot just assign to that key in the table.
                                               -- Does not seem to point at orginal, rather a new slot.
            table.insert( options.Traps, { -- Add it again
                Trap = arguments[1] or trap.Trap,
                UseTrapChance = arguments[2] or trap.UseTrapChance,
                TrapUsageRadius = arguments[3] or trap.TrapUsageRadius,
                Position = arguments[4] or trap.Position,
                HasToBeVisible = arguments[5] -- Boolean 
            })
            return true -- Setting was a success
        end
    end
    print("Error setting creationID: " .. arguments[1] .. " does not exists...")
    return false -- Setting as a failure
end

----------------------------------------------------    
-- set_explosion_settings()
-- Set custom stats for a certain trap
-- @param arg1 Float: Trap usage chance
-- @param arg2 Integer: Trap usage radius
-- @param arg3 Table: Vector(s) position for trap or position of trigger box
-- @param arg4 Boolean: If a player needs to be in line of sight
-- @return Boolean: If settings were applied
----------------------------------------------------
local function set_explosion_settings(...) 
    local arguments = {...} -- Get passed in arguments as table
    table.insert( options.Explosions, {
        UseExplosionChance = arguments[1],
        ExplosionUsageRadius = arguments[2],
        Position = arguments[3],
        HasToBeVisible = arguments[4]
    })
end

----------------------------------------------------
-- create_explosion()
-- Causes a explosion forces props away
-- @param location Vector: Location where explosion will appear
----------------------------------------------------
local function create_explosion(location)
    local ent = ents.Create("env_delayed_physexplosion")
    if IsValid(ent) then
        ent:Spawn()
        ent:SetPos(location)
        ent:Activate()
        ent:DelayedExplode(ZM_PHYSEXP_DELAY)
    end
end

----------------------------------------------------
-- activate_trap()
-- Triggers a trap
-- @param ent Entity: The trap to be activated
----------------------------------------------------
local function activate_trap(ent)
    ent:Trigger(zmBot)
    zmBot:TakeZMPoints(ent:GetCost())
    options.LastTrapUsed = ent
    if (options.Debug) then zmBot:Say("Trap activated.") end -- Debugging
end

----------------------------------------------------
-- get_trap_settings()
-- Gets the trap settings for the given trap
-- @param arg1 Entity: The trap to be checked
-- @return trapSettings Table: Table containing the settings
----------------------------------------------------
local function get_trap_settings(ent)
    for __, trapSettings in pairs(options.Traps) do -- Checks both keys to find the trap in the traps table that's being checked
        if (ent:MapCreationID() == trapSettings.Trap) then -- If it's the same trap being checked as the one in the traps table
            return trapSettings -- Returns the settings
        end
    end
end

----------------------------------------------------
-- check_for_traps()
-- Checks for traps within radius of players
-- @return ent Entity: Trap which has been found
----------------------------------------------------
local function check_for_traps()
    for _, ent in RandomPairs(ents.FindByClass("info_manipulate")) do  -- Gets all traps
        if (IsValid(ent)) then -- Check if trap is vaild and not used
            local sphereSearch, positions, searchType = true, nil, nil
            local settings = get_trap_settings(ent) -- Get trap settings
            if (table.Count(settings.Position) > 1) then -- If it's a sphere or box
                sphereSearch = false 
                positions = settings.Position -- Gets vectors as a table
            else 
                ent:SetPos(settings.Position[1]) -- Gets the one vector
            end
            if (sphereSearch) then searchType = get_players_within_radius(ent:GetPos(), settings.TrapUsageRadius) else searchType = get_players_within_box(positions[1], positions[2]) end
            for ___, ply in RandomPairs(searchType) do -- Checks if any players within given radius of the trap
                if (ent:GetActive()) then -- Check if entity is player 
                    local ignorePlayer = get_player_in_ignore_table(ply)
                    if ((!ply.IsZMBot) && (!ignorePlayer)) then 
                        local canUse = true
                        if (settings.HasToBeVisible) then -- If it matters if the trap is visible
                            if (!ent:Visible(ply)) then canUse = false end -- is not visible to the trap
                        end
                        if (options.Debug) then zmBot:Say(ply:Nick() .. " Is within a trap at of radius: " .. settings.TrapUsageRadius .. " of chance: " .. settings.UseTrapChance .. " at going off.") end
                        if (canUse) then return ent end
                    end
                end 
            end
        end
    end
    return nil -- If no traps were found
end

----------------------------------------------------
-- set_up_all_traps()
-- Sets up all the traps from the get go with stats
----------------------------------------------------
local function set_up_all_traps()
    table.Empty(options.Traps)
    for _, ent in pairs(ents.FindByClass("info_manipulate")) do  -- Gets all traps
        table.insert( options.Traps, {
            Trap = ent:MapCreationID(),
            UseTrapChance = get_chance_trap(),
            TrapUsageRadius = get_trap_usage_radius(),
            Position = {ent:GetPos()}, -- Incase we need to fake it
            HasToBeVisible = true
        })
    end
    if (options.Debug) then PrintTable(options.Traps) end
end

----------------------------------------------------    
-- set_all_map_settings()
-- Gets all custom settings for maps if set and sets it
----------------------------------------------------
local function set_all_map_settings()
    local map = game.GetMap() .. ".lua"
    local files, _ = file.Find(MAPSETTINGSPATH .. "*", "LUA") 
    for i, filename in ipairs(files) do
        if (map == filename) then
            mapSettings, mapTrapSettings, mapExplosionSettings = include(MAPSETTINGSPATH .. map) -- Gets settings from the map file
            if (mapSettings) then -- Sets up custom settings if any
                for _, setting in ipairs(mapSettings) do
                    local index = setting[1]
                    local value = setting[2]
                    options[index] = value
                end
            end
            set_up_all_traps() -- Sets up the traps in the map given the settings
            if (mapTrapSettings) then -- Sets up custom traps if any
                for _, trap in ipairs(mapTrapSettings) do
                    set_trap_settings(trap.creationID, trap.usageChance, trap.usageRadius, trap.positions, trap.lineOfSight)
                end
            end
            if (mapExplosionSettings) then -- Sets up custom explosions if any
                for _, exp in ipairs(mapExplosionSettings) do
                    set_explosion_settings(exp.useExplosionChance, exp.explosionUsageRadius, exp.position, exp.lineOfSight)
                end
            end
            return true
        end
    end
    return false
end

----------------------------------------------------
-- set_zm_settings()
-- Sets up the bots stats
----------------------------------------------------
local function set_zm_settings()
    if (options.SetUp) then -- The setup for the bot 
        -- This section is done once during the round start
        local hasCustom = set_all_map_settings() -- Sets custom settings
        if (!hasCustom) then set_up_all_traps() end -- Sets up the traps in the map if no custom settings
        zmBot:SetZMPoints(10000)
        options.UseExplosionChance = get_chance_explosion()
        options.Debug = false
        options.SetUp = false
    else -- Dynamic stats, that can change during the game
        options.MaxZombies = get_max_zombies()
    end
end

----------------------------------------------------
-- pick_zombie()
-- Picks a random zombie
-- @return zb String: The zombie to use as class
----------------------------------------------------
local function pick_zombie()
    local tb = gamemode.Call("GetZombieTable", false)
    local zb = "npc_zombie"
    for _, zm in pairs(tb) do -- Finds zombie
        if (get_zombie_chance() == 0) then zb = zm.Class end -- Checks if this is the zombie to use
    end
    return zb
end

----------------------------------------------------
-- spawn_zombie()
-- Spawns a zombie
-- @param ent Entity: Spawn to spawn zombie at
----------------------------------------------------
local function spawn_zombie(ent)
    if (options.SpawnZombieChance < math.Rand(0, 1)) then return nil end
    local zb = pick_zombie()
    -- Attempt to spawn another zombie if failed
    --[[local allowed = true
    local attempts = 0
    while (allowed) do
        if (attempts > 5) then 
            if (options.Debug) then zmBot:Say("Attempt to spawn zombie failed... Query: " .. #ent.query) end
            return nil 
        end
        local data = gamemode.Call("GetZombieData", zb)
        if ((data) && (#ent.query < 18)) then
            local zombieFlags = ent:GetZombieFlags() or 0
            allowed = gamemode.Call("CanSpawnZombie", data.Flag or 0, zombieFlags)
            if (!allowed) then zb = pick_zombie() end
            attempts = attempts + 1
        end
    end]]
    ent:AddQuery(zmBot, zb, 1)
    options.LastSpawned = ent
    if (options.Debug) then zmBot:Say("Attempted to spawn: " .. zb) end
end

----------------------------------------------------
-- check_for_spawner()
-- Finds zombies spawners and spawns a zombie
-- @return entToUse Entity: cloeset spawner
----------------------------------------------------
local function check_for_closest_spawner()
    if (get_zombie_population() > options.MaxZombies) then return nil end
    local zombieSpawns = ents.FindByClass("info_zombiespawn")
    if (#zombieSpawns == 0) then return nil end -- Checks if there's any spawns
    local player = table.Random(team.GetPlayers(HUMANTEAM)) -- Picks a random player from humanteam
    local ignorePlayer = get_player_in_ignore_table(player)
    if (ignorePlayer) then return end
    local entToUse = nil -- Default to nil
    for __, spawn in RandomPairs(zombieSpawns) do -- Find cloest spawn point
        if ((IsValid(spawn)) && (spawn:GetActive())) then
            if (entToUse) then -- If it's not the first zombie spawner
                local newDis = spawn:GetPos():Distance(player:GetPos()) -- Get Distance of new spawner
                local oldDis = entToUse:GetPos():Distance(player:GetPos()) -- Get Distance of stored spawner
                if (oldDis > newDis) then entToUse = spawn end -- Check which one is closer
            else entToUse = spawn end -- Set First Spawner in the table to check
        end
    end
    if (!entToUse) then return nil end
    local dis = entToUse:GetPos():Distance(player:GetPos()) -- Get distance of closest spawner to player
    if (dis > options.SpawnRadius) then return nil end -- Checks if spawn is within distance
    return entToUse -- Return the closest spawn
end

----------------------------------------------------
-- using_spawner()
-- Controls the bot using a spawner
----------------------------------------------------
local function using_spawner()
    if (CurTime() < spawnDelay) then return end
    local cloestSpawnPoint = check_for_closest_spawner() -- Check cloest spawn to players
    if (cloestSpawnPoint) then spawn_zombie(cloestSpawnPoint) end -- Spawn zombie
    spawnDelay = CurTime() + options.ZombieSpawnDelay
end

----------------------------------------------------
-- using_explosion_custom_set()
-- Controls the bot using explosion at custom set locations
----------------------------------------------------
local function using_explosion_custom_set()
    for _, exp in RandomPairs(options.Explosions) do
        if (exp.UseExplosionChance > math.Rand(0, 1)) then
            for __, ply in RandomPairs(get_players_within_radius(exp.Position, exp.ExplosionUsageRadius)) do
                local canUse = true
                if (exp.HasToBeVisible) then
                    if (!exp:Visible(ply)) then canUse = false end
                end
                if (canUse) then 
                    if (options.Debug) then zmBot:Say("Custom Explosion used on: " .. ply:Nick()) end
                    create_explosion(ply:GetPos()) 
                    explosionDelay = CurTime() + options.ExplosionDelay
                end
            end
        end
    end
end

----------------------------------------------------
-- using_explosion_random()
-- Controls the bot using explosion on a players
----------------------------------------------------
local function using_explosion_random()
    if (options.UseExplosionChance < math.Rand(0, 1)) then return end
    for ___, ply in RandomPairs(team.GetPlayers(HUMANTEAM)) do
        local ignorePlayer = get_player_in_ignore_table(ply)
        if (!ignorePlayer) then
            local amount = #ents.FindInSphere(ply:GetPos(), options.ExplosionSearchRange) -- Get all amount of ents within range of player
            if (amount > options.ExplosionUseAmount) then
                create_explosion(ply:GetPos()) -- Create explosion at player
                options.UseExplosionChance = get_chance_explosion()
                if (options.Debug) then zmBot:Say("Explosion used on: " .. ply:Nick()) end
                explosionDelay = CurTime() + options.ExplosionDelay
            end
        end
    end
end

----------------------------------------------------
-- using_explosion()
-- Controls the bot using the explosion
----------------------------------------------------
local function using_explosion()
    if (CurTime() < explosionDelay) then return end
    using_explosion_custom_set()
    using_explosion_random()
end

----------------------------------------------------
-- can_use_trap()
-- Checks for traps within radius of players
-- @param ent Entity: The trap to be checked
-- @return Boolean: If trap can be used
----------------------------------------------------
local function can_use_trap(ent)
    local settings = get_trap_settings(ent)
    if (settings.UseTrapChance < math.Rand(0, 1)) then return false else return true end -- Check chances of using the trap
end

----------------------------------------------------
-- using_trap()
-- Controls the bot using the traps
----------------------------------------------------
local function using_trap()
    local trap = check_for_traps() -- Check if player is near trap
    if (!trap) then return end -- Checks if a trap was found
    local canUse = can_use_trap(trap) -- Checks if the trap can be used
    if (canUse) then activate_trap(trap) end
end

----------------------------------------------------
-- deleting_zombies()
-- Controls the bot deleting zombies
----------------------------------------------------
local function deleting_zombies()
    if (CurTime() < killZombieDelay) then return end
    local zombiesToDelete = get_zombie_too_far() -- Gets zombies too far away from players
    if (zombiesToDelete) then kill_all_zombies(zombiesToDelete) end -- Kills given zombies
    killZombieDelay = CurTime() + options.KillZombieDelay
end

----------------------------------------------------
-- command_zombie()
-- Controls the bot commanding a zombie
----------------------------------------------------
local function command_zombie()
    if (CurTime() < commandDelay) then return end
    move_zombie_to_player() -- Move random zombie towards random player if non in view of that zombie
    commandDelay = CurTime() + options.CommandDelay
end

----------------------------------------------------
-- incress_spawn_range()
-- Controls the bot spawning and deletion range
-- Currently not used
----------------------------------------------------
local function incress_spawn_range()
    if (CurTime() < spawnRangeDelay) then return end
    local zombiePopu = get_zombie_population()
    if (zombiePopu == 0) then 
        local range = options.SpawnRadius + options.IncressSpawnRange
        options.SpawnRadius = range
        options.DeleteRadius = range
        if (options.Debug) then zmBot:Say("No zombies spawned... Incressing range to: " .. range) end
    end
    spawnRangeDelay = CurTime() + options.SpawnRangeDelay
end

----------------------------------------------------
-- zm_brain()
-- Main Entry point of bot
----------------------------------------------------
local function zm_brain()
    if (zmBot:Team() == ZOMBIEMASTERTEAM) then -- Checks if bot is ZM
        -- Code that should run while bot is playing goes here
        -- Functions that will be effected by bot speed go below if realtime go above
        if (CurTime() < speedDelay) then return end
        set_zm_settings() -- Set all the settings
        using_spawner() -- Function which includes functionality for using a spawner
        using_trap() -- Function which includes functionality for traps
        using_explosion() -- Function which includes functionality explosions
        deleting_zombies() -- Function which includes functionality for deleting zombies
        command_zombie() -- Function which includes functionality commanding a zombie
        --create_explosion(team.GetPlayers(HUMANTEAM)[1]:GetPos())
        speedDelay = CurTime() + options.BotSpeed -- Bot delay
    else -- Bot is not ZM or round is over, etc..
        if (zmBot:Team() == HUMANTEAM) then if (zmBot:Alive()) then zmBot:Kill() end end -- Checks if bot is a survivor, if so kills himself
        options.SetUp = true
    end
end

----------------------------------------------------
-- create_zm_bot()
-- Spawns the AI bot
----------------------------------------------------
local function create_zm_bot()
    if ((!game.SinglePlayer()) && (#player.GetAll() < game.MaxPlayers()) && (player.GetCount() >= 1) && #player.GetBots() == 0) then
        local bot = player.CreateNextBot(names[math.random(#names)]) -- Create a bot given the name list
        bot.IsZMBot = true -- Set bot as ZM bot
        zmBot = bot -- Assign bot as global for usage
    else print( "Cannot create bot. Do you have free slots or are you in Single Player?" ) end -- This prints to console if the bot cannot spawn
end

----------------------------------------------------    
-- Think
-- Think hook for controlling the bot
----------------------------------------------------
hook.Add( "Think", "Control_Bot", function()
    --get_creationid_within_range()
    if ((options.Playing) && (zmBot) && (#team.GetPlayers(HUMANTEAM) > 0)) then zm_brain() end -- Checks if the bot was created, runs the bot if so
end )

----------------------------------------------------   
-- InitPostClient
-- InitPostClient hook for detecting player join
----------------------------------------------------
hook.Add( "InitPostClient", "Bot_Creation", function()
    if (cvars.Bool("zm_ai_enabled") and options.Playing) then
        if (get_amount_zm_bots() == 0) then create_zm_bot() end -- Check if there's already a bot on the server and waits for players to join first
    end
end )

----------------------------------------------------   
-- GetZombieMasterVolunteer
-- GetZombieMasterVolunteer hook for making it where only the bot is choosen
----------------------------------------------------
hook.Add( "GetZombieMasterVolunteer", "Bot_Selection", function()
    if ((options.Playing) && (zmBot)) then
        return zmBot -- Force the zombie master selection to the bot
    end
end )

----------------------------------------------------    
-- CMDs
-- Console Commands for bot
----------------------------------------------------

-- Bot Global Speed Delay
concommand.Add( "zm_ai_speed", function(ply, cmd, args)
    if (ply:IsAdmin()) then options.BotSpeed =  tonumber(args[1]) end
end )

-- Bot Command Delay (Commanding zombies)
concommand.Add( "zm_ai_command_delay", function(ply, cmd, args)
    if (ply:IsAdmin()) then options.CommandDelay = tonumber(args[1]) end
end )

-- Bot Zombie Spawn Delay
concommand.Add( "zm_ai_zombie_spawn_delay", function(ply, cmd, args)
    if (ply:IsAdmin()) then options.ZombieSpawnDelay = tonumber(args[1]) end
end )

-- Bot Max Zombies Per Player
concommand.Add( "zm_ai_max_zombies_per_player", function(ply, cmd, args)
    if (ply:IsAdmin()) then options.ZombiesPerPlayer = tonumber(args[1]) end
end )

-- Bot Max Zombie Spawn Distance
concommand.Add( "zm_ai_max_zombie_spawn_dis", function(ply, cmd, args)
    if (ply:IsAdmin()) then options.SpawnRadius = tonumber(args[1]) end
end )

-- Bot Min Zombie Spawn Distance
concommand.Add( "zm_ai_min_zombie_delete_dis", function(ply, cmd, args)
    if (ply:IsAdmin()) then options.DeleteRadius = tonumber(args[1]) end
end )

-- Bot Min Distance To Activate Trap
concommand.Add( "zm_ai_min_distance_to_act_trap", function(ply, cmd, args)
    if (ply:IsAdmin()) then 
        options.MinTrapRange = tonumber(args[1])
        set_up_all_traps() -- Update traps with new number
    end
end )

-- Bot Max Distance To Activate Trap
concommand.Add( "zm_ai_max_distance_to_act_trap", function(ply, cmd, args)
    if (ply:IsAdmin()) then 
        options.MaxTrapRange = tonumber(args[1])
        set_up_all_traps() -- Update traps with new number
    end
end )

-- Toggle Debugger
concommand.Add( "zm_ai_debug", function(ply, cmd, args)
    if (ply:IsAdmin()) then 
        if (!options.Debug) then 
            options.Debug = true 
            print("Debug Enabled")
        else 
            options.Debug = false 
            print("Debug Disabled")
        end
    end
end )

-- Forces the round to begin
concommand.Add( "zm_ai_force_start_round", function(ply, cmd, args)
    if (ply:IsAdmin()) then 
        gamemode.Call("EndRound")
        zmBot:Say("Round forcefully started")
    end
end )

-- Adds player to the ignore list
concommand.Add( "zm_ai_ignore_player", function(ply, cmd, args)
    if (ply:IsAdmin()) then 
        add_player_ignore(ply)
    end
end )

-- Removes player from the ignore list
concommand.Add( "zm_ai_remove_ignore_player", function(ply, cmd, args)
    if (ply:IsAdmin()) then 
        remove_player_ignore(ply)
    end
end )

-- Move Player To Last spawned Zombie Spawn
concommand.Add( "zm_ai_move_ply_to_last_spawn", function(ply, cmd, args)
    if ((options.LastSpawned) && (ply:IsAdmin())) then ply:SetPos(options.LastSpawned:GetPos()) end
end )

-- Enable the AI
CreateConVar("zm_ai_enabled", "0", FCVAR_NOTIFY + FCVAR_ARCHIVE, "Enables the Zombie Master AI.")
cvars.AddChangeCallback("zm_ai_enabled", function(convar_name, value_old, value_new)
    if(player.GetCount() == 0) then return end
    
    if (!zmBot) then -- In case an error and bot was never created in the first place
        create_zm_bot()
    else
        if (!options.Playing) then 
            if (get_amount_zm_bots() == 0) then create_zm_bot() end -- Rejoins the bot
            options.Playing = true
            print("AI Enabled")
        else 
            zmBot:Kick("AI Terminated") -- Kicks the bot
            options.Playing = false 
            print("AI Disabled")
        end
    end
end)