CATEGORY_ACTIONS = 1
CATEGORY_POWERS = 2
CATEGORY_GROUPS = 3

GM.PowerCatImages = {}
GM.PowerCatImages[CATEGORY_ACTIONS] = "VGUI/minicrosshair"
GM.PowerCatImages[CATEGORY_POWERS] = "VGUI/minishockwave"
GM.PowerCatImages[CATEGORY_GROUPS] = "VGUI/minigroupadd"

GM.PowerCategorys = {}

function GM:AddZMPower(cat, func)
	if not self.PowerCategorys[cat] then
		self.PowerCategorys[cat] = {}
	end
	
	table.insert(self.PowerCategorys[cat], func)
end

function GM:SetupZMPowers()
	if not IsValid(self.powerMenu) then return end
	
	for cat, functions in pairs(self.PowerCategorys) do
		local Scroll = vgui.Create("DScrollPanel")
		Scroll:Dock(FILL)
	
		local Tab = vgui.Create("DIconLayout", Scroll)
		Tab:Dock(FILL)
		Tab:SetBorder(4)
		Tab:SetSpaceX(8)
		Tab:SetSpaceY(8)
		Scroll.LayoutPan = Tab
		
		self.powerMenu:AddSheet("PowerTab"..cat, Scroll, self.PowerCatImages[cat], true, true)
		
		for _, power in pairs(functions) do
			pcall(power, cat)
		end
	end
end

GM:AddZMPower(CATEGORY_ACTIONS,	function(Cat)
	local button = vgui.Create("zm_powerbutton")
	button:SetSize(ScreenScale(11), ScreenScale(11))
	button:SetImage("VGUI/miniselectall")
	button:SetKeepAspect(true)
	button:SetTip(translate.Get("tooltip_select_all"))
	button.DoClick = function(self)
		net.Start("zm_selectall_zombies") 
		net.SendToServer() 
	end
	
	GAMEMODE.powerMenu:AddItem("ZM_Action_SelectAll", button, Cat)
end)

GM:AddZMPower(CATEGORY_ACTIONS, function(Cat)  
	local button = vgui.Create("zm_powerbutton") 
	button:SetSize(ScreenScale(11), ScreenScale(11)) 
	button:SetImage("VGUI/minishield") 
	button:SetKeepAspect(true) 
	button:SetTip(translate.Get("tooltip_defend")) 
	button.DoClick = function(self) 
		net.Start("zm_switch_to_defense")  
		net.SendToServer()  
	end 

	GAMEMODE.powerMenu:AddItem("ZM_Action_Defend", button, Cat) 
end)

GM:AddZMPower(CATEGORY_ACTIONS, function(Cat) 
	local button = vgui.Create("zm_powerbutton")
	button:SetSize(ScreenScale(11), ScreenScale(11))
	button:SetImage("VGUI/minicrosshair")
	button:SetKeepAspect(true)
	button:SetTip(translate.Get("tooltip_attack"))
	button.DoClick = function(self)
		net.Start("zm_switch_to_offense") 
		net.SendToServer() 
	end
	
	GAMEMODE.powerMenu:AddItem("ZM_Action_Offense", button, Cat)
end)

GM:AddZMPower(CATEGORY_ACTIONS, function(Cat) 
	local button = vgui.Create("zm_powerbutton")
	button:SetSize(ScreenScale(11), ScreenScale(11))
	button:SetImage("VGUI/miniarrows")
	button:SetKeepAspect(true)
	button:SetTip(translate.Get("tooltip_ambush"))
	button.DoClick = function(self)
		RunConsoleCommand("zm_power_ambushpoint") 
	end
	
	GAMEMODE.powerMenu:AddItem("ZM_Action_Ambush", button, Cat)
end)

GM:AddZMPower(CATEGORY_ACTIONS, function(Cat) 
	local button = vgui.Create("zm_powerbutton")
	button:SetSize(ScreenScale(11), ScreenScale(11))
	button:SetImage("VGUI/miniceiling")
	button:SetKeepAspect(true)
	button:SetTip(translate.Get("tooltip_ceiling"))
	button.DoClick = function(self)
		net.Start("zm_cling_ceiling") 
		net.SendToServer()
	end
	
	GAMEMODE.powerMenu:AddItem("ZM_Action_Ceiling", button, Cat)
end)

