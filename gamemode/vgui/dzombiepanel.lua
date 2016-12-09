local PANEL = {}

AccessorFunc(PANEL, "m_iFlags", 	"Zombieflags", 	FORCE_NUMBER)
AccessorFunc(PANEL, "m_iCurrent", 	"Current", 		FORCE_NUMBER)

function PANEL:Paint(w, h)
	draw.RoundedBox(0, 0, 0, w, h, Color(60, 0, 0, 200))
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
		
	if not self.DontDisabled then
		if #self.ParentQueue:GetItems() <= 0 then
			self:SetEnabled(false)
		else
			self:SetEnabled(true)
		end
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
		surface.DrawRect(0, 0, ScrW() - 5, ScrH() - 5)
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
	self.removeOne.DontDisabled = true
	self.removeOne.Paint = PaintButton
	self.removeOne.Think = ThinkButton
	self.removeOne.DoClick = function()
		if LocalPlayer():IsZM() then
			if #self.queue:GetItems() > 0 then
				RunConsoleCommand("zm_rqueue", self:GetCurrent())
				self:UpdateQueue()
			end
		end
	end
	
	self.clearQueue = vgui.Create("DButton", self)
	self.clearQueue.ParentQueue = self.queue
	self.clearQueue:SetPos(self:GetWide() - 90, self:GetTall() - 38)
	self.clearQueue:SetSize(80, 20)
	self.clearQueue:SetText("Clear")
	self.clearQueue:SetTextColor(color_white)
	self.clearQueue.DontDisabled = true
	self.clearQueue.Paint = PaintButton
	self.clearQueue.Think = ThinkButton
	self.clearQueue.DoClick = function()
		if LocalPlayer():IsZM() then
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
		if LocalPlayer():IsZM() then
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
		if LocalPlayer():IsZM() then
			self:Close()
		end
	end
end

function PANEL:Populate()
	local zombieData = GAMEMODE:GetZombieTable()
	
	for k, data in SortedPairsByMemberValue(zombieData, "Cost", false) do
		local buttonBase = vgui.Create("DPanel")
		buttonBase:SetTall(28)
		buttonBase.Paint = function() end
		
		local buttonSingle = vgui.Create("DButton", buttonBase)
		buttonSingle:SetSize(75, 28)
		buttonSingle:SetText(data.Name)
		buttonSingle.Paint = PaintButton
		buttonSingle.Think = ThinkButtonZombie
		buttonSingle.DoClick = function()
			RunConsoleCommand("zm_spawnzombie", self:GetCurrent(), data.Class, 1)
		end
		
		buttonSingle.OnCursorEntered = function()
			self.image = vgui.Create("DImage", self)
			self.image:SetImage(data.Icon)
			self.image:SetPos(146, 30)
			self.image:SetSize(142, 142)

			self.base = vgui.Create("DPanel", self)
			self.base:SetPos(120, self:GetTall() - 145)
			self.base:SetSize(200, 106)
			self.base.Paint = function() end
			
			self.costLabel = EasyLabel(self.base, "Resources: " .. data.Cost, "DefaultFontBold", color_white)
			self.costLabel:SetPos(5, 20)
			
			self.popLabel = EasyLabel(self.base, "Population: " .. data.PopCost, "DefaultFontBold", color_white)
			self.popLabel:SetPos(5, 40)
			
			self.desc = EasyLabel(self.base, data.Description, "DefaultFontBold", color_white)
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
			RunConsoleCommand("zm_spawnzombie", self:GetCurrent(), data.Class, 5)
		end
		
		buttonFive:MoveRightOf(buttonSingle, 5)
		
		if not gamemode.Call("CanSpawnZombie", data.Flag or 0, self:GetZombieflags()) then
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
	local smallImage = "VGUI/zombies/queue_"..string.lower(data.Name)
	
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