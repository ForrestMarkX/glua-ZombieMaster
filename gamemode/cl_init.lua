include("shared.lua")
include("cl_killicons.lua")
include("cl_utility.lua")
include("cl_scoreboard.lua")
include("cl_dermaskin.lua")
include("cl_entites.lua")

include("cl_zm_options.lua")
include("cl_targetid.lua")
include("cl_hud.lua")
include("cl_zombie.lua")

include("vgui/dpingmeter.lua")
include("vgui/dteamcounter.lua")
include("vgui/dteamheading.lua")
include("vgui/dzombiepanel.lua")
include("vgui/dpowerpanel.lua")

include("vgui/dexnotificationslist.lua")
include("vgui/dexroundedframe.lua")

local circleMaterial 	   = Material("SGM/playercircle")
local healthcircleMaterial = Material("effects/zm_healthring")
local healtheffect		   = Material("effects/yellowflare")
local gradient 		 = surface.GetTextureID("gui/gradient")
local gradient_up	 = surface.GetTextureID("gui/gradient_up")
local gradient_down	 = surface.GetTextureID("gui/gradient_down")

local zombieMenu	  = nil

mouseX, mouseY  = 0, 0
traceX, traceY  = 0, 0
isDragging 	    = false
holdTime 	    = CurTime()

local nightVision_ColorMod = {
	["$pp_colour_addr"] 		= -1,
	["$pp_colour_addg"] 		= -0.35,
	["$pp_colour_addb"] 		= -1,
	["$pp_colour_brightness"] 	= 0.8,
	["$pp_colour_contrast"]		= 1.1,
	["$pp_colour_colour"] 		= 0,
	["$pp_colour_mulr"] 		= 0 ,
	["$pp_colour_mulg"] 		= 0.028,
	["$pp_colour_mulb"] 		= 0
}

local function TraceLongDistance(vector, nocollideall)
	return util.TraceLine({start = LocalPlayer():GetShootPos(), endpos = LocalPlayer():GetShootPos() + (vector * 56756), filter = nocollideall and ents.GetAll() or LocalPlayer()})
end

local function TraceLongDistanceFilter(vector, filter)
	return util.TraceLine({start = LocalPlayer():GetShootPos(), endpos = LocalPlayer():GetShootPos() + (vector * 56756), filter = filter})
end

function GM:PostClientInit()
	RunConsoleCommand("zm_player_ready")
end

function GM:OnReloaded()
	hook.Call("BuildZombieDataTable", self)
end

function GM:InitPostEntity()
	hook.Call("PostClientInit", self)
end

