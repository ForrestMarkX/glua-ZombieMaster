local PANEL = {}

local image1 = surface.GetTextureID("VGUI/minicrosshair")
local image2 = surface.GetTextureID("VGUI/minishockwave")
local image3 = surface.GetTextureID("VGUI/minigroupadd")
	
local function ButtonPaint(self, w, h)
	draw.DrawSimpleRect(0, 0, w, h, Color(60, 0, 0, self.alpha))
	
	surface.SetDrawColor(255, 255, 255, self.alpha)
	surface.SetTexture(self.Image)
	surface.DrawTexturedRect(2, 0, 32, 32)
	
	draw.DrawSimpleOutlined(0, 0, w, h -1, color_black)
end
function PANEL:Init()
	self.last = nil
	
	self:SetSize(128, 128)
	self:SetPos(ScrW() - 130, ScrH() - 130)
	
	self.list = vgui.Create("DIconLayout", self)
	self.list:SetSize(self:GetWide() - 4, self:GetTall() - 37)
	self.list:SetPos(2, 34)
	self.list:SetBorder(4)
	self.list:SetSpaceX(8)
	self.list:SetSpaceY(8)
	self.list.Paint = function() end
	
	self.button1 = vgui.Create("DPanel", self)
	self.button1:SetPos(1, 0)
	self.button1:SetSize(34, 34)
	self.button1.alpha = 100
	
	self.button1.buttons = {
		{image = "VGUI/miniselectall", func = function() net.Start("zm_selectall_zombies") net.SendToServer() end, tooltip = translate.Get("tooltip_select_all")},
		{image = "VGUI/minishield", func = function() net.Start("zm_switch_to_defense") net.SendToServer() end, tooltip = translate.Get("tooltip_defend")},
		{image = "VGUI/minicrosshair", func = function() net.Start("zm_switch_to_offense") net.SendToServer() end, tooltip = translate.Get("tooltip_attack")},
		{image = "VGUI/miniarrows", func = function() RunConsoleCommand("zm_power_ambushpoint") end, tooltip = translate.Get("tooltip_ambush")},
		{image = "VGUI/miniceiling", func = function() net.Start("zm_cling_ceiling") net.SendToServer() end, tooltip = translate.Get("tooltip_ceiling")}
	}
	
	self.button1.Image = image1
	self.button1.Paint = ButtonPaint
	
	self.button1.OnMousePressed = function(_self, code)
		if self.last then
			self.last.alpha = 100
		end
		
		_self.alpha = 255
		self.last = _self
		
		self.list:Clear()
		
		for k, v in ipairs(_self.buttons) do
			local button = vgui.Create("DImageButton")
			button:SetSize(32, 32)
			button:SetImage(v.image)
			button.DoClick = function()
				v.func()
			end
			
			button.OnCursorEntered = function(self)
				self.toolpan = vgui.Create("DPanel")
				self.toolpan:SetSize(ScrW() * 0.1, ScrH() * 0.03)
				self.toolpan:InvalidateLayout(true)
				self.toolpan:Center()
				self.toolpan:AlignBottom(10)
				
				self.toollab = vgui.Create("DLabel", self.toolpan)
				self.toollab:SetTextColor(color_white)
				self.toollab:SetText(v.tooltip)
				self.toollab:SetFont("OptionsHelpBig")
				self.toollab:SizeToContents()
				
				self.toolpan:InvalidateLayout(true)
				self.toolpan:SizeToChildren(true, false)
				self.toolpan:SetSize(self.toolpan:GetWide() + 15, self.toolpan:GetTall())
				self.toollab:Center()
				self.toolpan:Center()
				self.toolpan:AlignBottom(10)
				
				GAMEMODE.ToolPan_Center_Tip = self.toolpan
			end
			
			button.OnCursorExited = function(self)
				if self.toolpan then
					self.toolpan:Remove()
					GAMEMODE.ToolPan_Center_Tip = nil
				end
			end
			
			self.list:Add(button)
		end
		
		if _self.GroupButton then
			local dropdown = vgui.Create("DComboBox", self.button3)
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
			self.list:Add(dropdown)
		end
	end
	self.button1:OnMousePressed()
	
	self.button2 = vgui.Create("DPanel", self)
	self.button2:SetPos(self:GetWide() /2 - 17, 0)
	self.button2:SetSize(34, 34)
	self.button2.alpha = 100
	
	self.button2.buttons = {
		{image = "VGUI/minieye", func = function() RunConsoleCommand("zm_power_nightvision") end, tooltip = translate.Get("tooltip_nightvision")},
		{image = "VGUI/minishockwave", func = function() RunConsoleCommand("zm_power_physexplode") end, tooltip = translate.Format("tooltip_explosion_cost_x", GetConVar("zm_physexp_cost"):GetInt())},
		{image = "VGUI/minideletezombies", func = function() RunConsoleCommand("zm_power_killzombies") end, tooltip = translate.Get("tooltip_expire_zombies")},
		{image = "VGUI/minispotcreate", func = function() RunConsoleCommand("zm_power_spotcreate") end, tooltip = translate.Format("tooltip_hidden_zombie_cost_x", GetConVar("zm_spotcreate_cost"):GetInt())}
	}
	
	self.button2.Image = image2
	self.button2.Paint = ButtonPaint
	
	self.button2.OnMousePressed = self.button1.OnMousePressed
	
	self.button3 = vgui.Create("DPanel", self)
	self.button3:SetPos(self:GetWide() - 35, 0)
	self.button3:SetSize(34, 34)
	self.button3.GroupButton = true
	self.button3.alpha = 100
	self.button3.OnMousePressed = self.button1.OnMousePressed
	
	self.button3.buttons = {
		{image = "VGUI/minigroupadd", func = function() net.Start("zm_creategroup") net.SendToServer() end, tooltip = translate.Get("tooltip_create_squad")},
		{image = "VGUI/minigroupselect", func = function() net.Start("zm_selectgroup") net.SendToServer() end, tooltip = translate.Get("tooltip_select_squad")}
	}
	
	self.button3.Image = image3
	self.button3.Paint = ButtonPaint
end

function PANEL:Paint(w, h)
	draw.DrawSimpleRect(0, 32, w, h - 32, Color(60, 0, 0, 200))
	draw.DrawSimpleOutlined(0, 32, w, h - 32, color_black)
end

vgui.Register("zm_powerpanel", PANEL, "DPanel")