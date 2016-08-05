include("shared.lua")
include("cl_killicons.lua")
include("cl_utility.lua")
include("cl_scoreboard.lua")
include("cl_dermaskin.lua")

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

w, h = ScrW(), ScrH()

MySelf = MySelf or NULL
hook.Add("InitPostEntity", "GetLocal", function()
	MySelf = LocalPlayer()

	GAMEMODE.HookGetLocal = GAMEMODE.HookGetLocal or (function(g) end)
	gamemode.Call("HookGetLocal", MySelf)
	RunConsoleCommand("initpostentity")
end)

local function TraceLongDistance(vector)
	local data = {}
	data.start = MySelf:GetShootPos()
	data.endpos = data.start +(vector *9999999999999)
	data.filter = MySelf
	
	return util.TraceLine(data)
end

function GM:InitPostEntity()
	self.HUDShouldDraw = self._HUDShouldDraw
	self.HUDPaint = self._HUDPaint
	self.PostPlayerDraw = self._PostPlayerDraw
	self.PrePlayerDraw = self._PrePlayerDraw
	self.CreateMove = self._CreateMove
end

function GM:_PrePlayerDraw(ply)
	return not ply:IsSurvivor()
end

function GM:_PostPlayerDraw(pl)
	if MySelf:IsZM() and pl:IsSurvivor() then
		local plHealth, plMaxHealth = pl:Health(), pl:GetMaxHealth()
		local pos = pl:GetPos() + Vector(0, 0, 2)
		local colour = Color(0, 0, 0, 125)
		local healthfrac = math.max(plHealth, 0) / plMaxHealth
		
		colour.r = math.Approach(255, 20, math.abs(255 - 20) * healthfrac)
		colour.g = math.Approach(0, 255, math.abs(0 - 255) * healthfrac)
		colour.b = math.Approach(0, 20, math.abs(0 - 20) * healthfrac)
		
		render.SetMaterial(healthcircleMaterial)
		render.DrawQuadEasy(pos, Vector(0, 0, 1), 40, 40, colour)
		render.DrawQuadEasy(pos, Vector(0, 0, -1), 40, 40, colour)
		
		render.SetMaterial(healtheffect)
		render.DrawQuadEasy(pos, Vector(0, 0, 1), 38, 28, Color(255, 255, 255))
		render.DrawQuadEasy(pos, Vector(0, 0, -1), 38, 28, Color(255, 255, 255))
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

	if ( bTeamOnly ) then
		table.insert( tab, Color( 30, 160, 40 ) )
		table.insert( tab, "(TEAM) " )
	end

	if ( IsValid( player ) ) then
		table.insert( tab, player )
	else
		table.insert( tab, "Console" )
	end

	table.insert( tab, Color( 255, 255, 255 ) )
	table.insert( tab, ": " .. strText )

	chat.AddText( unpack(tab) )

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

function GM:GUIMouseReleased(mouseCode, aimVector)
	local tr = TraceLongDistance(aimVector)
	
	if tr.Entity and tr.Entity:IsNPC() then
		isDragging = false
		RunConsoleCommand("zm_selectnpc", tr.Entity:EntIndex())
	end
	
	if isDragging then
		local a, b = gui.ScreenToVector(traceX, traceY), gui.ScreenToVector(mouseX, mouseY)
		local c, d = TraceLongDistance(a), TraceLongDistance(b)
		
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
	if MySelf:IsZM() then
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
				local hitPos = TraceLongDistance(aimVector).HitPos
				local vector = string.Explode(" ", tostring(hitPos))
			
				RunConsoleCommand("zm_placetrigger", vector[1], vector[2], vector[3], trapTrigger)

				placingTrap = false
			elseif placingRally then
				if zm_placedrally then zm_placedrally = false end
				
				local hitPos = TraceLongDistance(aimVector).HitPos
				local vector = string.Explode(" ", tostring(hitPos))
				
				RunConsoleCommand("zm_placerally", vector[1], vector[2], vector[3], trapTrigger)
				
				placingRally = false			
				zm_placedrally = true
			else
				RunConsoleCommand("zm_deselect")
			end
			
			if zm_placedpoweritem or zm_placedrally then
				click_delta = CurTime()

				local tr = TraceLongDistance(aimVector)
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
			if zm_rightclicked then zm_rightclicked = false end
			
			click_delta = CurTime()

			local tr = TraceLongDistance(aimVector)
			zm_ring_pos = tr.HitPos
			zm_ring_ang = tr.HitNormal:Angle()
			zm_ring_ang:RotateAroundAxis(zm_ring_ang:Right(), 90)
			
			zm_rightclicked = true
			
			RunConsoleCommand("zm_command_npcgo", tostring(zm_ring_pos))
		end
	end
end

