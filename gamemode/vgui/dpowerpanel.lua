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
		{image = "VGUI/miniselectall", func = function() RunConsoleCommand("zm_selectall_zombies") end, tooltip = "Select all: Select all your zombies."},
		{image = "VGUI/minishield", func = function() RunConsoleCommand("zm_switch_to_defense") end, tooltip = "Defend: Order selected units to defend their current location."},
		{image = "VGUI/minicrosshair", func = function() RunConsoleCommand("zm_switch_to_offense") end, tooltip = "Attack: Order selected units to attack any humans they see."}
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
				
				self.toolpan.Paint = function(self, w, h)
					draw.RoundedBox(8, 0, 0, w, h, Color(89, 0, 0))
					draw.RoundedBox(4, 2, 2, w - 4, h - 4, Color(60, 0, 0))
				end
				
				self.toollab = vgui.Create("DLabel", self.toolpan)
				self.toollab:SetTextColor(color_white)
				self.toollab:SetText(v.tooltip)
				self.toollab:SetFont("ZMHUDFontSmaller")
				self.toollab:SizeToContents()
				
				self.toolpan:InvalidateLayout(true)
				self.toolpan:SizeToChildren(true, false)
				self.toolpan:SetSize(self.toolpan:GetWide() + 15, self.toolpan:GetTall())
				self.toollab:Center()
				self.toolpan:Center()
				self.toolpan:AlignBottom(10)
			end
			
			button.OnCursorExited = function(self)
				if self.toolpan then
					self.toolpan:Remove()
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
				RunConsoleCommand("zm_setselectedgroup", tostring(value))
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
	
	self.button2 = vgui.Create("DPanel", self)
	self.button2:SetPos(self:GetWide() /2 - 17, 0)
	self.button2:SetSize(34, 34)
	self.button2.alpha = 100
	
	self.button2.buttons = {
		{image = "VGUI/minieye", func = function() RunConsoleCommand("zm_power_nightvision") end, tooltip = "Nightvision: Toggles your nightvision."},
		{image = "VGUI/minishockwave", func = function() RunConsoleCommand("zm_power_physexplode") end, tooltip = "Explosion: Click in the world to blast objects away. (Costs "..GetConVar("zm_physexp_cost"):GetInt()..")."},
		{image = "VGUI/minideletezombies", func = function() RunConsoleCommand("zm_power_killzombies") end, tooltip = "Expire: Relinquish your control of the currently selected units."},
		{image = "VGUI/minispotcreate", func = function() RunConsoleCommand("zm_power_spotcreate") end, tooltip = "Hidden Summon: Click in the world to create a Shambler. Only works out of sight of the humans (Costs "..GetConVar("zm_spotcreate_cost"):GetInt()..")."}
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
		{image = "VGUI/minigroupadd", func = function() RunConsoleCommand("zm_creategroup") end, tooltip = "Create squad: Create a squad from selected units."},
		{image = "VGUI/minigroupselect", func = function() RunConsoleCommand("zm_selectgroup") end, tooltip = "Select squad: Select the chosen squad. The units in this squad will be selected."}
	}
	
	self.button3.Image = image3
	self.button3.Paint = ButtonPaint
end

function PANEL:Paint()
	local w, h = self:GetSize()
	
	draw.DrawSimpleRect(0, 32, w, h - 32, Color(60, 0, 0, 200))
	draw.DrawSimpleOutlined(0, 32, w, h - 32, color_black)
end

vgui.Register("zm_powerpanel", PANEL, "DPanel")