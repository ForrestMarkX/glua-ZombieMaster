local meta = FindMetaTable("NPC")
if not meta then return end

function meta:Alive()
    return self:Health() > 0
end

function meta:Team()
    return TEAM_ZOMBIEMASTER
end