function GM:PostGamemodeLoaded()
	language.Add("revolver_ammo", "Revolver Ammo")
	language.Add("molotov_ammo", "Molotov Ammo")
	
	local screenscale = BetterScreenScale()
	
	surface.CreateFont("ZMDeathFonts", {font = "zmweapons", extended = false, size = screenscale * 120, weight = 500, blursize = 0, scanlines = 0, antialias = true, additive = false})
	surface.CreateFont("zm_hud_font", {font = "Consolas", size = 20, weight = 700, antialias = true, additive = false})
	surface.CreateFont("zm_hud_font2", {font = "Consolas", size = 16, weight = 700, antialias = true, additive = false})
	
	surface.CreateFont("ZMHUDFontTiny", {font = "Consolas", size = screenscale * 16, weight = 0, antialias = true, additive = false, shadow = false, outline = true})
	surface.CreateFont("ZMHUDFontSmallest", {font = "Consolas", size = screenscale * 20, weight = 0, antialias = true, additive = false, shadow = false, outline = true})
	surface.CreateFont("ZMHUDFontSmaller", {font = "Consolas", size = screenscale * 22, weight = 0, antialias = true, additive = false, shadow = false, outline = true})
	surface.CreateFont("ZMHUDFontSmall", {font = "Consolas", size = screenscale * 28, weight = 0, antialias = true, additive = false, shadow = false, outline = true})
	surface.CreateFont("ZMHUDFont", {font = "Consolas", size = screenscale * 42, weight = 0, antialias = true, additive = false, shadow = false, outline = true})
	surface.CreateFont("ZMHUDFontBig", {font = "Consolas", size = screenscale * 72, weight = 0, antialias = true, additive = false, shadow = false, outline = true})
	surface.CreateFont("ZMHUDFontTinyBlur", {font = "Consolas", size = screenscale * 16, weight = 0, antialias = true, additive = false, shadow = false, outline = false, blursize = 8})
	surface.CreateFont("ZMHUDFontSmallerBlur", {font = "Consolas", size = screenscale * 22, weight = 0, antialias = true, additive = false, shadow = false, outline = false, blursize = 8})
	surface.CreateFont("ZMHUDFontSmallBlur", {font = "Consolas", size = screenscale * 28, weight = 0, antialias = true, additive = false, shadow = false, outline = false, blursize = 8})
	surface.CreateFont("ZMHUDFontBlur", {font = "Consolas", size = screenscale * 42, weight = 0, antialias = true, additive = false, shadow = false, outline = false, blursize = 8})
	surface.CreateFont("ZMHUDFontBigBlur", {font = "Consolas", size = screenscale * 72, weight = 0, antialias = true, additive = false, shadow = false, outline = false, blursize = 8})
	
	surface.CreateFont("ZMScoreBoardTitle", {font = "Verdana", size = 32, weight = 0, antialias = true, additive = false, shadow = false, outline = true})
	surface.CreateFont("ZMScoreBoardSubTitle", {font = "Verdana", size = 22, weight = 0, antialias = true, additive = false, shadow = false, outline = true})
	surface.CreateFont("ZMScoreBoardPlayer", {font = "Verdana", size = 16, weight = 0, antialias = true, additive = false, shadow = false, outline = true})
	surface.CreateFont("ZMScoreBoardHeading", {font = "Verdana", size = 24, weight = 0, antialias = true, additive = false, shadow = false, outline = false})
	surface.CreateFont("ZMScoreBoardPlayerSmall", {font = "arial", size = 20, weight = 0, antialias = true, additive = false, shadow = false, outline = true})
	
	surface.CreateFont("ZSHUDFontSmallestNS", {font = "Verdana", size = screenscale * 20, weight = 0, antialias = true, additive = false, shadow = false, outline = true})
	
	surface.CreateFont("DefaultFontVerySmall", {font = "Consolas", size = 10, weight = 0, antialias = false})
	surface.CreateFont("DefaultFontSmall", {font = "Consolas", size = 11, weight = 0, antialias = false})
	surface.CreateFont("DefaultFontSmallDropShadow", {font = "Consolas", size = 11, weight = 0, shadow = true, antialias = false})
	surface.CreateFont("DefaultFont", {font = "Consolas", size = 13, weight = 500, antialias = false})
	surface.CreateFont("DefaultFontBold", {font = "Consolas", size = 13, weight = 1000, antialias = false})
	surface.CreateFont("DefaultFontLarge", {font = "Consolas", size = 16, weight = 0, antialias = false})
end

function GM:PrePlayerDraw(ply)
	if not player_manager.RunClass(LocalPlayer(), "PreDraw", ply) then return true end
end

function GM:PostPlayerDraw(pl)
	if not player_manager.RunClass(LocalPlayer(), "PostDraw", pl) then return true end
end

local startVal = 0
local endVal = 1
local fadeSpeed = 1.6
local function FadeToDraw(self)
	if self.fadeAlpha < 1 then
		self.fadeAlpha = self.fadeAlpha + fadeSpeed * FrameTime()
		self.fadeAlpha = math.Clamp(self.fadeAlpha, startVal, endVal)
		
		render.SetBlend(self.fadeAlpha)
		self:DrawModel()
		render.SetBlend(1)
	else
		self:DrawModel()
	end
