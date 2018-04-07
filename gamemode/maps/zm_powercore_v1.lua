hook.Add("EntityKeyValue", "changing", function(ent, key, value)
    local name = ent:GetName()
    if ent:GetClass() == "item_item_crate" then
        if string.lower(key) == "itemclass" and value == "item_ammo_3" then
            return "item_ammo_357"
        end
    end
end)