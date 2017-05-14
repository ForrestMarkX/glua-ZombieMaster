CreateClientConVar("zm_preference", "0", true, true, "What is your Zombie Master preference? (0 = Survivor, 1 = Zombie Master)")
CreateClientConVar("zm_nopreferredmenu", "0", true, true, "Toggles the preference menu to appear or not.")
CreateClientConVar("zm_scrollwheelsensativity", "20", true, false, "How sensitive the mouse scroll is when moving with ZM.")

CreateClientConVar("zm_dropweaponkey", "12", true, false, "Key enum to use for dropping your currently held weapon.")
CreateClientConVar("zm_dropammokey", "32", true, false, "Key enum to use for dropping your currently held weapons ammo.")

local function ZM_Open_Preferred_Menu(ply)
	if not IsValid(ply) then return end
	GAMEMODE:MakePreferredMenu()
end
concommand.Add("zm_open_preferred_menu", ZM_Open_Preferred_Menu, nil, "Opens the preference menu.")

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

local LightingModeChanged = false
local function StartOfLightingMod()
	render.SetLightingMode( 2 )
	LightingModeChanged = true
end
local function EndOfLightingMod()
	if LightingModeChanged then
		render.SetLightingMode( 0 )
		LightingModeChanged = false
	end
end
local function ZM_Power_NightVision(ply)
	if ply:IsZM() then
		GAMEMODE.nightVision = not GAMEMODE.nightVision
		
		if GAMEMODE.nightVision then
			hook.Add("PreRender", "PreRender.Fullbright", StartOfLightingMod)
			hook.Add("PostRender", "PostRender.Fullbright", EndOfLightingMod)
			hook.Add("PreDrawHUD", "PreDrawHUD.Fullbright", EndOfLightingMod)
		else
			hook.Remove("PreRender", "PreRender.Fullbright")
			hook.Remove("PostRender", "PostRender.Fullbright")
			hook.Remove("PreDrawHUD", "PreDrawHUD.Fullbright")
		end
		
		ply:PrintTranslatedMessage(HUD_PRINTTALK, "toggled_nightvision")
		
		if not GAMEMODE.nightVision then
			GAMEMODE.nightVisionCur = 0.5
		end
	end
end
concommand.Add("zm_power_nightvision", ZM_Power_NightVision, nil, "Enables night vision")

local function ZM_Power_KillZombies()
	net.Start("zm_net_power_killzombies")
	net.SendToServer()
end
concommand.Add("zm_power_killzombies", ZM_Power_KillZombies, nil, "Kills all selected zombies")

local function ZM_Drop_Ammo()
	net.Start("zm_net_dropammo")
	net.SendToServer()
end
concommand.Add("zm_dropammo", ZM_Drop_Ammo, nil, "Drops your current weapons ammo")

local function ZM_Drop_Weapon()
	net.Start("zm_net_dropweapon")
	net.SendToServer()
end
concommand.Add("zm_dropweapon", ZM_Drop_Weapon, nil, "Drops your current weapon")

local function ZM_Deselect()
	net.Start("zm_net_deselect")
	net.SendToServer()
end
concommand.Add("zm_deselect", ZM_Deselect, nil, "Deselects all NPCs")