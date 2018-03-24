-- Table layout
-------------------------------------
-- trapName, what's the trap
-- creationID, map creationID of the trap
-- usageChance, chance the trap is used, nil means bot choses
-- usageRadius, the radius of the trap, nil means bot choses
-- positions, position for the trap (One vector), trigger box (Two vectors), nil means default position
-- lineOfSight, if player needs to be in view of the trap
-------------------------------------

local smallStructorVector = Vector(-734, -1215, -911)
local pathWayVector = Vector(731, -2085, -834)
local laserVector = Vector(22, -189, -663)

local mapTrapSettings = {
    {
        trapName    = "Red block that falls with hole in center",
        creationID  = 1255,
        usageChance = nil,
        usageRadius = nil,
        positions   = {Vector(-1281, -1952, -948)},
        lineOfSight = true
    },
    {
        trapName    = "Red wall",
        creationID  = 1275,
        usageChance = nil,
        usageRadius = nil,
        positions   = {Vector(605, -1462, -175)},
        lineOfSight = true
    },
    {
        trapName    = "Small Structor",
        creationID  = 2437,
        usageChance = nil,
        usageRadius = nil,
        positions   = {smallStructorVector},
        lineOfSight = true
    },
    {
        trapName    = "Small Structor",
        creationID  = 2220,
        usageChance = nil,
        usageRadius = nil,
        positions   = {smallStructorVector},
        lineOfSight = true
    },
    {
        trapName    = "Small Structor",
        creationID  = 2215,
        usageChance = nil,
        usageRadius = nil,
        positions   = {smallStructorVector},
        lineOfSight = true
    },
    {
        trapName    = "Pathway01",
        creationID  = 1264,
        usageChance = nil,
        usageRadius = nil,
        positions   = {pathWayVector},
        lineOfSight = true
    },
    {
        trapName    = "Pathway02",
        creationID  = 1265,
        usageChance = nil,
        usageRadius = nil,
        positions   = {pathWayVector},
        lineOfSight = true
    },
    {
        trapName    = "Pathway03",
        creationID  = 1266,
        usageChance = nil,
        usageRadius = nil,
        positions   = {pathWayVector},
        lineOfSight = true
    },
    {
        trapName    = "Laser01",
        creationID  = 2379,
        usageChance = nil,
        usageRadius = nil,
        positions   = {laserVector},
        lineOfSight = true
    },
    {
        trapName    = "Laser02",
        creationID  = 2393,
        usageChance = nil,
        usageRadius = nil,
        positions   = {laserVector},
        lineOfSight = true
    },
    {
        trapName    = "Laser03",
        creationID  = 1275,
        usageChance = nil,
        usageRadius = nil,
        positions   = {laserVector},
        lineOfSight = true
    }
}

return nil, mapTrapSettings, nil