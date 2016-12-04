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

hook.Add("OnEntityCreated", "changing2", function(ent)
	timer.Simple(1, function()
		if IsValid(ent) and ent:GetModel() == "models/cat/cat_woodencrate_grey.mdl" then
			ent:SetModel("models\props_junk\wood_crate001a.mdl")
		end
	end)
end)