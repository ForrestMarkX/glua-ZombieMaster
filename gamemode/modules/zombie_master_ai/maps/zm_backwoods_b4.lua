-- Table layout
-------------------------------------
-- trapName, what's the trap
-- creationID, map creationID of the trap
-- usageChance, chance the trap is used, nil means bot choses
-- usageRadius, the radius of the trap, nil means bot choses
-- positions, position for the trap (One vector), trigger box (Two vectors), nil means default position
-- lineOfSight, if player needs to be in view of the trap
-------------------------------------

local mapTrapSettings = {
    -- Trigger is in not the best spot for these trap doors
    {
        trapName    = "First trap door",
        creationID  = 2015,
        usageChance = nil,
        usageRadius = nil,
        positions   = {Vector(-2290, 2322, -231)},
        lineOfSight = true
    },
    {
        trapName    = "Second trap door",
        creationID  = 2016,
        usageChance = nil,
        usageRadius = nil,
        positions   = {Vector(-3057, 2326, -227)},
        lineOfSight = true
    },
    {
        trapName    = "Third trap door",
        creationID  = 2350,
        usageChance = nil,
        usageRadius = nil,
        positions   = {Vector(-5731, 7199, -229)},
        lineOfSight = true
    },
    {
        trapName    = "Fourth trap door",
        creationID  = 2367,
        usageChance = nil,
        usageRadius = nil,
        positions   = {Vector(-7438, 7187, -229)},
        lineOfSight = true
    },
    {
        trapName    = "Tall Building",
        creationID  = 1260,
        usageChance = nil,
        usageRadius = nil,
        positions   = {Vector(-4352, 7494, -23)},
        lineOfSight = false
    }
}

return nil, mapTrapSettings, nil