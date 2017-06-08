surface.CreateFont("OptionsHelp", {font = "Consolas", size = 20, weight = 450})
surface.CreateFont("OptionsHelpBig", {font = "Consolas", size = 22, weight = 450})

function GM:HUDPaint()
	if player_manager.RunClass(LocalPlayer(), "DrawHUD") then return end
	
	if not self:GetRoundActive() then
		local h, w = ScrH(), ScrW()
		if not self:GetZMSelection() then
			draw.SimpleText(translate.Get("waiting_on_players"), "zm_hud_font_small", w * 0.5, h * 0.25, Color(150, 0, 0), TEXT_ALIGN_CENTER)
		else
			draw.SimpleText(translate.Get("players_ready"), "zm_hud_font_small", w * 0.5, h * 0.25, Color(0, 150, 0), TEXT_ALIGN_CENTER)
		end
	end
	
	hook.Call( "HUDDrawTargetID", self )
	hook.Call( "HUDDrawPickupHistory", self )
	hook.Call( "DrawDeathNotice", self, 0.85, 0.04 )
end

function GM:HUDShouldDraw(name)
	return name ~= "CHudHealth" and name ~= "CHudBattery" and name ~= "CHudAmmo" and name ~= "CHudSecondaryAmmo"
end

local defaultHelpStr = [[
	<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/1999/REC-html401-19991224/loose.dtd">
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
	<body scroll="no">
	<div id="centering">
	<!-- motd goes here -->
	<h2>Zombie Master</h2>
	<h3>Beta 1.X.X</h3>
	<h4>Make sure you bind all new keys in the keyboard config!</h4>
	<p><b>ZM for noobs</b></p>
	<p><i>As Zombie Master</i>: Click on the orbs, spawn zombies, kill humans.</p>
	<p><i>As Human</i>: Get guns, check map objectives (key in keyconfig), survive and complete objectives.</p>
	<p>www.zombiemaster.org</p>

	</div>
	</body>
	</html>
]]
function MakepHelp()
	local frame = vgui.Create( "DFrame" )
	frame:SetSize(ScrW() * 0.6, ScrH() * 0.6)
	frame:SetTitle("Help")
	frame:SetVisible(true)
	frame:SetDraggable(true)
	frame.btnMaxim:SetVisible(false)
	frame.btnMinim:SetVisible(false)
	frame:Center()
	frame.OnClose = function(self)
		if not IsValid(self.OptionsMenu) then
			GAMEMODE:ShowOptions()
		end
	end
	
	local html = vgui.Create("DHTML", frame)
	html:Dock(FILL)
	html:SetHTML(Either(GAMEMODE.HelpInfo == "No Info", defaultHelpStr, GAMEMODE.HelpInfo))

	frame:MakePopup()
end