end
function GM:OnEntityCreated(ent)
	if ent:IsNPC() then
		local entname = string.lower(ent:GetClass())
		
		if string.sub(entname, 1, 12) == "npc_headcrab" then
			ent:DrawShadow(false)
			ent.RenderOverride = function(self)
				return true
			end
			
			return
		end
	
		if string.lower(entname) == "npc_zombie" or string.lower(entname) == "npc_poisonzombie" or string.lower(entname) == "npc_fastzombie" then
			ent.fadeAlpha = 0
			ent.RenderOverride = FadeToDraw
		end
	end
end

function GM:SpawnMenuEnabled()
	return false
end

function GM:SpawnMenuOpen()
	return false
end

function GM:ContextMenuOpen()
	return false
end

function GM:GetCurrentZombieGroups()
	return self.ZombieGroups == {} and nil or self.ZombieGroups
end

function GM:GetCurrentZombieGroup()
	return self.SelectedZombieGroups
end

local placingShockWave = false
function GM:SetPlacingShockwave(b)
	placingShockwave = b
end

local placingZombie = false
function GM:SetPlacingSpotZombie(b)
	placingZombie = b
end

local placingRally = false
function GM:SetPlacingRallyPoint(b)
	placingRally = b
end

local placingTrap = false
function GM:SetPlacingTrapEntity(b)
	placingTrap = b
end

function GM:OnPlayerChat( player, strText, bTeamOnly, bPlayerIsDead )
	local tab = {}

	if bTeamOnly then
		table.insert(tab, Color(30, 160, 40))
		table.insert(tab, "(TEAM) ")
	end

	if IsValid(player) then
		table.insert(tab, player)
	else
		table.insert(tab, "Console")
	end

	table.insert(tab, Color(255, 255, 255))
	table.insert(tab, ": " .. strText)

	chat.AddText(unpack(tab))

	return true
end

local colBlur = Color(0, 0, 0)
function draw.SimpleTextBlurry(text, font, x, y, col, xalign, yalign)
	colBlur.r = col.r
	colBlur.g = col.g
	colBlur.b = col.b
	colBlur.a = col.a * math.Rand(0.35, 0.6)

	draw.SimpleText(text, font.."Blur", x, y, colBlur, xalign, yalign)
	draw.SimpleText(text, font, x, y, col, xalign, yalign)
end

local function TraceToNPCs(ent)
	if ent:IsNPC() and not ent:GetSharedBool("selected") then
		return true
	end
	
	return false
end
function GM:GUIMouseReleased(mouseCode, aimVector)
	local tr = TraceLongDistanceFilter(aimVector, TraceToNPCs)
	
	if tr.Entity and tr.Entity:IsNPC() then
		isDragging = false
		RunConsoleCommand("zm_selectnpc", tr.Entity:EntIndex())
	end
	
	if isDragging then
		local a, b = gui.ScreenToVector(traceX, traceY), gui.ScreenToVector(mouseX, mouseY)
		local c, d = TraceLongDistanceFilter(a, TraceToNPCs), TraceLongDistanceFilter(b, TraceToNPCs)
		
		if c.HitPos and d.HitPos then
			RunConsoleCommand("zm_traceselect", tostring(d.HitPos), tostring(c.HitPos))
		end
		
		isDragging = false
		traceX, traceY = 0, 0
	end
end

