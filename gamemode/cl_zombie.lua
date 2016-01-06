--[[
	- Angry Lawyer: April 17, 2007 -
	
	Note about ZombieFlags 
	These are set by adding the following numbers together: 

	0 - Everything 
	1 - Shamblers 
	2 - Banshees 
	4 - Hulks 
	8 - Drifters
	16 - Immolators
	
	Max: 31
]]

local function CanSpawnZombie(flag)
	local allowed = {}
	allowed[1] = false
	allowed[2] = false
	allowed[4] = false
	allowed[8] = false
	allowed[16] = false
	
	if flag == 0 then
		return true
	else
		for i = 1, 5 do
			if (flag - 16) >= 0 then
				flag = flag -16
				allowed[16] = true
			end

			if (flag - 8) >= 0 then
				flag = flag -8
				allowed[8] = true
			end

			if (flag - 4) >= 0 then
				flag = flag -4
				allowed[4] = true
			end

			if (flag - 2) >= 0 then
				flag = flag -2
				allowed[2] = true
			end

			if (flag - 1) >= 0 then
				flag = flag -1
				allowed[1] = true
			end
		end
		
		return allowed
	end
	
	return false
end

local zombieMenus = {}

function GM:GetZombieMenus()
	return zombieMenus
end

function GM:ResetZombieMenus()
	for k, v in pairs(zombieMenus) do
		v:Remove()
	end
	
	zombieMenus = {}
end

local PANEL = {}

AccessorFunc(PANEL, "m_iFlags", 	"Zombieflags", 	FORCE_NUMBER)
AccessorFunc(PANEL, "m_iCurrent", 	"Current", 		FORCE_NUMBER)

function PANEL:Paint(w, h)
	draw.RoundedBox(0, 0, 0, w, h, Color(60, 0, 0, 100))
end

local function PaintButton(self, w, h)
	if self.m_bDisabled then
		boxColor = Color(58, 0, 0)
		surfaceColor = Color(26, 0, 0, 250)
		self:SetTextColor(Color(60, 60, 60))
	elseif self:IsHovered() then
		boxColor = Color(173, 0, 0)
		surfaceColor = Color(78, 0, 0, 250)
		self:SetTextColor(color_white)
	else
		boxColor = Color(115, 0, 0)
		surfaceColor = Color(52, 0, 0, 250)
		self:SetTextColor(color_white)
	end
	
	draw.OutlinedBox(0, 0, w, h, 2, boxColor)
	surface.SetDrawColor(surfaceColor)
	surface.DrawRect(2, 2, w - 3, h - 3)
end
local function ThinkButton(self)
	self.BaseClass.Think(self)
		
	if #self.ParentQueue:GetItems() <= 0 then
		self:SetEnabled(false)
	else
		self:SetEnabled(true)
	end
	
	if self.bActive ~= not self.m_bDisabled then
		self.bActive = not self.m_bDisabled
		if not self.bActive then
			self:AlphaTo(185, 0.75, 0)
			self:SetTextColor(Color(60, 60, 60))
		else
			self:AlphaTo(255, 0.75, 0)
			self:SetTextColor(color_white)
		end
	end