function MakepCredits()
	local wid = math.min(ScrW(), 750)
	local frame = vgui.Create("DFrame")
	frame:SetWide(wid)
	frame:SetTitle("")
	frame:SetKeyboardInputEnabled(false)
	frame.btnMinim:SetVisible(false)
	frame.btnMaxim:SetVisible(false)
	
	frame.OnClose = function(self)
		if not IsValid(self.OptionsMenu) then
			GAMEMODE:ShowOptions()
		end
	end

	local label = Label(GAMEMODE.Name.." Credits", frame)
	label:SetFont("zm_hud_font_normal")
	label:SizeToContents()
	label:AlignTop(8)
	label:CenterHorizontal()
	
	local creditslist = vgui.Create("Panel", frame)
	creditslist:SetWide(wid * 0.99)
	creditslist:MoveBelow(label)
	creditslist:CenterHorizontal()

	local alphatime = 0.2
	for authorindex, authortab in ipairs(GAMEMODE.Credits) do
		local base = vgui.Create("Panel", creditslist)
		base:SetWide(creditslist:GetWide())
		base:Dock(TOP)
		base:DockMargin(0, 4, 0, 4)
		base:DockPadding(0, 4, 0, 4)
		
		local avatar = vgui.Create("AvatarImage", base)
		if authortab.SteamID ~= "" then
			avatar:SetMouseInputEnabled(true)
			avatar:SetKeyboardInputEnabled(true)
			avatar:SetCursor("hand")
			avatar.OnMousePressed = function(self, code) if code == MOUSE_FIRST then gui.OpenURL("http://steamcommunity.com/profiles/"..util.SteamIDTo64(authortab.SteamID)) end end
		end
		
		local lineleft = Label(string.Replace(authortab.Name, "@", "(at)"), base)
		local linemid = Label("-", base)
		local lineright = Label(authortab.Description, base)
		
		local linesub
		if authortab.Website then
			linesub = vgui.Create("DLabelURL", base)
			linesub:SetText(authortab.Website)
			linesub:SetURL(authortab.Website)
			linesub:SizeToContents()
		end
		
		avatar:SetSize(32, 32)
		avatar:SetSteamID(util.SteamIDTo64(authortab.SteamID), 32)
		lineleft:SetFont("OptionsHelp")
		lineleft:SizeToContents()
		lineright:SetFont("OptionsHelp")
		lineright:SizeToContents()
		linemid:SetFont("OptionsHelp")
		linemid:SizeToContents()
		
		avatar:SetAlpha(0)
		lineleft:SetAlpha(0)
		lineright:SetAlpha(0)
		linemid:SetAlpha(0)
		avatar:AlphaTo(255, alphatime)
		lineleft:AlphaTo(255, alphatime)
		lineright:AlphaTo(255, alphatime)
		linemid:AlphaTo(255, alphatime)

		avatar:AlignLeft(8)
		lineleft:AlignLeft(48)
		lineright:AlignRight(8)
		linemid:CenterHorizontal()

		if linesub then
			linesub:AlignLeft(48)
			linesub:MoveBelow(lineleft)
			linesub:SetAlpha(0)
			linesub:AlphaTo(255, alphatime)
		end
		
		base:InvalidateLayout(true)
		base:SizeToChildren(false, true)
		
		alphatime = alphatime + 0.1
	end

	creditslist:InvalidateLayout(true)
	creditslist:SizeToChildren(false, true)
	
	frame:InvalidateLayout(true)
	frame:SizeToChildren(false, true)
	frame:Center()
	frame:SetAlpha(0)
	frame:AlphaTo(255, 0.5, 0)
	frame:MakePopup()
end

local function BinderTextUpdate(self)
	local str = input.GetKeyName(self.m_iSelectedNumber)
	if not str then str = "NONE" end

	str = language.GetPhrase(str)

	self:SetText(string.upper(str))
