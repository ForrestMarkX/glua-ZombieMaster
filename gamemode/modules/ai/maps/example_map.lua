-- mapSettings Table layout
-------------------------------------
-- Table
    -- Option to edit
    -- New value for option
-------------------------------------

local mapSettings = {
    --Example
    {"MinTrapRange", 10000}, -- minTrapRange
    {"MaxTrapRange", 10001}, -- maxTrapRange
    {"MinTrapChance", 0.01}, -- minTrapChance
    {"MaxTrapChance", 0.4} -- maxTrapChance
}

-- mapTrapSettings Table layout
-------------------------------------
-- trapName, what's the trap
-- creationID, map creationID of the trap
-- usageChance, chance the trap is used, nil means bot choses
-- usageRadius, the radius of the trap, nil means bot choses
-- positions, position for the trap (One vector), trigger box (Two vectors), nil means default position
-- lineOfSight, if player needs to be in view of the trap
-------------------------------------

local mapTrapSettings = {
    -- Example
    {
        trapName    = "Exploding Barrel",
        creationID  = 2015,
        usageChance = nil,
        usageRadius = nil,
        positions   = {Vector(-2290, 2322, -231)},
        lineOfSight = true
    }
}

-- mapExplosionSettings Table layout
-------------------------------------
-- explosionName, what's the explosion
-- useExplosionChance, chance the explosion is used
-- explosionUsageRadius, the radius of the explosions checking range
-- position, position for the explosion
-- lineOfSight, if player needs to be in view of the explosion location
-------------------------------------

local mapExplosionSettings = {
    -- Example
    {
        explosionName = "Inside the small building at all the boxes",
        useExplosionChance = 0.3,
        explosionUsageRadius = 192,
        position = Vector(345, -3453, -245),
        lineOfSight = true
    }
}

return mapSettings, mapTrapSettings, mapExplosionSettings