end
function PANEL:Init()
	self:SetSize(400, 300)
	self:SetTitle("Spawn Menu")
	self:MakePopup()
	
	self.imageBackground = vgui.Create("DPanel", self)
	self.imageBackground:SetSize(142, 142)
	self.imageBackground:SetPos(146, 30)
	self.imageBackground.Paint = function() 
		surface.SetDrawColor(Color(52, 0, 0, 250))
		surface.DrawRect(0, 0, w - 5, h - 5)
	end
	
	self.buttons = vgui.Create("DPanelList", self)
	self.buttons:SetPos(4, 28)
	self.buttons:SetSize(115, self:GetTall() - 32)
	self.buttons:SetPadding(2)
	self.buttons:SetSpacing(4)
	
	self.buttons.Paint = function(self, w, h)
		draw.DrawSimpleRect(w - 1, 0, 1, h * 0.8, color_black)
	end
	
	self.queue = vgui.Create("DPanelList", self)
	self.queue:SetPos(self:GetWide() - 98, 24)
	self.queue:SetSize(125, self:GetTall() - 62)
	self.queue:SetPadding(1)
	self.queue:SetSpacing(1)
	self.queue:EnableHorizontal(true)
	
	self.queue.Paint = function(self, w, h)
		draw.DrawSimpleRect(1, 0, 1, h * 0.93, color_black)
	end
	
	self.removeOne = vgui.Create("DButton", self)
	self.removeOne.ParentQueue = self.queue
	self.removeOne:SetPos(self:GetWide() - 90, self:GetTall() - 62)
	self.removeOne:SetSize(80, 20)
	self.removeOne:SetText("Remove Last")
	self.removeOne:SetTextColor(color_white)
	self.removeOne.Paint = PaintButton
	self.removeOne.Think = ThinkButton
	self.removeOne.DoClick = function()
		if MySelf:IsZM() then
			if #self.queue:GetItems() > 0 then
				self:UpdateQueue()
				RunConsoleCommand("zm_rqueue", self:GetCurrent())
			end
		end
	end
	
	self.clearQueue = vgui.Create("DButton", self)
	self.clearQueue.ParentQueue = self.queue
	self.clearQueue:SetPos(self:GetWide() - 90, self:GetTall() - 38)
	self.clearQueue:SetSize(80, 20)
	self.clearQueue:SetText("Clear")
	self.clearQueue:SetTextColor(color_white)
	self.clearQueue.Paint = PaintButton
	self.clearQueue.Think = ThinkButton
	self.clearQueue.DoClick = function()
		if MySelf:IsZM() then
			if #self.queue:GetItems() > 0 then
				self.queue:Clear()
				RunConsoleCommand("zm_rqueue", self:GetCurrent(), "1")
			end
		end
	end
	
	self.placeRally = vgui.Create("DButton", self)
	self.placeRally.ParentQueue = self.queue
	self.placeRally:SetPos(self:GetWide() - 372, self:GetTall() - 38)
	self.placeRally:SetSize(95, 32)
	self.placeRally:SetText("Place Rally Point")
	self.placeRally:SetTextColor(color_white)
	self.placeRally.Paint = PaintButton
	self.placeRally.DoClick = function()
		if MySelf:IsZM() then
			gamemode.Call("CreateGhostEntity", false, self:GetCurrent())
			self:Close()
		end
	end
	
	self.closebut = vgui.Create("DButton", self)
	self.closebut.ParentQueue = self.queue
	self.closebut:SetPos(self:GetWide() - 250, self:GetTall() - 38)
	self.closebut:SetSize(128, 32)
	self.closebut:SetText("Close")
	self.closebut:SetTextColor(color_white)
	self.closebut.Paint = PaintButton
	self.closebut.DoClick = function()
		if MySelf:IsZM() then
			self:Close()
		end
	end
end

function PANEL:Populate()
	local zombieData = GAMEMODE:GetZombieTable()
	
	for k, data in ipairs(zombieData) do
		local buttonBase = vgui.Create("DPanel")
		buttonBase:SetTall(28)
		buttonBase.Paint = function() end
		
		local buttonSingle = vgui.Create("DButton", buttonBase)
		buttonSingle:SetSize(75, 28)
		buttonSingle:SetText(data.name)
		buttonSingle.Paint = PaintButton
		buttonSingle.Think = ThinkButtonZombie
		buttonSingle.DoClick = function()
			RunConsoleCommand("zm_spawnzombie", self:GetCurrent(), data.class, 1)
		end
		
		buttonSingle.OnCursorEntered = function()
			self.image = vgui.Create("DImage", self)
			self.image:SetImage(data.icon)
			self.image:SetPos(146, 30)
			self.image:SetSize(142, 142)

			self.base = vgui.Create("DPanel", self)
			self.base:SetPos(120, self:GetTall() - 145)
			self.base:SetSize(200, 106)
			self.base.Paint = function() end
			
			self.costLabel = EasyLabel(self.base, "Resources: " .. data.cost, "DefaultFontBold", color_white)
			self.costLabel:SetPos(5, 20)
			
			self.popLabel = EasyLabel(self.base, "Population: " .. data.popCost, "DefaultFontBold", color_white)
			self.popLabel:SetPos(5, 40)
			
			self.desc = EasyLabel(self.base, data.description, "DefaultFontBold", color_white)
			self.desc:SetPos(5, 60)
			self.desc:DockMargin(5, 60, 12, 0)
			self.desc:Dock(FILL)
			self.desc:SetContentAlignment(7)
			self.desc:SetWrap(true)
		end
		
		buttonSingle.OnCursorExited = function()
			if (self.image) then
				self.image:Remove()
			end
			
			if (self.base) then
				self.base:Remove()
			end
		end

		local buttonFive = vgui.Create("DButton", buttonBase)
		buttonFive:SetSize(25, 28)
		buttonFive:SetText("x 5")
		buttonFive.Paint = PaintButton
		buttonFive.Think = ThinkButtonZombie
		buttonFive.DoClick = function()
			RunConsoleCommand("zm_spawnzombie", self:GetCurrent(), data.class, 5)
		end
		
		buttonFive:MoveRightOf(buttonSingle, 5)
		
		local zombieFlags = self:GetZombieflags()
		local allowed = CanSpawnZombie(zombieFlags)
		
		if allowed and type(allowed) == "table" and not allowed[data.flag] then
			buttonSingle:SetDisabled(true)
			buttonFive:SetDisabled(true)
		end
		
		buttonFive.OnCursorEntered = buttonSingle.OnCursorEntered
		buttonFive.OnCursorExited  = buttonSingle.OnCursorExited
		
		self.buttons:AddItem(buttonBase)
	end
