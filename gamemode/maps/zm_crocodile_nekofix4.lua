hook.Add("EntityKeyValue", "changing", function(ent, key, value)
	if ent:GetClass() == "func_door" then
		if key == "spawnflags" then
			return "32"
		end
		
		local name = ent:GetName()
		if name ~= "Airlock2_door1" and name ~= "Airlock3_door1" then
			if key == "spawnpos" then
				return "0"
			end
		end
	end
end)