GM:AddZMPower(CATEGORY_POWERS, function(Cat)
	local button = vgui.Create("zm_powerbutton")
	button:SetSize(ScreenScale(11), ScreenScale(11))
	button:SetImage("VGUI/minieye")
	button:SetKeepAspect(true)
	button:SetTip(translate.Get("tooltip_nightvision"))
	button.DoClick = function(self)
		RunConsoleCommand("zm_power_nightvision") 
	end
	
	GAMEMODE.powerMenu:AddItem("ZM_Power_Nightvision", button, Cat)	
end)

GM:AddZMPower(CATEGORY_POWERS, function(Cat) 
	local button = vgui.Create("zm_powerbutton")
	button:SetSize(ScreenScale(11), ScreenScale(11))
	button:SetImage("VGUI/minishockwave")
	button:SetKeepAspect(true)
	button:SetTip(translate.Format("tooltip_explosion_cost_x", GetConVar("zm_physexp_cost"):GetInt()))
	button.DoClick = function(self)
		RunConsoleCommand("zm_power_physexplode") 
	end
	
	GAMEMODE.powerMenu:AddItem("ZM_Power_Explosion", button, Cat)
end)

GM:AddZMPower(CATEGORY_POWERS, function(Cat) 
	local button = vgui.Create("zm_powerbutton")
	button:SetSize(ScreenScale(11), ScreenScale(11))
	button:SetImage("VGUI/minideletezombies")
	button:SetKeepAspect(true)
	button:SetTip(translate.Get("tooltip_expire_zombies"))
	button.DoClick = function(self)
		RunConsoleCommand("zm_power_killzombies") 
	end
	
	GAMEMODE.powerMenu:AddItem("ZM_Power_KillZombies", button, Cat)
end)

GM:AddZMPower(CATEGORY_POWERS, function(Cat) 
	local button = vgui.Create("zm_powerbutton")
	button:SetSize(ScreenScale(11), ScreenScale(11))
	button:SetImage("VGUI/minispotcreate")
	button:SetKeepAspect(true)
	button:SetTip(translate.Format("tooltip_hidden_zombie_cost_x", GetConVar("zm_spotcreate_cost"):GetInt()))
	button.DoClick = function(self)
		RunConsoleCommand("zm_power_spotcreate") 
	end
	
	GAMEMODE.powerMenu:AddItem("ZM_Power_HiddenSpawn", button, Cat)
end)

GM:AddZMPower(CATEGORY_GROUPS, function(Cat)
	local button = vgui.Create("zm_powerbutton")
	button:SetSize(ScreenScale(11), ScreenScale(11))
	button:SetImage("VGUI/minigroupadd")
	button:SetKeepAspect(true)
	button:SetTip(translate.Get("tooltip_create_squad"))
	button.DoClick = function(self)
		net.Start("zm_creategroup") 
		net.SendToServer() 
	end
	
	GAMEMODE.powerMenu:AddItem("ZM_Group_Create", button, Cat)	
end)

GM:AddZMPower(CATEGORY_GROUPS, function(Cat) 
	local button = vgui.Create("zm_powerbutton")
	button:SetSize(ScreenScale(11), ScreenScale(11))
	button:SetImage("VGUI/minigroupselect")
	button:SetKeepAspect(true)
	button:SetTip(translate.Get("tooltip_select_squad"))
	button.DoClick = function(self)
		net.Start("zm_selectgroup") 
		net.SendToServer()
	end
	
	GAMEMODE.powerMenu:AddItem("ZM_Group_Select", button, Cat)
end)

GM:AddZMPower(CATEGORY_GROUPS, function(Cat) 
	local dropdown = vgui.Create("DComboBox")
	dropdown:SetMouseInputEnabled(true)
	dropdown:SetPos(0, 10)
	dropdown:SetText("None")
	dropdown.OnSelect = function(me, index, value, data)
		net.Start("zm_setselectedgroup")
			net.WriteString(string.Replace(tostring(value), "Group ", ""))
		net.SendToServer()
	end
	dropdown.Think = function(self)
		self.BaseClass.Think(self)
		
		if GAMEMODE.bUpdateGroups then
			local groups = gamemode.Call("GetCurrentZombieGroups")
			if groups then
				for i, group in pairs(groups) do
					self:AddChoice("Group "..i)
				end
			end
			dropdown:SetText(groups and "Group "..gamemode.Call("GetCurrentZombieGroup") or "None")
			GAMEMODE.bUpdateGroups = false
		end
	end
	
	GAMEMODE.powerMenu:AddItem("ZM_Group_List", dropdown, Cat)
end)