local selectringMaterial = CreateMaterial("CommandRingMat", "UnlitGeneric", {
	["$basetexture"] = "effects/zm_ring",
	["$ignorez"] = 1,
	["$additive"] = 1,
	["$vertexalpha"] = 1,
	["$vertexcolor"] = 1,
	["$translucent"] = 1,
	["$nocull"] = 1
})
local rallyringMaterial = CreateMaterial("RallyRingMat", "UnlitGeneric", {
	["$basetexture"] = "effects/zm_arrows",
	["$ignorez"] = 1,
	["$additive"] = 1,
	["$vertexalpha"] = 1,
	["$vertexcolor"] = 1,
	["$translucent"] = 1,
	["$nocull"] = 1
})
local click_delta = 0
local zm_ring_pos = Vector(0, 0, 0)
local zm_ring_ang = Angle(0, 0, 0)
function GM:GUIMousePressed(mouseCode, aimVector)
	if LocalPlayer():IsZM() then
		if mouseCode == MOUSE_LEFT then
			if placingShockwave then
				if zm_placedpoweritem then zm_placedpoweritem = false end
				
				RunConsoleCommand("_place_physexplode_zm", tostring(aimVector))
				placingShockwave = false
				zm_placedpoweritem = true
			elseif placingZombie then
				if zm_placedpoweritem then zm_placedpoweritem = false end
				
				RunConsoleCommand("_place_zombiespot_zm", tostring(aimVector))
				placingZombie = false
				zm_placedpoweritem = true
			elseif placingTrap then
				local hitPos = TraceLongDistance(aimVector, true).HitPos
				local vector = string.Explode(" ", tostring(hitPos))
			
				RunConsoleCommand("zm_placetrigger", vector[1], vector[2], vector[3], trapTrigger)

				placingTrap = false
			elseif placingRally then
				if zm_placedrally then zm_placedrally = false end
				
				local hitPos = TraceLongDistance(aimVector, true).HitPos
				local vector = string.Explode(" ", tostring(hitPos))
				
				RunConsoleCommand("zm_placerally", vector[1], vector[2], vector[3], trapTrigger)
				
				placingRally = false			
				zm_placedrally = true
			else
				RunConsoleCommand("zm_deselect")
			end
			
			if zm_placedpoweritem or zm_placedrally then
				click_delta = CurTime()

				local tr = TraceLongDistance(aimVector, true)
				zm_ring_pos = tr.HitPos
				zm_ring_ang = tr.HitNormal:Angle()
				zm_ring_ang:RotateAroundAxis(zm_ring_ang:Right(), 90)
			end
		end
		
		if mouseCode == MOUSE_LEFT and not placingShockwave and not placingZombie then
			local ent = TraceLongDistance(aimVector).Entity
			if IsValid(ent) then
				local class = ent:GetClass()
				gamemode.Call("SpawnTrapMenu", class, ent)
			end
		elseif mouseCode == MOUSE_RIGHT then
			if placingShockwave then
				LocalPlayer():PrintTranslatedMessage(HUD_PRINTTALK, "exit_explosion_mode")
				placingShockwave = false
				zm_placedpoweritem = false
				return
			elseif placingZombie then
				LocalPlayer():PrintTranslatedMessage(HUD_PRINTTALK, "exit_hidden_mode")
				placingZombie = false
				zm_placedpoweritem = true
				return
			elseif placingTrap then
				placingTrap = false
				return
			elseif placingRally then
				zm_placedrally = false
				return
			end
			
			if zm_rightclicked then zm_rightclicked = false end
			
			click_delta = CurTime()

			local tr = TraceLongDistance(aimVector)
			zm_ring_pos = tr.HitPos
			zm_ring_ang = tr.HitNormal:Angle()
			zm_ring_ang:RotateAroundAxis(zm_ring_ang:Right(), 90)
			
			zm_rightclicked = true
			
			if IsValid(tr.Entity) and not tr.Entity:IsWorld() then
				RunConsoleCommand("zm_npc_target_object", tostring(tr.HitPos), tr.Entity:EntIndex())
			else
				RunConsoleCommand("zm_command_npcgo", tostring(tr.HitPos))
			end
		end
	end
end

function GM:PlayerBindPress(ply, bind, pressed)
	if player_manager.RunClass(ply, "BindPress", bind, pressed) then return true end
end

function GM:CreateGhostEntity(trap, rallyID)
	if trap then
		hook.Call("SetPlacingTrapEntity", self, true)
	else
		hook.Call("SetPlacingRallyPoint", self, true)
		trapTrigger = rallyID
	end
end

function GM:KeyPress(ply, key)
	if ply:IsZM() and key == IN_SPEED then
		gui.EnableScreenClicker(false)
	end