end
function MakepOptions()
	if pOptions then
		pOptions:SetAlpha(0)
		pOptions:AlphaTo(255, 0.5, 0)
		pOptions:SetVisible(true)
		pOptions:MakePopup()
		return
	end

	local Window = vgui.Create("DFrame")
	local wide = math.min(ScrW(), 500)
	local tall = math.min(ScrH(), 580)
	Window:SetSize(wide, tall)
	Window:Center()
	Window:SetTitle(" ")
	Window:SetDeleteOnClose(false)
	Window.btnMinim:SetVisible(false)
	Window.btnMaxim:SetVisible(false)
	
	Window.OnClose = function(self)
		if LocalPlayer().HadMenuOpen and not IsValid(self.OptionsMenu) then
			GAMEMODE:ShowOptions()
		end
	end
	
	pOptions = Window
	
	local header = Label("Options", Window)
	header:SetFont("zm_hud_font_normal")
	header:SizeToContents()
	header:CenterHorizontal()
	header:AlignTop(8)
	
	local list = vgui.Create("DScrollPanel", pOptions)
	list:MoveBelow(header, 8)
	list:SetSize(wide - 24, tall - 12)
	list:SetPadding(8)
	list:CenterHorizontal()

	hook.Call("AddExtraOptions", GAMEMODE, list, Window)
	
	local catagory = vgui.Create("DCollapsibleCategory", list)
	catagory:SetSize(64, 64)
	catagory:Dock(TOP)
	catagory:DockMargin(0, 0, 0, 8)
	catagory:SetExpanded(0)
	catagory:SetLabel("Volunteer Settings")
	
	local catagorylist = vgui.Create("DScrollPanel", list)
	catagory:SetContents(catagorylist)
	
	local check = vgui.Create("DCheckBoxLabel")
	check:SetText("Don't show volunteer menu")
	check:SetConVar("zm_nopreferredmenu")
	check:SizeToContents()
	check:Dock(TOP)
	check:DockMargin(0, 8, 0, 4)
	catagorylist:AddItem(check)	
	
	local but = vgui.Create("DButton")
	but:SetTall(24)
	but:SetFont("OptionsHelpBig")
	but:SetText("Open Volunteer Menu")
	but:Dock(TOP)
	but:DockMargin(0, 8, 0, 4)
	but.DoClick = function()
		RunConsoleCommand("zm_open_preferred_menu")
	end
	catagorylist:AddItem(but)
	
	local catagory = vgui.Create("DCollapsibleCategory", list)
	catagory:SetSize(64, 64)
	catagory:Dock(TOP)
	catagory:DockMargin(0, 0, 0, 8)
	catagory:SetExpanded(0)
	catagory:SetLabel("Key Binds")
	
	local catagorylist = vgui.Create("DScrollPanel", list)
	catagory:SetContents(catagorylist)
	
	local label = Label("Drop Weapon Key", list)
	label:SetFont("OptionsHelp")
	label:SizeToContents()
	label:Dock(TOP)
	label:DockMargin(0, 8, 0, 4)
	catagorylist:AddItem(label)	
	
	local binder = vgui.Create("DBinder", list)
	binder:SetTall(24)
	binder:SetFont("OptionsHelpBig")
	binder:SetConVar("zm_dropweaponkey")
	binder:SizeToContents()
	binder.UpdateText = BinderTextUpdate
	binder:Dock(TOP)
	binder:DockMargin(0, 8, 0, 4)
	catagorylist:AddItem(binder)	
	
	local label = Label("Drop Ammo Key", list)
	label:SetFont("OptionsHelp")
	label:SizeToContents()
	label:Dock(TOP)
	label:DockMargin(0, 8, 0, 4)
	catagorylist:AddItem(label)	
	
	local binder = vgui.Create("DBinder", list)
	binder:SetTall(24)
	binder:SetFont("OptionsHelpBig")
	binder:SetConVar("zm_dropammokey")
	binder:SizeToContents()
	binder.UpdateText = BinderTextUpdate
	binder:Dock(TOP)
	binder:DockMargin(0, 8, 0, 4)
	catagorylist:AddItem(binder)	
	
	local catagory = vgui.Create("DCollapsibleCategory", list)
	catagory:SetSize(64, 64)
	catagory:Dock(TOP)
	catagory:DockMargin(0, 0, 0, 8)
	catagory:SetExpanded(0)
	catagory:SetLabel("Ragdoll Settings")
	
	local catagorylist = vgui.Create("DScrollPanel", list)
	catagory:SetContents(catagorylist)
	
	local check = vgui.Create("DCheckBoxLabel", list)
	check:SetText("Should ragdolls fadeout")
	check:SetConVar("zm_shouldragdollsfade")
	check:SizeToContents()
	check:Dock(TOP)
	check:DockMargin(0, 8, 0, 4)
	catagorylist:AddItem(check)
	
	local slider = vgui.Create("DNumSlider", list)
	slider:SetDecimals(0)
	slider:SetMinMax(1, 1000)
	slider:SetConVar("g_ragdoll_fadespeed")
	slider:SetText("Fade Speed")
	slider:SizeToContents()
	slider:Dock(TOP)
	slider:DockMargin(0, 8, 0, 4)
	catagorylist:AddItem(slider)
	
	local slider = vgui.Create("DNumSlider", list)
	slider:SetDecimals(0)
	slider:SetMinMax(1, 300)
	slider:SetConVar("zm_cl_ragdoll_fadetime")
	slider:SetText("Time before fadeout")
	slider:SizeToContents()
	slider:Dock(TOP)
	slider:DockMargin(0, 8, 0, 4)
	catagorylist:AddItem(slider)

	Window:SetAlpha(0)
	Window:AlphaTo(255, 0.5, 0)
	Window:MakePopup()
