CreateClientConVar("zm_preference", "0", true, true, "What is your Zombie Master preference? (0 = Survivor, 1 = Zombie Master)")
CreateClientConVar("zm_nopreferredmenu", "0", true, false, "Toggles the preference menu to appear or not.")

local function ZM_Power_PhysExplode(ply)
	if (not IsValid(ply)) or (IsValid(ply) and not ply:IsZM()) then
		return
	end
	
	ply:PrintTranslatedMessage(HUD_PRINTTALK, "enter_explosion_mode")
	
	GAMEMODE:SetPlacingShockwave(true)
end
concommand.Add("zm_power_physexplode", ZM_Power_PhysExplode, nil, "Creates a physics explosion at a chosen location")

local function ZM_Power_SpotCreate(ply)
	if (not IsValid(ply)) or (IsValid(ply) and not ply:IsZM()) then
		return
	end
	
	ply:PrintTranslatedMessage(HUD_PRINTTALK, "enter_hidden_mode")
	
	GAMEMODE:SetPlacingSpotZombie(true)
end
concommand.Add("zm_power_spotcreate", ZM_Power_SpotCreate, nil, "Creates a Shambler at target location, if it is unseen to players")

local function ZM_Power_NightVision(ply)
	if ply:IsZM() then
		GAMEMODE.nightVision = not GAMEMODE.nightVision
		
		ply:PrintTranslatedMessage(HUD_PRINTTALK, "toggled_nightvision")
		
		if not GAMEMODE.nightVision then
			GAMEMODE.nightVisionCur = 0.5
		end
	end
end
concommand.Add("zm_power_nightvision", ZM_Power_NightVision, nil, "Enables night vision")