end

function GM:KeyRelease(ply, key)
	if ply:IsZM() and key == IN_SPEED then
		gui.EnableScreenClicker(true)
	end
end

function GM:CreateVGUI()
	holdTime = CurTime()
	isDragging = false
	
	if IsValid(self.trapPanel) then
		trapPanel:Remove()
	end
	
	gui.EnableScreenClicker(true)
	self.powerMenu = vgui.Create("zm_powerpanel")
	
	timer.Simple(0.25, function()
		if not IsValid(self.powerMenu) then
			self.powerMenu = vgui.Create("zm_powerpanel")
		else
			self.powerMenu:SetVisible(true)
		end
	end)
end

function GM:SetDragging(b)
	isDragging = b
	holdTime = CurTime()
end

function GM:IsMenuOpen()
	if IsValid(self.objmenu) and self.objmenu:IsVisible() then
		return true
	end
	
	local menus = hook.Call("GetZombieMenus", self)
	if menus then
		for _, menu in pairs(menus) do
			if IsValid(menu) and menu:IsVisible() then
				return true
			end
		end
	end
	
	if self.trapMenu and self.trapMenu:IsVisible() then
		return true
	end
	
	return false
end

local entnum = 0
function GM:CreateClientsideRagdoll(ent, ragdoll)
	if IsValid(ent) and ent:IsNPC() then
		local instantfade = false
		local ragdollnum = #ents.FindByClass(ragdoll:GetClass())
		if ragdollnum > GetConVar("zm_max_ragdolls"):GetInt() then
			instantfade = true
		end
		
		ragdoll:SetModel(ent:GetModel())
		ragdoll.fadeAlpha = 255
		
		local entname = tostring(ent)
		local fadetime = instantfade and 0 or GetConVar("zm_ragdoll_fadetime"):GetInt()
		timer.Simple(fadetime, function()
			if not IsValid(ragdoll) then return end
			
			ragdoll:SetRenderMode(RENDERMODE_TRANSALPHA)
			
			local col = Color(255, 255, 255)
			local timername = "FadeRagdoll_"..entname.."_"..entnum
			entnum = entnum + 1
			timer.Create(timername, 0, 0, function()
				if not IsValid(ragdoll) then 
					timer.Destroy(timername) 
					return 
				end
				
				if ragdoll.fadeAlpha == nil then ragdoll.fadeAlpha = 255 end
				
				if ragdoll.fadeAlpha and ragdoll.fadeAlpha <= 0 then
					entnum = entnum - 1
					
					timer.Destroy(timername)
					ragdoll:Remove()
					
					if IsValid(ent) then
						ent:Remove()
					end
					
					return
				elseif not ragdoll.fadeAlpha then
					ragdoll:Remove()
					if IsValid(ent) then
						ent:Remove()
					end
				end
				
				ragdoll.fadeAlpha = ragdoll.fadeAlpha - (255 * FrameTime())
				ragdoll.fadeAlpha = math.Clamp(ragdoll.fadeAlpha, 0, 255)
				
				col.a = ragdoll.fadeAlpha
				ragdoll:SetColor(col)
			end)
		end)
	end
end