end

function GM:ShowOptions()
	if self.OptionsMenu and self.OptionsMenu:Valid() then
		self.OptionsMenu:Remove()
	end
	
	local menu = vgui.Create("DPanel")
	menu:SetSize(420, ScrH() * 0.35)
	menu:Center()
	
	LocalPlayer().HadMenuOpen = true

	local header = Label(self.Name, menu)
	header:SetFont("zm_hud_font_normal")
	header:SizeToContents()
	header:SetContentAlignment(8)
	header:DockMargin(0, 12, 0, 24)
	header:Dock(TOP)
	
	local but = vgui.Create("DButton", menu)
	but:SetFont("OptionsHelpBig")
	but:SetText(translate.Get("button_help"))
	but:SetTall(32)
	but:DockMargin(12, 0, 12, 12)
	but:DockPadding(0, 12, 0, 12)
	but:Dock(TOP)
	but.DoClick = function() MakepHelp() menu:Remove() end
	
	local but = vgui.Create("DButton", menu)
	but:SetFont("OptionsHelpBig")
	but:SetText(translate.Get("button_playermodel"))
	but:SetTall(32)
	but:DockMargin(12, 0, 12, 12)
	but:DockPadding(0, 12, 0, 12)
	but:Dock(TOP)
	but.DoClick = function() RunConsoleCommand("playermodel_selector") end
	
	local but = vgui.Create("DButton", menu)
	but:SetFont("OptionsHelpBig")
	but:SetText(translate.Get("button_options"))
	but:SetTall(32)
	but:DockMargin(12, 0, 12, 12)
	but:DockPadding(0, 12, 0, 12)
	but:Dock(TOP)
	but.DoClick = function() MakepOptions() menu:Remove() end

	local but = vgui.Create("DButton", menu)
	but:SetFont("OptionsHelpBig")
	but:SetText(translate.Get("button_credits"))
	but:SetTall(32)
	but:DockMargin(12, 0, 12, 12)
	but:DockPadding(0, 12, 0, 12)
	but:Dock(TOP)
	but.DoClick = function() MakepCredits() menu:Remove() end

	local but = vgui.Create("DButton", menu)
	but:SetFont("OptionsHelpBig")
	but:SetText(translate.Get("button_close"))
	but:SetTall(32)
	but:DockMargin(12, 24, 12, 0)
	but:DockPadding(0, 12, 0, 12)
	but:Dock(TOP)
	but.DoClick = function() gui.EnableScreenClicker(false) menu:Remove() LocalPlayer().HadMenuOpen = false end

	menu:InvalidateLayout(true)
	menu:SizeToChildren(false, true)
	menu:SetSize(menu:GetWide(), menu:GetTall() + 12)
	menu:MakePopup()
	
	self.OptionsMenu = menu
end

