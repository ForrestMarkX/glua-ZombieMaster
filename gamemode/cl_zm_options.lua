CreateClientConVar("zm_preference", "0", true, true, "What is your Zombie Master preference? (0 = Survivor, 1 = Zombie Master)")
CreateClientConVar("zm_nopreferredmenu", "0", true, true, "Toggles the preference menu to appear or not.")
CreateClientConVar("zm_scrollwheelsensativity", "20", true, false, "How sensitive the mouse scroll is when moving with ZM.")
CreateClientConVar("zm_drawitemhalos", "1", true, false, "Should Halos be drawn on weapons and ammo?")

CreateClientConVar("zm_dropweaponkey", "12", true, false, "Key enum to use for dropping your currently held weapon.")
CreateClientConVar("zm_dropammokey", "32", true, false, "Key enum to use for dropping your currently held weapons ammo.")
CreateClientConVar("zm_killzombieskey", "73", true, false, "Key enum to use for killing all selected zombies.")

CreateClientConVar("zm_itemhalo_r", "255", true, false, "Item halo red color min. 0 max. 255")
CreateClientConVar("zm_itemhalo_g", "0", true, false, "Item halo green color min. 0 max. 255")
CreateClientConVar("zm_itemhalo_b", "0", true, false, "Item halo blue color min. 0 max. 255")

CreateClientConVar("zm_vision_quality", "2", true, false, "The quality of the zombie master vision drawing.")
CreateClientConVar("zm_cl_spawntype", "1", true, false, "What type of spawn drawing should we use?")

CreateClientConVar("zm_shouldragdollsfade", "1", true, false, "Should ragdolls spawned by zombies fade out?")
CreateClientConVar("zm_cl_ragdoll_fadetime", "30", true, false, "How much time in seconds before the ragdolls fadeout.")

CreateClientConVar("zm_healthcircle_brightness", "0.5", true, false, "Healthcircle brightness between 1.0 and 0.0, where 1.0 is brightest and 0.0 is off. Clientside.")
CreateClientConVar("zm_cl_scrollspeed", "40", true, true, "How fast the speed is for the Zombie Master when using scroll to move up and down.")

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

local function ZM_Power_AmbushCreate(ply)
	if (not IsValid(ply)) or (IsValid(ply) and not ply:IsZM()) then
		return
	end
	
	ply:PrintTranslatedMessage(HUD_PRINTTALK, "enter_ambush_mode")
	
	hook.Call("SetPlacingAmbush", GAMEMODE, true)
end
concommand.Add("zm_power_ambushpoint", ZM_Power_AmbushCreate, nil, "Creates a ambush point for zombies")

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