--local SCROLL_THRESHOLD = 8
function GM:Think()
	if input.IsMouseDown(MOUSE_LEFT) and holdTime < CurTime() and not isDragging and LocalPlayer():IsZM() then
		holdTime = CurTime()
		mouseX, mouseY = gui.MousePos()
		
		isDragging = true
	end
	
	if isDragging and not input.IsMouseDown(MOUSE_LEFT) then
		isDragging = false
	end
	
	-- +lookup and +lookdown is broken in gmod
	--[[
	if not isDragging and LocalPlayer():IsZM() and vgui.CursorVisible() then
		local menuopen = gamemode.Call("IsMenuOpen")
		if not menuopen then
			local mousex, mousey = gui.MousePos()	
			if mousex <= SCROLL_THRESHOLD then
				RunConsoleCommand("+left")
				timer.Simple(0, function() RunConsoleCommand("-left") end)
			elseif mousex >= (ScrW() - SCROLL_THRESHOLD) then
				RunConsoleCommand("+right")
				timer.Simple(0, function() RunConsoleCommand("-right") end)
			else
				RunConsoleCommand("-right")
				timer.Simple(0, function() RunConsoleCommand("-left") end)
			end
			
			if mousey <= SCROLL_THRESHOLD then
				RunConsoleCommand("+lookup")
				timer.Simple(0, function() RunConsoleCommand("-lookdown") end)
			elseif mousey >= (ScrH() - SCROLL_THRESHOLD) then
				RunConsoleCommand("+lookdown")
				timer.Simple(0, function() RunConsoleCommand("-lookup") end)
			else
				RunConsoleCommand("-lookup")
				timer.Simple(0, function() RunConsoleCommand("-lookdown") end)
			end
		end
	end
	--]]
end

function GM:PostDrawOpaqueRenderables()
	if LocalPlayer():IsZM() then
		cam.Start3D()
			local zombies = ents.FindByClass("npc_*")
		
			for _, entity in pairs(zombies) do
				if string.sub(entity:GetClass(), 1, 12) == "npc_headcrab" then continue end
				
				if IsValid(entity) and entity:Health() > 0 then
					local Health, MaxHealth = entity:Health(), entity:GetMaxHealth()
					local pos = entity:GetPos() + Vector(0, 0, 2)
					local colour = Color(0, 0, 0, 125)
					local healthfrac = math.max(Health, 0) / MaxHealth
					
					colour.r = math.Approach(255, 20, math.abs(255 - 20) * healthfrac)
					colour.g = math.Approach(0, 255, math.abs(0 - 255) * healthfrac)
					colour.b = math.Approach(0, 20, math.abs(0 - 20) * healthfrac)
					
					render.SetMaterial(healthcircleMaterial)
					render.DrawQuadEasy(pos, Vector(0, 0, 1), 40, 40, colour)
					render.DrawQuadEasy(pos, Vector(0, 0, -1), 40, 40, colour)
					
					if entity:GetSharedBool("selected", false) then
						render.SetMaterial(circleMaterial)
						
						render.DrawQuadEasy(pos, Vector(0, 0, 1), 40, 40, colour)
						render.DrawQuadEasy(pos, Vector(0, 0, -1), 40, 40, colour)
					end
				end
			end
		cam.End3D()
		
		if zm_rightclicked then
			cam.Start3D2D(zm_ring_pos, zm_ring_ang, 1)
				local size = 64 * (1 - (CurTime() - click_delta) * 4)
					
				render.SetMaterial(selectringMaterial)
				render.DrawQuadEasy(Vector( 0, 0, 0 ), Vector(0, 0, 1), size, size, Color(255, 255, 255))
				render.DrawQuadEasy(Vector( 0, 0, 0 ), Vector(0, 0, -1), size, size, Color(255, 255, 255))
				
				if size <= 0 then
					zm_rightclicked = false
					didtrace = false
				end
			cam.End3D2D()		
		elseif zm_placedrally then
			cam.Start3D2D(zm_ring_pos, zm_ring_ang, 1)
				local size = 64 * (1 - (CurTime() - click_delta) * 4)
					
				render.SetMaterial(rallyringMaterial)
				render.DrawQuadEasy(Vector( 0, 0, 0 ), Vector(0, 0, 1), size, size, Color(255, 255, 255))
				render.DrawQuadEasy(Vector( 0, 0, 0 ), Vector(0, 0, -1), size, size, Color(255, 255, 255))
				
				if size <= 0 then
					zm_placedrally = false
					didtrace = false
				end
			cam.End3D2D()
		elseif zm_placedpoweritem then
			cam.Start3D2D(zm_ring_pos, zm_ring_ang, 1)
				local size = 1 * ((CurTime() - click_delta) * 350)
					
				render.SetMaterial(selectringMaterial)
				render.DrawQuadEasy(Vector( 0, 0, 0 ), Vector(0, 0, 1), size, size, Color(255, 255, 255), (CurTime() * 250) % 360)
				
				if size >= 128 then
					zm_placedpoweritem = false
					didtrace = false
				end
			cam.End3D2D()
		end
	end