function GM:_CreateMove( cmd )
	if MySelf:IsZM() then
		if not isDragging and vgui.CursorVisible() then
			local menuopen = gamemode.Call("IsMenuOpen")
			if not menuopen then
				local x, y = gui.MousePos()
				if x ~= 0 or y ~= 0 then
					if x < 3 then
						mouseonedge = true
						mouseonedgex = true
						mouseonedgey = false
					elseif x > ScrW() - 3 then
						mouseonedge = true
						mouseonedgex = true
						mouseonedgey = false
					elseif y < 3 then
						mouseonedge = true
						mouseonedgex = false
						mouseonedgey = true
					elseif y > ScrH() - 3 then
						mouseonedge = true
						mouseonedgex = false
						mouseonedgey = true
					elseif mouseonedge then
						mouseonedge = false
						mouseonedgex = false
						mouseonedgey = false
					end
					
					if mouseonedge then
						local mouse_vect = gui.ScreenToVector(x, y)
						
						if not keepoldz then
							old_mouse_vect = mouse_vect
						end
						
						if mouseonedgex then
							mouse_vect.z = old_mouse_vect.z
							keepoldz = true
						elseif mouseonedgey then
							mouse_vect.x = 0
							keepoldz = false
						end
						
						local oldang = cmd:GetViewAngles()
						local newang = (mouse_vect - EyePos()):Angle()
						oldang.pitch = math.ApproachAngle(oldang.pitch, newang.pitch, FrameTime() * math.max(45, math.abs(math.AngleDifference(oldang.pitch, newang.pitch)) ^ 1.05))
						oldang.yaw = math.ApproachAngle(oldang.yaw, newang.yaw, FrameTime() * math.max(45, math.abs(math.AngleDifference(oldang.yaw, newang.yaw)) ^ 1.05))
						cmd:SetViewAngles(oldang)
					end
				end
			end
		end
	end
end

function GM:PlayerBindPress(ply, bind, pressed)
	if bind == "+menu" then
		if pressed and ply:IsSurvivor() then
			RunConsoleCommand("zm_dropweapon")
		end
		return true
	elseif bind == "+menu_context" then
		if pressed and ply:IsSurvivor() then
			RunConsoleCommand("zm_dropammo")
		end
		return true
	elseif bind == "impulse 100" then
		if pressed and ply:IsZM() then
			RunConsoleCommand("zm_power_nightvision")
		end
	end
end

function GM:CreateGhostEntity(trap, rallyID)
	if trap then
		gamemode.Call("SetPlacingTrapEntity", true)
	else
		gamemode.Call("SetPlacingRallyPoint", true)
		trapTrigger = rallyID
	end
end

function GM:KeyPress( ply, key )
	if ply:IsZM() and key == IN_SPEED then
		gui.EnableScreenClicker(false)
	end
end

function GM:KeyRelease( ply, key )
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
	
	local menus = gamemode.Call("GetZombieMenus")
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

function GM:CreateClientsideRagdoll(ent, ragdoll)
	if IsValid(ent) and ent:IsNPC() then
		ragdoll:SetModel(ent:GetModel())
		
		if ent.GetDamageForce then
			local force = ent:GetDamageForce()
			if force and not force:IsZero() then
				for i=0, ragdoll:GetPhysicsObjectCount() - 1 do
					local phys = ragdoll:GetPhysicsObjectNum(i)
					phys:ApplyForceCenter(force * 10000)
				end
			end
		end
		
		timer.Simple(0.1, function()
			if not timer.Exists("removeRagdolls") then
				timer.Create("removeRagdolls", 30, 0, function() game.RemoveRagdolls() end)
			end
		end)
	end
end

--local SCROLL_THRESHOLD = 8
function GM:Think()
	if input.IsMouseDown(MOUSE_LEFT) and holdTime < CurTime() and not isDragging and MySelf:IsZM() then
		holdTime = CurTime()
		mouseX, mouseY = gui.MousePos()
		
		isDragging = true
	end
	
	if isDragging and not input.IsMouseDown(MOUSE_LEFT) then
		isDragging = false
	end
	
	-- +lookup and +lookdown is broken in gmod
	--[[
	if not isDragging and MySelf:IsZM() and vgui.CursorVisible() then
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
	if MySelf:IsZM() then
		cam.Start3D()
			local zombies = ents.FindByClass("npc_*")
		
			for _, entity in pairs(zombies) do
				if IsValid(entity) then
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
					
					if entity:GetNWBool("selected", false) then
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

function GM:RenderScreenspaceEffects()
	if MySelf:IsSpectator() then
		render.SetMaterial( Material( "zm_overlay.png", "smooth unlitgeneric nocull" ) )
		render.DrawScreenQuad()
	elseif MySelf:IsZM() then
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
	end
	
	GAMEMODE.ZombieGroups = nil
	GAMEMODE.SelectedZombieGroups = nil
	
	gamemode.Call("ResetZombieMenus")
	
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
	local attacker = "Something"
	
	GAMEMODE:AddDeathNotice( attacker, -1, inflictor, victim:Name(), victim:Team() )
end)