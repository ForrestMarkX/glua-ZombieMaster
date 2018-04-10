CATEGORY_ACTIONS = 1
CATEGORY_POWERS = 2
CATEGORY_GROUPS = 3

GM.PowerCatImages = {}
GM.PowerCatImages[CATEGORY_ACTIONS] = "VGUI/minicrosshair"
GM.PowerCatImages[CATEGORY_POWERS] = "VGUI/minishockwave"
GM.PowerCatImages[CATEGORY_GROUPS] = "VGUI/minigroupadd"

GM.PowerCategorys = {}

function GM:AddZMPower(cat, name, callback)
    if not self.PowerCategorys[cat] then
        self.PowerCategorys[cat] = {}
    end
    
    table.insert(self.PowerCategorys[cat], {name, callback})
end

function GM:SetupZMPowers()
    if not IsValid(self.powerMenu) then return end
    
    for cat, tab in pairs(self.PowerCategorys) do
        local Scroll = vgui.Create("DScrollPanel")
        Scroll:Dock(FILL)
    
        local IconTab = vgui.Create("DIconLayout", Scroll)
        IconTab:Dock(FILL)
        IconTab:SetBorder(4)
        IconTab:SetSpaceX(8)
        IconTab:SetSpaceY(8)
        Scroll.LayoutPan = IconTab
        
        self.powerMenu:AddSheet("PowerTab"..cat, Scroll, self.PowerCatImages[cat], true, true)
        
        for _, info in pairs(tab) do
            local success, panel = pcall(info[2])
            if not success then continue end
            
            if not ispanel(panel) then
                ErrorNoHalt("The callback for the ZM power (" .. info[1] .. ") did not return a panel!")
                continue
            end
            
            GAMEMODE.powerMenu:AddItem(info[1], panel, cat)
        end
    end
end

GM:AddZMPower(CATEGORY_ACTIONS, "ZM_Action_SelectAll", function()
    local button = vgui.Create("zm_powerbutton")
    button:SetSize(ScreenScale(11), ScreenScale(11))
    button:SetImage("VGUI/miniselectall")
    button:SetKeepAspect(true)
    button:SetTip(translate.Get("tooltip_select_all"))
    button.DoClick = function(self)
        net.Start("zm_selectall_zombies") 
        net.SendToServer() 
    end
    
    return button
end)

GM:AddZMPower(CATEGORY_ACTIONS, "ZM_Action_Defend", function()  
    local button = vgui.Create("zm_powerbutton") 
    button:SetSize(ScreenScale(11), ScreenScale(11)) 
    button:SetImage("VGUI/minishield") 
    button:SetKeepAspect(true) 
    button:SetTip(translate.Get("tooltip_defend")) 
    button.DoClick = function(self) 
        net.Start("zm_switch_to_defense")  
        net.SendToServer()  
    end 

    return button
end)

GM:AddZMPower(CATEGORY_ACTIONS, "ZM_Action_Offense", function() 
    local button = vgui.Create("zm_powerbutton")
    button:SetSize(ScreenScale(11), ScreenScale(11))
    button:SetImage("VGUI/minicrosshair")
    button:SetKeepAspect(true)
    button:SetTip(translate.Get("tooltip_attack"))
    button.DoClick = function(self)
        net.Start("zm_switch_to_offense") 
        net.SendToServer() 
    end
    
    return button
end)

GM:AddZMPower(CATEGORY_ACTIONS, "ZM_Action_Ambush", function() 
    local button = vgui.Create("zm_powerbutton")
    button:SetSize(ScreenScale(11), ScreenScale(11))
    button:SetImage("VGUI/miniarrows")
    button:SetKeepAspect(true)
    button:SetTip(translate.Get("tooltip_ambush"))
    button.DoClick = function(self)
        RunConsoleCommand("zm_power_ambushpoint") 
    end
    
    return button
end)

GM:AddZMPower(CATEGORY_ACTIONS, "ZM_Action_Ceiling", function() 
    local button = vgui.Create("zm_powerbutton")
    button:SetSize(ScreenScale(11), ScreenScale(11))
    button:SetImage("VGUI/miniceiling")
    button:SetKeepAspect(true)
    button:SetTip(translate.Get("tooltip_ceiling"))
    button.DoClick = function(self)
        net.Start("zm_cling_ceiling") 
        net.SendToServer()
    end
    
    return button
end)

GM:AddZMPower(CATEGORY_POWERS, "ZM_Power_Nightvision", function()
    local button = vgui.Create("zm_powerbutton")
    button:SetSize(ScreenScale(11), ScreenScale(11))
    button:SetImage("VGUI/minieye")
    button:SetKeepAspect(true)
    button:SetTip(translate.Get("tooltip_nightvision"))
    button.DoClick = function(self)
        RunConsoleCommand("zm_power_nightvision") 
    end
    
    return button
end)

GM:AddZMPower(CATEGORY_POWERS, "ZM_Power_Explosion", function() 
    local button = vgui.Create("zm_powerbutton")
    button:SetSize(ScreenScale(11), ScreenScale(11))
    button:SetImage("VGUI/minishockwave")
    button:SetKeepAspect(true)
    button:SetTip(translate.Format("tooltip_explosion_cost_x", GetConVar("zm_physexp_cost"):GetInt()))
    button.DoClick = function(self)
        RunConsoleCommand("zm_power_physexplode") 
    end
    
    return button
end)

GM:AddZMPower(CATEGORY_POWERS, "ZM_Power_KillZombies", function() 
    local button = vgui.Create("zm_powerbutton")
    button:SetSize(ScreenScale(11), ScreenScale(11))
    button:SetImage("VGUI/minideletezombies")
    button:SetKeepAspect(true)
    button:SetTip(translate.Get("tooltip_expire_zombies"))
    button.DoClick = function(self)
        RunConsoleCommand("zm_power_killzombies") 
    end
    
    return button
end)

GM:AddZMPower(CATEGORY_POWERS, "ZM_Power_HiddenSpawn", function() 
    local button = vgui.Create("zm_powerbutton")
    button:SetSize(ScreenScale(11), ScreenScale(11))
    button:SetImage("VGUI/minispotcreate")
    button:SetKeepAspect(true)
    button:SetTip(translate.Format("tooltip_hidden_zombie_cost_x", GetConVar("zm_spotcreate_cost"):GetInt()))
    button.DoClick = function(self)
        RunConsoleCommand("zm_power_spotcreate") 
    end
    
    return button
end)

GM:AddZMPower(CATEGORY_GROUPS, "ZM_Group_Create", function()
    local button = vgui.Create("zm_powerbutton")
    button:SetSize(ScreenScale(11), ScreenScale(11))
    button:SetImage("VGUI/minigroupadd")
    button:SetKeepAspect(true)
    button:SetTip(translate.Get("tooltip_create_squad"))
    button.DoClick = function(self)
        net.Start("zm_creategroup") 
        net.SendToServer() 
    end
    
    return button
end)

GM:AddZMPower(CATEGORY_GROUPS, "ZM_Group_Select", function() 
    local button = vgui.Create("zm_powerbutton")
    button:SetSize(ScreenScale(11), ScreenScale(11))
    button:SetImage("VGUI/minigroupselect")
    button:SetKeepAspect(true)
    button:SetTip(translate.Get("tooltip_select_squad"))
    button.DoClick = function(self)
        net.Start("zm_selectgroup") 
        net.SendToServer()
    end
    
    return button
end)

GM:AddZMPower(CATEGORY_GROUPS, "ZM_Group_List", function() 
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
    
    return dropdown
end)