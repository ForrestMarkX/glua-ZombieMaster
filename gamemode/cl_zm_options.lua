CreateClientConVar("zm_preference", "0", true, true, "What is your Zombie Master preference? (0 = Survivor, 1 = Zombie Master)")
CreateClientConVar("zm_nopreferredmenu", "0", true, false, "Toggles the preference menu to appear or not.")

GAMEMODE:MakePreferredMenu()

local function ZM_Open_Preferred Menu(ply)
	if not IsValid(ply) then return end
	GAMEMODE:MakePreferredMenu()
end
concommand.Add("zm_open_preferred menu", ZM_Open_Preferred Menu, nil, "Opens the preference menu.")

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