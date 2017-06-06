-- replacerclass is the classname of the weapon you'll be adding
-- replacedclass is the classname of the weapon you'll be replacing
-- chance, the chance this weapon will be replaced when spawned
-- GAMEMODE:AddCustomWeapon(string replacerclass, string replacedclass, float chance)

-- ammotype the name of the ammo you'll be replacing (buckshot, smg1, ar2, etc)
-- replacerclass is the classname of the ammo you'll be adding (check item_ammo_revolver)
-- model, the model the ammo will use
-- replacertype, the ammotype this will be using (buckshot, smg1, ar2, etc)
-- chance, the chance this ammo will be replaced when spawned
-- maxcount, the max amount of ammo the player can carry
-- pickupamount, the amount given when picked up
-- damagetype, the damagetype of the ammo use DMG_ enums
-- tracerstyle, the tracer style of the ammo use TRACER_ enum
-- GAMEMODE:AddCustomAmmo(string ammotype, string replacerclass, string model, string replacertype, float chance, int maxcount, int pickupamount, int damagetype, int tracerstyle)

hook.Add("SetupCustomItems", "SetupCustomItems.ExampleHook", function()
	GAMEMODE:AddCustomWeapon("weapon_zm_example", "weapon_zm_shotgun", 0.75)
	GAMEMODE:AddCustomAmmo("smg1", "item_ammo_smg1", "models/items/boxmrounds.mdl", "custom_smg", 0.35, 70, 12, DMG_BULLET, TRACER_LINE)
end)