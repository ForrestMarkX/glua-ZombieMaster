local skullMaterial  = surface.GetTextureID("VGUI/miniskull")
local popMaterial	 = surface.GetTextureID("VGUI/minifigures")
local selection_color_outline = Color(255, 0, 0, 255)
local selection_color_box 	  = Color(120, 0, 0, 80)

function GM:_HUDPaint()
	local myteam = MySelf:Team()
	local screenscale = BetterScreenScale()
	local wid, hei = 225 * screenscale, 72 * screenscale

	if MySelf:IsSurvivor() then
		self:HumanHUD(screenscale)
	elseif MySelf:IsZM() then
		self:ZombieMasterHUD(screenscale)
	end
	
	if not self:GetRoundActive() then
		draw.SimpleText("Waiting for all players to be ready.", "ZSHUDFontSmall", w * 0.5, h * 0.25, COLOR_GRAY, TEXT_ALIGN_CENTER)
	end
	
	hook.Run( "HUDDrawTargetID" )
	hook.Run( "HUDDrawPickupHistory" )
	hook.Run( "DrawDeathNotice", 0.85, 0.04 )
end

function GM:_HUDShouldDraw(name)
	local wep = MySelf:GetActiveWeapon()
	if wep.HUDShouldDraw then
		local ret = wep:HUDShouldDraw(name)
		if ret ~= nil then return ret end
	end

	return name ~= "CHudHealth" and name ~= "CHudBattery" and name ~= "CHudAmmo" and name ~= "CHudSecondaryAmmo"
end