end

function PANEL:AddQueue(type)
	local data = GAMEMODE:GetZombieData(type)
	local smallImage = "VGUI/zombies/queue_"..string.lower(data.name)
	
	local image = vgui.Create("DImage")
	image:SetImage(smallImage)
	image:SetSize(32, 32)
	
	self.queue:AddItem(image)
end

function PANEL:UpdateQueue()
	local items = self.queue:GetItems()
	self.queue:RemoveItem(table.GetFirstValue(items))
end

function PANEL:Close()
	self:SetVisible(false)
end

function PANEL:Think()
	if self:IsVisible() then
		GAMEMODE:SetDragging(false)
	end
end

vgui.Register("zm_zombiemenu", PANEL, "DFrame")

net.Receive("zm_queue", function(len)
	local type = net.ReadString()
	local id = ents.GetByIndex(net.ReadInt(32))
	local menu = zombieMenus[id]
	
	if menu then
		menu:AddQueue(type)
	end
end)

net.Receive("zm_remove_queue", function(um)
	local id = ents.GetByIndex(net.ReadInt(32))
	local menu = zombieMenus[id]
	
	if menu then
		menu:UpdateQueue()
	end
end)

local PANEL = {}

local image1 = surface.GetTextureID("VGUI/minicrosshair")
local image2 = surface.GetTextureID("VGUI/minishockwave")
local image3 = surface.GetTextureID("VGUI/minigroupadd")
	
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
	
	self.button1.Paint = function(self)
		local w, h = self:GetSize()
		
		draw.DrawSimpleRect(0, 0, w, h, Color(60, 0, 0, self.alpha))
		
		surface.SetDrawColor(255, 255, 255, self.alpha)
		surface.SetTexture(image1)
		surface.DrawTexturedRect(2, 0, 32, 32)
		
		draw.DrawSimpleOutlined(0, 0, w, h -1, color_black)
	end
	
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
					draw.RoundedBox(4, 2, 2, w - 4, h - 4, Color(59, 0, 0))
				end
				
				self.toollab = vgui.Create("DLabel", self.toolpan)
				self.toollab:SetTextColor(color_white)
				self.toollab:SetText(v.tooltip)
				self.toollab:SetFont("ZSHUDFontSmaller")
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
	
	self.button2.Paint = function(self)
		local w, h = self:GetSize()
		
		draw.DrawSimpleRect(0, 0, w, h, Color(60, 0, 0, self.alpha))
		
		surface.SetDrawColor(255, 255, 255, self.alpha)
		surface.SetTexture(image2)
		surface.DrawTexturedRect(2, 1, 30, 30)
		
		draw.DrawSimpleOutlined(0, 0, w, h -1, color_black)
	end
	
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
	
	self.button3.Paint = function(self)
		local w, h = self:GetSize()
		
		draw.DrawSimpleRect(0, 0, w, h, Color(60, 0, 0, self.alpha))
		
		surface.SetDrawColor(255, 255, 255, self.alpha)
		surface.SetTexture(image3)
		surface.DrawTexturedRect(2, 0, 32, 32)
		
		draw.DrawSimpleOutlined(0, 0, w, h -1, color_black)
	end
end

function PANEL:Paint()
	local w, h = self:GetSize()
	
	draw.DrawSimpleRect(0, 32, w, h - 32, Color(60, 0, 0, 200))
	draw.DrawSimpleOutlined(0, 32, w, h - 32, color_black)
end

vgui.Register("zm_powerpanel", PANEL, "DPanel")