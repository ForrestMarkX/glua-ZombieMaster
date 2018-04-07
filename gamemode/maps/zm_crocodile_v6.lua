hook.Add("EntityKeyValue", "changing", function(ent, key, value)
    local name = ent:GetName()
    if ent:GetClass() == "func_door" and name ~= "JumpDoorEntry" then
        if key == "spawnflags" then
            return "32"
        end
        
        if name ~= "Airlock2_door1" and name ~= "Airlock3_door1" then
            if key == "spawnpos" then
                return "0"
            end
        end
    end
end)