function GM:HumanHUD(screenscale)	
	local wid, hei = 225 * screenscale, 72 * screenscale
	local x, y = ScrW() - wid - screenscale * (ScrW() - (ScrW() * 0.18)), ScrH() - hei - screenscale * 32
	
	draw.RoundedBox(16, x + 2, y + 2, wid, hei, Color(60, 0, 0, 200))
	
	local health = MySelf:Health()
	local healthCol = health <= 10 and Color(185, 0, 0, 255) or health <= 30 and Color(150, 50, 0) or health <= 60 and Color(255, 200, 0) or color_white
	draw.SimpleTextBlurry(MySelf:Health(), "ZSHUDFontBig", x + wid * 0.75, y + hei * 0.5, healthCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	draw.SimpleTextBlurry("Health", "ZSHUDFontSmall", x + wid * 0.27, y + hei * 0.7, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

local h, w = ScrH(), ScrW()
function GM:ZombieMasterHUD(scale)
	if MySelf:IsZM() then
		-- Resources + Income.
		draw.DrawSimpleRect(5, h - 43, 150, 38, Color(60, 0, 0, 200))
		draw.DrawSimpleOutlined(5, h - 43, 150, 38, color_black)
		
		surface.SetDrawColor(color_white)
		surface.SetTexture(skullMaterial)
		surface.DrawTexturedRect(7, h - 41, 32, 32)
		
		draw.DrawText(MySelf:GetZMPoints(), "zm_hud_font", 60, h - 42, color_white, 1)
		
		if MySelf:GetZMPointIncome() then
			draw.DrawText("+ " .. MySelf:GetZMPointIncome(), "zm_hud_font2", 90, h - 24, color_white, 1)
		end
		
		-- Population.
		draw.DrawSimpleRect(5, h - 62, 100, 18, Color(60, 0, 0, 200))
		draw.DrawSimpleOutlined(5, h - 62, 100, 18, color_black)
		
		surface.SetDrawColor(color_white)
		surface.SetTexture(popMaterial)
		surface.DrawTexturedRect(6, h - 61, 16, 16)
		
		draw.DrawText(self:GetCurZombiePop() .. "/" .. self:GetMaxZombiePop(), "zm_hud_font2", 60, h - 62, color_white, 1)

		if isDragging then
			local x, y = gui.MousePos()
			
			traceX, traceY = x, y

			if mouseX < x then
				if mouseY < y then
					surface.SetDrawColor(selection_color_outline)
					surface.DrawOutlinedRect(mouseX, mouseY, x -mouseX, y -mouseY)
				
					surface.SetDrawColor(selection_color_box)
					surface.DrawRect(mouseX, mouseY, x -mouseX, y -mouseY)
				else
					surface.SetDrawColor(selection_color_outline)
					surface.DrawOutlinedRect(mouseX, y, x -mouseX, mouseY -y)
				
					surface.SetDrawColor(selection_color_box)
					surface.DrawRect(mouseX, y, x -mouseX, mouseY -y)
				end
			else
				if mouseY > y then
					surface.SetDrawColor(selection_color_outline)
					surface.DrawOutlinedRect(x, y, mouseX -x, mouseY -y)
				
					surface.SetDrawColor(selection_color_box)
					surface.DrawRect(x, y, mouseX -x, mouseY -y)
				else
					surface.SetDrawColor(selection_color_outline)
					surface.DrawOutlinedRect(x, mouseY, mouseX -x, y -mouseY)
				
					surface.SetDrawColor(selection_color_box)
					surface.DrawRect(x, mouseY, mouseX -x, y -mouseY)
				end
			end
		end
	end
end

function MakepHelp()
	local frame = vgui.Create( "DFrame" )
	frame:SetSize(ScrW() * 0.6, ScrH() * 0.6)
	frame:SetTitle("Help")
	frame:SetVisible(true)
	frame:SetDraggable(true)
	frame.btnMaxim:SetVisible(false)
	frame.btnMinim:SetVisible(false)
	frame:Center()
	frame.Paint = function(self, w, h)
		draw.RoundedBox(8, 0, 0, w, h, Color(130, 0, 0))
		draw.RoundedBox(4, 2, 2, w - 4, h - 4, Color(60, 0, 0))
	end
	
	local html = vgui.Create("DHTML" , frame)
	html:Dock(FILL)
	html:SetHTML([[
		<html>
		<head>
		<title>ZM MOTD</title>
		<style type="text/css">
		body	{
			background:#1B0503;
			margin-left:10px;
			margin-top:10px;
			text-align: center;
		}
		h	{
			font-family: Arial Black, Arial, Impact, serif;
		}
		#centering {
			font-family: Tahoma, Verdana, Arial, Helvetica, sans-serif;
			color: #FFFFFF;
			width: 80%;
			background-color: #550000;
			margin-left: auto;
			margin-right: auto;
			padding: 20px;
		}
		</style>
		</head>
		<body scroll='no'>
		<div id='centering'>
		<!-- motd goes here -->
		<h2>Zombie Master</h2>
		<h3>Beta 1.X.X</h3>
		<h4>Make sure you bind all new keys in the keyboard config!</h4>
		<p><b>ZM for noobs</b></p>
		<p><i>As Zombie Master</i>: Click on the orbs, spawn zombies, kill humans.</p>
		<p><i>As Human</i>: Get guns, check map objectives (F1), survive and complete objectives.</p>
		<p>www.zombiemaster.org</p>

		</div>
		</body>
		</html>]])

	frame:MakePopup()
end

function MakepCredits()
	local wid = math.min(ScrW(), 750)

	local y = 8

	local frame = vgui.Create("DFrame")
	frame:SetWide(wid)
	frame:SetTitle(" ")
	frame:SetKeyboardInputEnabled(false)
	frame.lblTitle:SetFont("dexfont_med")
	frame.Paint = function(self, w, h)
		draw.RoundedBox(8, 0, 0, w, h, Color(0, 0, 0, 180))
	end

	local label = EasyLabel(frame, GAMEMODE.Name.." Credits", "ZSHUDFontNS", color_white)
	label:AlignTop(y)
	label:CenterHorizontal()
	y = y + label:GetTall() + 8

	for authorindex, authortab in ipairs(GAMEMODE.Credits) do
		local lineleft = EasyLabel(frame, string.Replace(authortab[1], "@", "(at)"), "ZSHUDFontSmallestNS", color_white)
		local linemid = EasyLabel(frame, "-", "ZSHUDFontSmallestNS", color_white)
		local lineright = EasyLabel(frame, authortab[3], "ZSHUDFontSmallestNS", color_white)
		local linesub
		if authortab[2] then
			linesub = EasyURL(frame, authortab[2], "DefaultFont", color_white)
		end

		lineleft:AlignLeft(8)
		lineleft:AlignTop(y)
		lineright:AlignRight(8)
		lineright:AlignTop(y)
		linemid:CenterHorizontal()
		linemid:AlignTop(y)

		y = y + lineleft:GetTall()
		if linesub then
			linesub:AlignTop(y)
			linesub:AlignLeft(8)
			y = y + linesub:GetTall()
		end
		y = y + 10
	end

	frame:SetTall(y + 8)
	frame:Center()
	frame:SetAlpha(0)
	frame:AlphaTo(255, 0.5, 0)
	frame:MakePopup()
end

local pPlayerModel
local function SwitchPlayerModel(self)
	surface.PlaySound("buttons/button14.wav")
	RunConsoleCommand("cl_playermodel", self.m_ModelName)
	chat.AddText(COLOR_LIMEGREEN, "You've changed your desired player model to "..tostring(self.m_ModelName))

	pPlayerModel:Close()
end
function MakepPlayerModel()
	if pPlayerModel and pPlayerModel:Valid() then pPlayerModel:Remove() end
	
	local numcols = 8
	local wid = numcols * 68 + 24
	local hei = 400

	pPlayerModel = vgui.Create("DFrame")
	pPlayerModel:SetSkin("Default")
	pPlayerModel:SetTitle("Player model selection")
	pPlayerModel:SetSize(wid, hei)
	pPlayerModel:Center()
	pPlayerModel:SetDeleteOnClose(true)
	pPlayerModel.btnMaxim:SetVisible(false)
	pPlayerModel.btnMinim:SetVisible(false)
	pPlayerModel.Paint = function(self, w, h)
		draw.RoundedBox(8, 0, 0, w, h, Color(130, 0, 0))
		draw.RoundedBox(4, 2, 2, w - 4, h - 4, Color(60, 0, 0))
	end

	local list = vgui.Create("DPanelList", pPlayerModel)
	list:StretchToParent(8, 24, 8, 8)
	list:EnableVerticalScrollbar()

	local grid = vgui.Create("DGrid", pPlayerModel)
	grid:SetCols(numcols)
	grid:SetColWide(68)
	grid:SetRowHeight(68)
	
	local playermodels = player_manager.AllValidModels()
	playermodels["zombie"] = nil
	playermodels["zombiefast"] = nil
	playermodels["corpse"] = nil
	playermodels["charple"] = nil
	playermodels["skeleton"] = nil
	playermodels["zombine"] = nil
	for name, mdl in pairs(playermodels) do
		if mdl ~= nil then
			local button = vgui.Create("SpawnIcon", grid)
			button:SetPos(0, 0)
			button:SetModel(mdl)
			button.m_ModelName = name
			button.OnMousePressed = SwitchPlayerModel
			grid:AddItem(button)
		end
	end
	grid:SetSize(wid - 16, math.ceil(table.Count(player_manager.AllValidModels()) / numcols) * grid:GetRowHeight())

	list:AddItem(grid)

	pPlayerModel:SetSkin("Default")
	pPlayerModel:MakePopup()
end

function MakepPlayerColor()
	if pPlayerColor and pPlayerColor:Valid() then pPlayerColor:Remove() end

	pPlayerColor = vgui.Create("DFrame")
	pPlayerColor:SetWide(math.min(ScrW(), 500))
	pPlayerColor:SetTitle(" ")
	pPlayerColor:SetDeleteOnClose(true)
	pPlayerColor.btnMaxim:SetVisible(false)
	pPlayerColor.btnMinim:SetVisible(false)
	pPlayerColor.Paint = function(self, w, h)
		draw.RoundedBox(8, 0, 0, w, h, Color(130, 0, 0))
		draw.RoundedBox(4, 2, 2, w - 4, h - 4, Color(60, 0, 0))
	end

	local y = 8

	local label = EasyLabel(pPlayerColor, "Colors", "ZSHUDFont", color_white)
	label:SetPos((pPlayerColor:GetWide() - label:GetWide()) / 2, y)
	y = y + label:GetTall() + 8

	local lab = EasyLabel(pPlayerColor, "Player color")
	lab:SetPos(8, y)
	y = y + lab:GetTall()

	local colpicker = vgui.Create("DColorMixer", pPlayerColor)
	colpicker:SetAlphaBar(false)
	colpicker:SetPalette(false)
	colpicker.UpdateConVars = function(me, color)
		me.NextConVarCheck = SysTime() + 0.2
		RunConsoleCommand("cl_playercolor", color.r / 100 .." ".. color.g / 100 .." ".. color.b / 100)
	end
	local r, g, b = string.match(GetConVarString("cl_playercolor"), "(%g+) (%g+) (%g+)")
	if r then
		colpicker:SetColor(Color(r * 100, g * 100, b * 100))
	end
	colpicker:SetSize(pPlayerColor:GetWide() - 16, 72)
	colpicker:SetPos(8, y)
	y = y + colpicker:GetTall()

	local lab = EasyLabel(pPlayerColor, "Weapon color")
	lab:SetPos(8, y)
	y = y + lab:GetTall()

	local colpicker = vgui.Create("DColorMixer", pPlayerColor)
	colpicker:SetAlphaBar(false)
	colpicker:SetPalette(false)
	colpicker.UpdateConVars = function(me, color)
		me.NextConVarCheck = SysTime() + 0.2
		RunConsoleCommand("cl_weaponcolor", color.r / 100 .." ".. color.g / 100 .." ".. color.b / 100)
	end
	local r, g, b = string.match(GetConVarString("cl_weaponcolor"), "(%g+) (%g+) (%g+)")
	if r then
		colpicker:SetColor(Color(r * 100, g * 100, b * 100))
	end
	colpicker:SetSize(pPlayerColor:GetWide() - 16, 72)
	colpicker:SetPos(8, y)
	y = y + colpicker:GetTall()

	pPlayerColor:SetTall(y + 8)
	pPlayerColor:Center()
	pPlayerColor:MakePopup()
end

local surfacecolor = Color(72, 0, 0)
local outlinecolor = Color(110, 0, 0)
local function DrawZMButton(self, w, h)
	if self:IsHovered() then
		surfacecolor = Color(92, 0, 0)
		outlinecolor = Color(140, 0, 0)
	else
		surfacecolor = Color(72, 0, 0)
		outlinecolor = Color(110, 0, 0)
	end
	draw.RoundedBox(8, 0, 0, w, h, outlinecolor)
	draw.RoundedBox(4, 2, 2, w - 4, h - 4, surfacecolor)
end
function GM:ShowOptions()
	local menu = vgui.Create("Panel")
	menu:SetSize(BetterScreenScale() * 420, ScrH() * 0.35)
	menu:Center()
	menu.Paint = function(self, w, h)
		draw.RoundedBox(8, 0, 0, w, h, Color(150, 0, 0))
		draw.RoundedBox(4, 4, 4, w - 7, h - 7, Color(60, 0, 0))
	end
	menu.Created = SysTime()

	local header = EasyLabel(menu, self.Name, "ZSHUDFont")
	header:SetContentAlignment(8)
	header:DockMargin(0, 10, 0, 64)
	header:Dock(TOP)
	
	local but = vgui.Create("DButton", menu)
	but:SetFont("ZSHUDFontSmaller")
	but:SetText("Help")
	but:SetTall(32)
	but:DockMargin(12, 0, 12, 12)
	but:DockPadding(0, 12, 0, 12)
	but:Dock(TOP)
	but.DoClick = function() MakepHelp() end
	but:SetTextColor(color_white)
	but.Paint = DrawZMButton
	
	local but = vgui.Create("DButton", menu)
	but:SetFont("ZSHUDFontSmaller")
	but:SetText("Player Model")
	but:SetTall(32)
	but:DockMargin(12, 0, 12, 12)
	but:DockPadding(0, 12, 0, 12)
	but:Dock(TOP)
	but.DoClick = function() MakepPlayerModel() end
	but:SetTextColor(color_white)
	but.Paint = DrawZMButton

	local but = vgui.Create("DButton", menu)
	but:SetFont("ZSHUDFontSmaller")
	but:SetText("Player Color")
	but:SetTall(32)
	but:DockMargin(12, 0, 12, 12)
	but:DockPadding(0, 12, 0, 12)
	but:Dock(TOP)
	but.DoClick = function() MakepPlayerColor() end
	but:SetTextColor(color_white)
	but.Paint = DrawZMButton

	local but = vgui.Create("DButton", menu)
	but:SetFont("ZSHUDFontSmaller")
	but:SetText("Credits")
	but:SetTall(32)
	but:DockMargin(12, 0, 12, 12)
	but:DockPadding(0, 12, 0, 12)
	but:Dock(TOP)
	but.DoClick = function() MakepCredits() end
	but:SetTextColor(color_white)
	but.Paint = DrawZMButton

	local but = vgui.Create("DButton", menu)
	but:SetFont("ZSHUDFontSmaller")
	but:SetText("Close")
	but:SetTall(32)
	but:DockMargin(12, 24, 12, 0)
	but:DockPadding(0, 12, 0, 12)
	but:Dock(TOP)
	but.DoClick = function() menu:Remove() end
	but:SetTextColor(color_white)
	but.Paint = DrawZMButton

	menu:MakePopup()
end

function GM:ShowHelp()
	gui.EnableScreenClicker(true)
	
	local frame = vgui.Create("DEXRoundedFrame")
	frame:SetWide(ScrW() * 0.75)
	frame:SetTall(math.min(ScrH() - (ScrH() * 0.1), 900))
	frame:SetTitle(" ")
	frame:SetKeyboardInputEnabled(false)
	frame:SetMouseInputEnabled(true)
	frame:Center()
	frame.Paint = function(self, w, h)
		draw.RoundedBoxEx(8, 0, 64, w, h - 64, Color(5, 5, 5, 180), false, false, true, true)
		draw.RoundedBoxEx(8, 0, 0, w, 64, Color(5, 5, 5, 220), true, true, false, false)
	end
	
	local sprite = vgui.Create("DImage", frame)
	sprite:AlignTop(-5)
	sprite:AlignLeft(5)
	sprite:SetSize(ScrW() * 0.07, ScrH() * 0.07)
	sprite:SetImage("vgui/gfx/vgui/hl2mp_logo")
	
	local pan = vgui.Create("DPanel", frame)
	pan:SetPos(frame:GetWide() * 0.08, frame:GetTall() * 0.08)
	pan:SetSize(frame:GetWide() * 0.85, frame:GetTall() * 0.85)
	pan.Paint = function(self, w, h) 
		draw.RoundedBox(8, 0, 0, w, h, Color(24, 24, 24))
	end
	
	local label = EasyLabel(frame, "Objectives!", "ZSHUDFont", color_white)
	label:AlignLeft(frame:GetWide() * 0.1)
	label:AlignTop(frame:GetTall() * 0.01)
	
	local scroll = vgui.Create("DScrollPanel", pan)
	scroll:SetSize(pan:GetWide() - 5, pan:GetTall() - 5)
	
	local lab = vgui.Create("DLabel", scroll)
	lab:SetFont("ZSHUDFontSmaller")
	lab:AlignTop(8)
	lab:AlignLeft(8)
	lab:SetText(self.MapInfo)
	lab:SizeToContents()
	
	local hoverColor = Color(0, 0, 0)
	local but = vgui.Create("DButton", frame)
	but:SetFont("ZSHUDFontSmaller")
	but:SetText("Okay")
	but:SetTall(frame:GetTall() * 0.05)
	but:SetWide(frame:GetWide() * 0.13)
	but:AlignBottom(frame:GetTall() * 0.012)
	but:AlignRight(frame:GetWide() * 0.062)
	but:SetTextColor(color_white)
	but.DoClick = function()
		if not MySelf:IsZM() then
			gui.EnableScreenClicker(false)
		end
		frame:SetVisible(false)
		sprite:SetVisible(false)
	end
	but.Paint = function(self, w, h) 
		draw.OutlinedBox(0, 0, w, h, 2, Color(46, 46, 46))
		if self:IsHovered() then
			hoverColor = Color(40, 0, 0, 200)
		else
			hoverColor = Color(30, 30, 30, 80)
		end
		surface.SetDrawColor(hoverColor)
		surface.DrawRect(2, 2, w - 3, h - 3)
	end
	
	self.objmenu = frame
	self.objmenuimage = sprite
end

function GM:MakePreferredMenu()
	if GetConVar("zm_nopreferredmenu"):GetBool() then return end
	
	gui.EnableScreenClicker(true)
	
	local frame = vgui.Create("DFrame")
	frame:SetWide(326.4)
	frame:SetTall(345)
	frame:SetTitle(" ")
	frame:SetKeyboardInputEnabled(false)
	frame:SetMouseInputEnabled(true)
	frame:AlignTop(20)
	frame:AlignLeft(20)
	frame.Close = function(self)
		if not MySelf:IsZM() then
			gui.EnableScreenClicker(false)
		end
		self:Remove()
	end
	frame.Paint = function(self)
		draw.RoundedBox(8, 0, 0, self:GetWide(), self:GetTall(), Color(60, 0, 0, 200))
	end
	
	local label = vgui.Create("DLabel", frame)
	label:AlignTop(45)
	label:SetFont("ZSHUDFontSmaller")
	label:SetText("Choose your playstyle.")
	label:SetTextColor(color_white)
	label:SizeToContents()
	label:CenterHorizontal()
	
	local but = vgui.Create("DButton", frame)
	but:AlignTop(95)
	but:SetWide(250)
	but:SetTall(30)
	but:SetText("Willing to be the Zombie Master (RTS).")
	but:CenterHorizontal()
	but:SetTextColor(color_white)
	but.DoClick = function(self)
		RunConsoleCommand("zm_preference", 1)
		surface.PlaySound("buttons/combine_button1.wav")
		frame:Close()
	end
	but.Paint = function(self)
		if self:IsHovered() then
			col = Color(145, 0, 0)
			col2 = Color(95, 0, 0)
		else
			col = Color(89, 0, 0)
			col2 = Color(52, 0, 0)
		end
		draw.RoundedBox(0, 0, 0, w, h, col)
		draw.RoundedBox(0, 2, 2, w - 4, h - 4, col2)
	end
	
	local but = vgui.Create("DButton", frame)
	but:AlignTop(165)
	but:SetWide(250)
	but:SetTall(30)
	but:SetText("Prefer being a Survivor (FPS).")
	but:CenterHorizontal()
	but:SetTextColor(color_white)
	but.DoClick = function(self)
		RunConsoleCommand("zm_preference", 0)
		surface.PlaySound("buttons/combine_button1.wav")
		frame:Close()
	end
	but.Paint = function(self)
		if self:IsHovered() then
			col = Color(145, 0, 0)
			col2 = Color(95, 0, 0)
		else
			col = Color(89, 0, 0)
			col2 = Color(52, 0, 0)
		end
		draw.RoundedBox(0, 0, 0, w, h, col)
		draw.RoundedBox(0, 2, 2, w - 4, h - 4, col2)
	end
	
	local check = vgui.Create("DCheckBoxLabel", frame)
	check:AlignTop(270)
	check:CenterHorizontal()
	check:SetText("Don't ask again.")
	check:SetConVar("zm_nopreferredmenu")
	check:SetTextColor(color_white)
	check:SizeToContents()
end

local boxColor = Color(115, 0, 0)
local surfaceColor = Color(52, 0, 0, 250)
local function trapMenuPaint(self, w, h)
	if not self.bActive then
		boxColor = Color(58, 0, 0)
		surfaceColor = Color(26, 0, 0, 250)
	elseif self:IsHovered() then
		boxColor = Color(173, 0, 0)
		surfaceColor = Color(78, 0, 0, 250)
	else
		boxColor = Color(115, 0, 0)
		surfaceColor = Color(52, 0, 0, 250)
	end
	
	draw.OutlinedBox(0, 0, w, h, 2, boxColor)
	surface.SetDrawColor(surfaceColor)
	surface.DrawRect(2, 2, w - 3, h - 3)
end
function GM:SpawnTrapMenu(class, ent)
	if class == "info_manipulate" and ent:GetActive() then
		if IsValid(self.trapMenu) then
			self.trapMenu:Remove()
		end
		
		if trapEntity then
			trapEntity:Remove()
			trapEntity = nil
		end
		
		local description = ent:GetDescription()
		local trapPanel = vgui.Create("DEXRoundedFrame")
		trapPanel:SetWide(326.4)
		trapPanel:SetTall(345)
		trapPanel:SetTitle("Manipulate")
		trapPanel:SetKeyboardInputEnabled(false)
		trapPanel:SetMouseInputEnabled(true)
		trapPanel:AlignTop(10)
		trapPanel:AlignLeft(20)
		trapPanel:SetColor(Color(60, 0, 0, 200))
		trapPanel.PerformLayout = function(self)
			self.lblTitle:SetWide(self:GetWide() - 25)
			self.lblTitle:SetPos(12, 8)
		end
		
		trapPanel.lblTitle:SetFont("ZSHUDFontSmallest")
			
		trapPanel.Close = function(self)
			self:SetVisible(false)
			trapPanel = nil
				
			isDragging = false
			holdTime = CurTime()
		end
		
		local description = vgui.Create("DLabel", trapPanel)
		description:AlignLeft(trapPanel:GetWide() * 0.12)
		description:AlignTop(trapPanel:GetTall() * 0.2)
		description:SetText(ent:GetDescription())
		description:SizeToContents()
		
		local cost = ent:GetCost()
		local activate = vgui.Create("DButton", trapPanel)
		activate:AlignLeft(trapPanel:GetWide() * 0.12)
		activate:AlignTop(trapPanel:GetTall() * 0.3)
		activate:SetTall(32)
		activate:SetWide(250)
		activate:SetTextColor(color_white)
		activate:SetText("Activate for "..cost)
		activate:SetEnabled(true)
		activate.bActive = true
		activate.Paint = trapMenuPaint
		activate.Think = function(self)
			self.BaseClass.Think(self)
			
			if not MySelf:CanAfford(cost) then
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
		activate.DoClick = function(self)
			isDragging = false
			holdTime = CurTime()
			
			if MySelf:CanAfford(cost) then
				RunConsoleCommand("zm_clicktrap", ent:EntIndex())
				trapPanel:Close()
			end
		end
		
		local trapCost = ent:GetTrapCost()
		local setTrigger = vgui.Create("DButton", trapPanel)
		setTrigger:AlignLeft(trapPanel:GetWide() * 0.12)
		setTrigger:AlignTop(trapPanel:GetTall() * 0.45)
		setTrigger:SetTall(32)
		setTrigger:SetWide(250)
		setTrigger:SetTextColor(color_white)
		setTrigger:SetText("Create trap for "..trapCost)
		setTrigger:SetEnabled(true)
		setTrigger.bActive = true
		setTrigger.Paint = trapMenuPaint
		setTrigger.Think = function(self)
			self.BaseClass.Think(self)
			
			if not MySelf:CanAfford(trapCost) then
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
		setTrigger.DoClick = function(self)
			isDragging = false
			holdTime = CurTime()
			
			if MySelf:CanAfford(trapCost) then
				gamemode.Call("CreateGhostEntity", true, ent:EntIndex())
				
				trapTrigger = ent:EntIndex()
				
				trapPanel:Close()
			end
		end
		
		local cancel = vgui.Create("DButton", trapPanel)
		cancel:AlignLeft(trapPanel:GetWide() * 0.12)
		cancel:AlignTop(trapPanel:GetTall() * 0.85)
		cancel:SetTall(32)
		cancel:SetWide(250)
		cancel:SetTextColor(color_white)
		cancel:SetText("Cancel")
		cancel.bActive = true
		cancel.Paint = trapMenuPaint
		cancel.DoClick = function(self)
			isDragging = false
			holdTime = CurTime()
			
			trapPanel:Close()
		end
		
		self.trapMenu = trapPanel
	elseif class == "info_zombiespawn" and ent:GetActive() then
		local data = gamemode.Call("GetZombieMenus")
		local menu = data[ent]
		
		if not IsValid(menu) then
			local zombieFlags = ent:GetZombieFlags() or 0
			
			local newMenu = vgui.Create("zm_zombiemenu")
			newMenu:SetZombieflags(zombieFlags)
			newMenu:SetTitle("Spawn Menu")
			newMenu:SetCurrent(ent:EntIndex())
			newMenu:Populate()
			newMenu:AlignTop(10)
			newMenu:AlignLeft(10)
			newMenu:SetVisible(true)
			newMenu:ShowCloseButton(false)
			
			trapTrigger = ent:EntIndex()
			
			data[ent] = newMenu
		else
			menu:SetVisible(true)
		end
	end
end