function GM:ShowHelp()
	if IsValid(self.objmenu) then
		self.objmenu:SetVisible(not self.objmenu:IsVisible())
		self.objmenuimage:SetVisible(not self.objmenuimage:IsVisible())
		
		if self.objmenu:IsVisible() then
			gui.EnableScreenClicker(true)
		else
			gui.EnableScreenClicker(false)
		end
		
		return
	end
	
	gui.EnableScreenClicker(true)
	
	local frame = vgui.Create("DPanel")
	frame:SetWide(ScrW() * 0.75)
	frame:SetTall(math.min(ScrH() - (ScrH() * 0.1), 900))
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
	
	local label = Label(translate.Get("title_objectives"), frame)
	label:SetFont("zm_hud_font_normal")
	label:SizeToContents()
	label:AlignLeft(frame:GetWide() * 0.1)
	label:AlignTop(frame:GetTall() * 0.01)
	
	local scroll = vgui.Create("DScrollPanel", pan)
	scroll:SetSize(pan:GetWide() - 5, pan:GetTall() - 5)
	
	local lab = vgui.Create("DLabel", scroll)
	lab:SetSize(scroll:GetSize())
	lab:SetFont("OptionsHelpBig")
	lab:AlignTop(8)
	lab:AlignLeft(8)
	lab:SetText(self.MapInfo)
	lab:SetWrap(true)
	lab:SetAutoStretchVertical(true)
	
	local hoverColor = Color(0, 0, 0)
	local but = vgui.Create("DButton", frame)
	but:SetFont("OptionsHelpBig")
	but:SetText(translate.Get("button_okay"))
	but:SetTall(frame:GetTall() * 0.05)
	but:SetWide(frame:GetWide() * 0.13)
	but:AlignBottom(frame:GetTall() * 0.012)
	but:AlignRight(frame:GetWide() * 0.062)
	but.DoClick = function()
		if not LocalPlayer():IsZM() then
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
	timer.Simple(0, function() gui.EnableScreenClicker(true) end)
	
	local frame = vgui.Create("DFrame")
	frame:SetWide(326.4)
	frame:SetTall(345)
	frame:SetTitle(" ")
	frame:AlignTop(20)
	frame:AlignLeft(20)
	frame.btnMinim:SetVisible(false)
	frame.btnMaxim:SetVisible(false)
	
	frame.Close = function(self)
		if not LocalPlayer():IsZM() then
			gui.EnableScreenClicker(false)
		end
		self:Remove()
	end
	
	local label = vgui.Create("DLabel", frame)
	label:AlignTop(45)
	label:SetFont("OptionsHelpBig")
	label:SetText(translate.Get("preferred_playstyle"))
	label:SetTextColor(color_white)
	label:SizeToContents()
	label:CenterHorizontal()
	
	local pan = vgui.Create("Panel", frame)
	pan:MoveBelow(label, 10)
	pan:SetSize(frame:GetWide() * 0.85, frame:GetTall() * 0.5)
	pan:Center()
	
	local but = vgui.Create("DButton", pan)
	but:Dock(TOP)
	but:DockMargin(0, 4, 0, 4)
	but:DockPadding(0, 4, 0, 4)
	but:SetWide(250)
	but:SetTall(30)
	but:SetText(translate.Get("preferred_willing_zm"))
	but:CenterHorizontal()
	but.DoClick = function(self)
		RunConsoleCommand("zm_preference", 1)
		surface.PlaySound("buttons/combine_button1.wav")
		frame:Close()
	end
	
	local but = vgui.Create("DButton", pan)
	but:Dock(TOP)
	but:DockMargin(0, 4, 0, 4)
	but:DockPadding(0, 4, 0, 4)
	but:SetWide(250)
	but:SetTall(30)
	but:SetText(translate.Get("preferred_prefer_survivor"))
	but:CenterHorizontal()
	but.DoClick = function(self)
		RunConsoleCommand("zm_preference", 0)
		surface.PlaySound("buttons/combine_button1.wav")
		frame:Close()
	end
	
	local but = vgui.Create("DButton", pan)
	but:Dock(TOP)
	but:DockMargin(0, 4, 0, 4)
	but:DockPadding(0, 4, 0, 4)
	but:SetWide(250)
	but:SetTall(30)
	but:SetText(translate.Get("preferred_prefer_spectator"))
	but:CenterHorizontal()
	but.DoClick = function(self)
		RunConsoleCommand("zm_preference", 2)
		surface.PlaySound("buttons/combine_button1.wav")
		frame:Close()
	end
	
	local check = vgui.Create("DCheckBoxLabel", frame)
	check:AlignBottom(25)
	check:CenterHorizontal()
	check:SetText(translate.Get("preferred_dont_ask"))
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
		local trapPanel = vgui.Create("DFrame")
		trapPanel:SetWide(326.4)
		trapPanel:SetTall(345)
		trapPanel:SetTitle("Manipulate")
		trapPanel:SetKeyboardInputEnabled(false)
		trapPanel:SetMouseInputEnabled(true)
		trapPanel:AlignTop(10)
		trapPanel:AlignLeft(20)
		trapPanel.btnMinim:SetVisible(false)
		trapPanel.btnMaxim:SetVisible(false)
		trapPanel.btnClose:SetVisible(false)
		trapPanel.PerformLayout = function(self)
			self.lblTitle:SetWide(self:GetWide() - 25)
			self.lblTitle:SetPos(12, 8)
		end
		
		trapPanel.lblTitle:SetFont("OptionsHelp")
			
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
		activate:SetText(translate.Format("trap_activate_for_x", cost))
		activate:SetEnabled(true)
		activate.bActive = true
		activate.Paint = trapMenuPaint
		activate.Think = function(self)
			self.BaseClass.Think(self)
			
			if not LocalPlayer():CanAfford(cost) then
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
			
			if LocalPlayer():CanAfford(cost) then
				net.Start("zm_clicktrap")
					net.WriteEntity(ent)
				net.SendToServer()
				
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
		setTrigger:SetText(translate.Format("trap_create_for_x", trapCost))
		setTrigger:SetEnabled(true)
		setTrigger.bActive = true
		setTrigger.Paint = trapMenuPaint
		setTrigger.Think = function(self)
			self.BaseClass.Think(self)
			
			if not LocalPlayer():CanAfford(trapCost) then
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
			
			if LocalPlayer():CanAfford(trapCost) then
				hook.Call("SetPlacingTrapEntity", GAMEMODE, true, ent)
				trapPanel:Close()
			end
		end
		
		local cancel = vgui.Create("DButton", trapPanel)
		cancel:AlignLeft(trapPanel:GetWide() * 0.12)
		cancel:AlignTop(trapPanel:GetTall() * 0.85)
		cancel:SetTall(32)
		cancel:SetWide(250)
		cancel:SetTextColor(color_white)
		cancel:SetText(translate.Get("button_cancel"))
		cancel.bActive = true
		cancel.Paint = trapMenuPaint
		cancel.DoClick = function(self)
			isDragging = false
			holdTime = CurTime()
			
			trapPanel:Close()
		end
		
		self.trapMenu = trapPanel
	elseif class == "info_zombiespawn" and ent:GetActive() then
		local data = hook.Call("GetZombieMenus", self)
		local menu = data[ent]
		
		if not IsValid(menu) then
			local zombieFlags = ent:GetZombieFlags() or 0
			
			local newMenu = vgui.Create("zm_zombiemenu")
			newMenu:SetZombieflags(zombieFlags)
			newMenu:SetTitle(translate.Get("title_spawn_menu"))
			newMenu:SetCurrent(ent)
			newMenu:Populate()
			newMenu:AlignTop(10)
			newMenu:AlignLeft(10)
			newMenu:SetVisible(true)
			newMenu:ShowCloseButton(false)
			
			TriggerEnt = ent
			
			data[ent] = newMenu
		else
			menu:SetVisible(true)
		end
	end
