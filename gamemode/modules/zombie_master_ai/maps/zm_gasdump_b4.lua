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
    {
        trapName    = "Tornado",
        creationID  = 2452,
        usageChance = 0.02,
        usageRadius = 2096,
        positions   = nil,
        lineOfSight = false
    }
}

return nil, mapTrapSettings, nil