end

local spec_overlay = Material("zm_overlay.png", "smooth unlitgeneric nocull")
function GM:RenderScreenspaceEffects()
	if LocalPlayer():IsSpectator() then
		render.SetMaterial(spec_overlay)
		render.DrawScreenQuad()
	elseif LocalPlayer():IsZM() then
		if self.nightVision then
			self.nightVisionCur = self.nightVisionCur or 0.5
			
			if self.nightVisionCur < 0.995 then 
				self.nightVisionCur = self.nightVisionCur + 0.02 *(1 - self.nightVisionCur)
			end
		
			nightVision_ColorMod["$pp_colour_brightness"] = self.nightVisionCur * 0.8
			nightVision_ColorMod["$pp_colour_contrast"]   = self.nightVisionCur * 1.1
		
			DrawColorModify(nightVision_ColorMod)
			DrawBloom(0, self.nightVisionCur * 3.6, 0.1, 0.1, 1, self.nightVisionCur * 0.5, 0, 1, 0)
		end
	end
end

function GM:RestartRound()
	if IsValid(self.trapPanel) then
		trapPanel:Remove()
	end
	
	if IsValid(self.powerMenu) then
		self.powerMenu:Remove()
		
		if IsValid(self.ToolPan_Center_Tip) then
			self.ToolPan_Center_Tip:Remove()
		end
	end
	
	GAMEMODE.ZombieGroups = nil
	GAMEMODE.SelectedZombieGroups = nil
	
	hook.Call("ResetZombieMenus", self)
	
	placingShockWave = false
	placingZombie = false
	placingRally = false
	
	zombieMenu = nil
	
	mouseX, mouseY  = 0, 0
	traceX, traceY  = 0, 0
	isDragging = false
	holdTime = 0
	
	gui.EnableScreenClicker(false)
end

net.Receive("zm_gamemodecall", function(length)
	gamemode.Call(net.ReadString())
end)

net.Receive("zm_mapinfo", function(length)
	GAMEMODE.MapInfo = net.ReadString()
end)

net.Receive("zm_sendcurrentgroups", function(length)
	GAMEMODE.ZombieGroups = net.ReadTable()
	GAMEMODE.bUpdateGroups = true
end)

net.Receive("zm_sendselectedgroup", function(length)
	GAMEMODE.SelectedZombieGroups = net.ReadUInt(8)
end)

net.Receive("zm_spawnclientragdoll", function(length)
	local ent = net.ReadEntity()
	if IsValid(ent) then
		ent:BecomeRagdollOnClient()
	end
end)

net.Receive("PlayerKilledByNPC", function(length)
	local victim = net.ReadEntity()
	if not IsValid(victim) then return end
	
	local inflictor	= net.ReadString()
	local attacker	= net.ReadString()
	
	GAMEMODE:AddDeathNotice(attacker, TEAM_ZOMBIEMASTER, inflictor, victim:Name(), victim:Team())
end)

net.Receive("PlayerKilled", function(length)
	local victim = net.ReadEntity()
	if not IsValid(victim) then return end
	
	local inflictor	= net.ReadString()
	local attacker = translate.Get("killmessage_something")
	
	GAMEMODE:AddDeathNotice(attacker, TEAM_UNASSIGNED, inflictor, victim:Name(), victim:Team())
end)

net.Receive("zm_coloredprintmessage", function(length)
	local msg = net.ReadString()
	local color = net.ReadColor()
	local dur =	net.ReadUInt(32)
	local fade = net.ReadFloat()
	
	util.PrintMessageC(nil, msg, color, dur, fade)
end)