end

function GM:HUDDrawPickupHistory()
	if self.PickupHistory == nil then return end
	
	local x, y = ScrW() - self.PickupHistoryWide - 20, self.PickupHistoryTop
	local tall = 0
	local wide = 0

	for k, v in pairs(self.PickupHistory) do
		if not istable(v) then
			Msg(tostring(v) .."\n")
			PrintTable(self.PickupHistory)
			self.PickupHistory[ k ] = nil
			return
		end
	
		if v.time < CurTime() then
			if v.y == nil then v.y = y end
			
			v.y = (v.y * 5 + y) / 6
			
			local delta = (v.time + v.holdtime) - CurTime()
			delta = delta / v.holdtime
			
			local alpha = 255
			local colordelta = math.Clamp(delta, 0.6, 0.7)
			
			-- Fade in/out
			if (delta > 1 - v.fadein) then
				alpha = math.Clamp((1.0 - delta) * (255 / v.fadein) , 0, 255)
			elseif delta < v.fadeout then
				alpha = math.Clamp(delta * ( 255 / v.fadeout ), 0, 255)
			end
			
			v.x = x + self.PickupHistoryWide - (self.PickupHistoryWide * (alpha / 255))

			local rx, ry, rw, rh = math.Round(v.x - 4), math.Round(v.y - (v.height / 2) - 4), math.Round(self.PickupHistoryWide + 9), math.Round(v.height + 8)
			local bordersize = 8
			
			surface.SetTexture(self.PickupHistoryCorner)
			
			surface.SetDrawColor(255, 0, 0, alpha)
			surface.DrawTexturedRectRotated(rx + bordersize/2, ry + bordersize / 2, bordersize, bordersize, 0)
			surface.DrawTexturedRectRotated(rx + bordersize/2, ry + rh -bordersize / 2, bordersize, bordersize, 90)
			surface.DrawRect(rx, ry + bordersize, bordersize, rh - bordersize * 2)
			surface.DrawRect(rx + bordersize, ry, v.height - 4, rh)
			
			surface.SetDrawColor(150 * colordelta, 0, 0, alpha)
			surface.DrawRect(rx + bordersize + v.height - 4, ry, rw - (v.height - 4) - bordersize * 2, rh)
			surface.DrawTexturedRectRotated(rx + rw - bordersize / 2 , ry + rh - bordersize / 2, bordersize, bordersize, 180)
			surface.DrawTexturedRectRotated(rx + rw - bordersize / 2 , ry + bordersize / 2, bordersize, bordersize, 270)
			surface.DrawRect(rx + rw-bordersize, ry + bordersize, bordersize, rh-bordersize * 2)
			
			draw.SimpleText(v.name, v.font, v.x + v.height + 9, v.y - (v.height / 2) + 1, Color(0, 0, 0, alpha * 0.5))
	
			draw.SimpleText(v.name, v.font, v.x + v.height + 8, v.y - (v.height / 2), Color(255, 255, 255, alpha))
			
			if v.amount then
				draw.SimpleText(v.amount, v.font, v.x + self.PickupHistoryWide + 1, v.y - (v.height / 2) + 1, Color(0, 0, 0, alpha * 0.5), TEXT_ALIGN_RIGHT)
				draw.SimpleText(v.amount, v.font, v.x + self.PickupHistoryWide, v.y - (v.height / 2), Color(255, 255, 255, alpha), TEXT_ALIGN_RIGHT)
			end
			
			y = y + (v.height + 16)
			tall = tall + v.height + 18
			wide = math.Max(wide, v.width + v.height + 24)
			
			if alpha == 0 then self.PickupHistory[ k ] = nil end
		end
	end
	
	self.PickupHistoryTop = (self.PickupHistoryTop * 5 + (ScrH() * 0.75 - tall ) / 2) / 6
	self.PickupHistoryWide = (self.PickupHistoryWide * 5 + wide) / 6
end