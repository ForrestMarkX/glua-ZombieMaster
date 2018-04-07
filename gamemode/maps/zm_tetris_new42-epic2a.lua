hook.Add("OnEntityCreated", "removing", function(ent)
    if ent:GetName() == "zm_trap_cannisters" then
        ent:Remove()
    end
end)