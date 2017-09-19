include("shared.lua")
include("cl_utility.lua")
include("cl_killicons.lua")
include("cl_scoreboard.lua")
include("cl_dermaskin.lua")
include("cl_entites.lua")

include("cl_zm_options.lua")
include("cl_targetid.lua")
include("cl_hud.lua")
include("cl_zombie.lua")

include("vgui/dteamheading.lua")
include("vgui/dzombiepanel.lua")
include("vgui/dpowerpanel.lua")
include("vgui/dmodelselector.lua")
include("vgui/dclickableavatar.lua")

local zombieMenu	  = nil

mouseX, mouseY  = 0, 0
oldMousePos		= Vector(0, 0, 0)
isDragging 	    = false

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

local ZombieModelOverrides = {}

function GM:PostClientInit()
	net.Start("zm_player_ready")
	net.SendToServer()
end

function GM:OnReloaded()
	if IsValid(g_Scoreboard) then
		g_Scoreboard:Remove()
	end
	
	hook.Call("BuildZombieDataTable", self)
	hook.Call("SetupNetworkingCallbacks", self)
	hook.Call("SetupCustomItems", self)
end

local startVal = 0
local endVal = 1
local fadeSpeed = 1.6
local function FadeToDraw(self)
	if GAMEMODE:CallZombieFunction(self, "PreDraw") then return end
	
	if self.fadeAlpha < 1 then
		self.fadeAlpha = self.fadeAlpha + fadeSpeed * FrameTime()
		self.fadeAlpha = math.Clamp(self.fadeAlpha, startVal, endVal)
		
		render.SetBlend(self.fadeAlpha)
		if self.OldDraw then	
			self:OldDraw()
		else 
			if IsValid(self.c_Model) then
				if not IsValid(self.c_Model:GetParent()) then
					self.c_Model:SetParent(self)
				end
				
				self.c_Model:DrawModel()
			else 
				self:DrawModel() 
			end
		end
		render.SetBlend(1)
	else
		if self.OldDraw then	
			self:OldDraw()
		else 
			if IsValid(self.c_Model) then
				if not IsValid(self.c_Model:GetParent()) then
					self.c_Model:SetParent(self)
				end
				
				self.c_Model:DrawModel()
			else 
				self:DrawModel() 
			end
		end
	end
	
	GAMEMODE:CallZombieFunction(self, "PostDraw")
end
function GM:InitPostEntity()
	hook.Call("PostClientInit", self)
	
	local ammotbl = hook.Call("GetCustomAmmo", self)
	if table.Count(ammotbl) > 0 then
		for _, ammo in pairs(ammotbl) do
			game.AddAmmoType({name = ammo.Type, dmgtype = ammo.DmgType, tracer = ammo.TracerType, plydmg = 0, npcdmg = 0, force = 2000, maxcarry = ammo.MaxCarry})
		end
	end
	
	for class, tab in pairs(scripted_ents.GetList()) do
		if scripted_ents.GetType(class) ~= "ai" then continue end
		
		local ENT = scripted_ents.GetStored(class).t
		if not ENT then continue end
		
		ENT.fadeAlpha = 0
		ENT.OldDraw = ENT.OldDraw or ENT.Draw
		ENT.Draw = FadeToDraw
	end
	
	vgui.CreateFromTable{
		Base = "Panel",
		Paint = function() return true end,
		PerformLayout = function()
			hook.Run("OnScreenSizeChange", ScrW(), ScrH())
		end
	}:ParentToHUD()
end

function GM:PostGamemodeLoaded()
	language.Add("revolver_ammo", "Revolver Ammo")
	language.Add("molotov_ammo", "Molotov Ammo")
	
	hook.Call("SetupFonts", GAMEMODE)
end

function GM:SetupFonts()
	surface.CreateFont("zm_powerhud_smaller", {font = "Consolas", size = 15})
	surface.CreateFont("zm_powerhud_small", {font = "Consolas", size = 18})
	
	surface.CreateFont("OptionsHelp", {font = "Consolas", size = 20, weight = 450})
	surface.CreateFont("OptionsHelpBig", {font = "Consolas", size = 22, weight = 450})

	surface.CreateFont("zm_hud_font_tiny", {font = "Consolas", size = ScreenScale(6)})
	surface.CreateFont("zm_hud_font_smaller", {font = "Consolas", size = ScreenScale(5)})
	surface.CreateFont("zm_hud_font_small", {font = "Consolas", size = ScreenScale(9)})
	surface.CreateFont("zm_hud_font_normal", {font = "Consolas", size = ScreenScale(14)})
	surface.CreateFont("zm_hud_font_big", {font = "Consolas", size = ScreenScale(24)})
	
	surface.CreateFont("ZMScoreBoardTitle", {font = "Verdana", size = ScreenScale(11)})
	surface.CreateFont("ZMScoreBoardTitleSub", {font = "Verdana", size = 16, weight = 1000})
	surface.CreateFont("ZMScoreBoardPlayer", {font = "Verdana", size = 16})
	surface.CreateFont("ZMScoreBoardPlayerSmall", {font = "arial", size = 20})
	surface.CreateFont("ZMScoreBoardHeading", {font = "Verdana", size = 24})

	surface.CreateFont("ZMScoreBoardPlayerBold", {font = "Verdana", size = 16, weight = 1000, outline = true, antialias = false})
	surface.CreateFont("ZMScoreBoardPlayerSmallBold", {font = "arial", size = 20, weight = 1000, outline = true, antialias = false})
	
	surface.CreateFont("ZMDeathFonts", {font = "zmweapons", extended = false, size = ScreenScale(40), weight = 500})
end

function GM:PrePlayerDraw(ply)
	if not player_manager.RunClass(LocalPlayer(), "PreDraw", ply) then return true end
end

function GM:PostPlayerDraw(pl)
	if not player_manager.RunClass(LocalPlayer(), "PostDraw", pl) then return true end
end

function GM:Think()
	player_manager.RunClass(LocalPlayer(), "Think")
	
	if IsValid(self.HiddenCSEnt) then
		local tr = util.QuickTrace(LocalPlayer():GetShootPos(), gui.ScreenToVector(gui.MousePos()) * 10000, player.GetAll())
		self.HiddenCSEnt:SetPos(tr.HitPos)
		
		local ang = LocalPlayer():EyeAngles()
		ang.x = 0.0
		ang.z = 0.0
		self.HiddenCSEnt:SetAngles(ang)
	end
end

function GM:OnEntityCreated(ent)
	if ent:IsNPC() then
		local entname = string.lower(ent:GetClass())
		if string.sub(entname, 1, 12) == "npc_headcrab" then
			ent:DrawShadow(false)
			ent.RenderOverride = function()
				return true
			end
			
			return
		end
		
		local zombietab = self:GetZombieData(entname)
		if zombietab ~= nil then
			self.iZombieList[ent:EntIndex()] = ent
		end

		if scripted_ents.GetType(entname) == nil then
			ent.fadeAlpha = 0
			ent.RenderOverride = FadeToDraw
			
			if ent:GetModel() == "models/zombie/classic.mdl" then
				self:CallZombieFunction(ent, "SetupModel")
							
				ent.c_Model = ClientsideModel(ent:GetModel())
				ent.c_Model:SetNoDraw(true)
				ent.c_Model:SetParent(ent)
				ent.c_Model:AddEffects(bit.bor(EF_BONEMERGE, EF_BONEMERGE_FASTCULL, EF_PARENT_ANIMATES))
				ent.c_Model:SetSkin(ent:GetSkin())
				
				ZombieModelOverrides[ent] = ent.c_Model
			end
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
local function SpotZombieCheck(self)
	render.SetBlend(0.65)
	self:DrawModel()
	render.SetBlend(1)
end
function GM:SetPlacingSpotZombie(b)
	if not IsValid(self.HiddenCSEnt) then
		self.HiddenCSEnt = ClientsideModel("models/zombie/zm_classic.mdl")
		
		local tr = util.QuickTrace(LocalPlayer():GetShootPos(), gui.ScreenToVector(gui.MousePos()) * 10000, player.GetAll())
		self.HiddenCSEnt:SetPos(tr.HitPos)
		self.HiddenCSEnt.RenderOverride = SpotZombieCheck
		
		local ang = LocalPlayer():EyeAngles()
		ang.x = 0.0
		ang.z = 0.0
		self.HiddenCSEnt:SetAngles(ang)
	end
	
	placingZombie = b
end

local placingAmbush = false
function GM:SetPlacingAmbush(b)
	placingAmbush = b
end

local TriggerEnt = nil
local placingRally = false
function GM:SetPlacingRallyPoint(b, ent)
	placingRally = b
	TriggerEnt = ent
end

local placingTrap = false
function GM:SetPlacingTrapEntity(b, ent)
	placingTrap = b
	TriggerEnt = ent
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
local function SelectionTrace(ent)
	if ent:GetClass() == "info_zombiespawn" or ent:GetClass() == "info_manipulate" then return true end
	return false
end
local function LocationTrace(ent)
	if not (ent:IsPlayer() or ent:IsNPC()) then return true end
end
function GM:GUIMousePressed(mouseCode, aimVector)
	if LocalPlayer():IsZM() then
		if mouseCode == MOUSE_LEFT then
			if not isDragging then
				mouseX, mouseY = gui.MousePos()
				isDragging = true
			end
			
			if placingShockwave then
				if zm_placedpoweritem then zm_placedpoweritem = false end
				
				net.Start("zm_place_physexplode")
					net.WriteVector(aimVector)
				net.SendToServer()
				
				placingShockwave = false
				zm_placedpoweritem = true
			elseif placingZombie then
				if zm_placedpoweritem then zm_placedpoweritem = false end
				
				net.Start("zm_place_zombiespot")
					net.WriteVector(aimVector)
				net.SendToServer()
				
				if IsValid(self.HiddenCSEnt) then
					self.HiddenCSEnt:Remove()
				end
				
				placingZombie = false
				zm_placedpoweritem = true
			elseif placingTrap then
				net.Start("zm_placetrigger")
					net.WriteVector(util.QuickTrace(LocalPlayer():GetShootPos(), aimVector * 10000, LocationTrace).HitPos)
					net.WriteEntity(TriggerEnt)
				net.SendToServer()

				placingTrap = false
			elseif placingRally then
				if zm_placedrally then zm_placedrally = false end
				
				net.Start("zm_placerally")
					net.WriteVector(util.QuickTrace(LocalPlayer():GetShootPos(), aimVector * 10000, LocationTrace).HitPos)
					net.WriteEntity(TriggerEnt)
				net.SendToServer()
				
				if IsValid(GAMEMODE.ZombiePanelMenu) then
					GAMEMODE.ZombiePanelMenu:SetVisible(true)
					GAMEMODE.ZombiePanelMenu = nil
				end
				
				placingRally = false			
				zm_placedrally = true			
			elseif placingAmbush then
				if zm_placedambush then zm_placedambush = false end
				
				net.Start("zm_create_ambush_point")
					net.WriteVector(util.QuickTrace(LocalPlayer():GetShootPos(), aimVector * 10000, LocationTrace).HitPos)
				net.SendToServer()
				
				placingAmbush = false			
				zm_placedambush = true
			else
				local tr = util.QuickTrace(LocalPlayer():GetShootPos(), aimVector * 56756, function(ent) if ent:IsNPC() and not ent.bIsSelected then return true end end)
				if tr.Entity and tr.Entity:IsNPC() then
					isDragging = false
					net.Start("zm_selectnpc")
						net.WriteEntity(tr.Entity)
					net.SendToServer()
				else
					if not LocalPlayer():KeyDown(IN_DUCK) then RunConsoleCommand("zm_deselect") end
				end
			end
			
			if zm_placedpoweritem or zm_placedrally or zm_placedambush then
				click_delta = CurTime()

				local tr = util.QuickTrace(LocalPlayer():GetShootPos(), aimVector * 10000, LocationTrace)
				zm_ring_pos = tr.HitPos + tr.HitNormal
				zm_ring_ang = tr.HitNormal:Angle()
				zm_ring_ang:RotateAroundAxis(zm_ring_ang:Right(), 90)
			end
		end
		
		if mouseCode == MOUSE_LEFT and not placingShockwave and not placingZombie then
			local ent = util.QuickTrace(LocalPlayer():GetShootPos(), aimVector * 10000, SelectionTrace).Entity
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
			elseif placingAmbush then
				zm_placedambush = false
				return
			end
			
			if zm_rightclicked then zm_rightclicked = false end
			
			click_delta = CurTime()

			local tr = util.QuickTrace(LocalPlayer():GetShootPos(), aimVector * 10000, LocationTrace)
			zm_ring_pos = tr.HitPos + tr.HitNormal
			zm_ring_ang = tr.HitNormal:Angle()
			zm_ring_ang:RotateAroundAxis(zm_ring_ang:Right(), 90)
			
			zm_rightclicked = true
			
			if IsValid(tr.Entity) and not tr.Entity:IsWorld() then
				net.Start("zm_npc_target_object")
					net.WriteVector(tr.HitPos)
					net.WriteEntity(tr.Entity)
				net.SendToServer()
			else
				net.Start("zm_command_npcgo")
					net.WriteVector(tr.HitPos)
				net.SendToServer()
			end
		end
	end
end

function GM:GUIMouseReleased(mouseCode, aimVector)
	if isDragging then
		util.BoxSelect(gui.MousePos())
		isDragging = false
	end
end

function GM:PlayerBindPress(ply, bind, pressed)
	if player_manager.RunClass(ply, "BindPress", bind, pressed) then return true end
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
	
	if IsValid(PlayerModelSelectionFrame) and PlayerModelSelectionFrame:IsVisible() then
		return true
	end
	
	return false
end

function GM:CreateClientsideRagdoll(ent, ragdoll)
	if string.find(ragdoll:GetModel(), "headcrab") then
		ragdoll:SetNoDraw(true)
		ragdoll:Remove()
	end
	
	if IsValid(ent) and ent:IsNPC() then
		if not GetConVar("zm_shouldragdollsfade"):GetBool() then return end
		
		local ragdollnum = #ents.FindByClass(ragdoll:GetClass())
		if ragdollnum > GetConVar("zm_max_ragdolls"):GetInt() then
			ragdoll:SetSaveValue("m_bFadingOut", true)
		end
		
		local fadetime = GetConVar("zm_cl_ragdoll_fadetime"):GetInt()
		timer.Simple(fadetime, function()
			if not IsValid(ragdoll) then return end
			ragdoll:SetSaveValue("m_bFadingOut", true)
		end)
		
		if IsValid(ZombieModelOverrides[ent]) then
			ZombieModelOverrides[ent]:Remove()
		end
	end
end

function GM:PostDrawOpaqueRenderables()
	if LocalPlayer():IsZM() and (zm_rightclicked or zm_placedrally or zm_placedpoweritem) then
		local size = Either(zm_placedpoweritem, 1 * ((CurTime() - click_delta) * 350), 64 * (1 - (CurTime() - click_delta) * 4))
		render.SuppressEngineLighting(true)
		render.OverrideDepthEnable(true, true)
		if zm_rightclicked then
			render.SetMaterial(selectringMaterial)
		elseif zm_placedrally then
			render.SetMaterial(rallyringMaterial)
		elseif zm_placedpoweritem then
			render.SetMaterial(selectringMaterial)
		end
		
		render.DrawQuadEasy(zm_ring_pos + Vector( 0, 0, 1 ), Vector(0, 0, 1), size, size, Color(255, 255, 255))
			
		if (zm_placedpoweritem and size >= 128) or (not zm_placedpoweritem and size <= 0) then
			zm_rightclicked = false
			zm_placedrally = false
			zm_placedpoweritem = false
			didtrace = false
		end			
		
		render.OverrideDepthEnable(false, false)
		render.SuppressEngineLighting(false)
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
	
	table.Empty(self.iZombieList)
	
	GAMEMODE.ZombieGroups = nil
	GAMEMODE.SelectedZombieGroups = nil
	GAMEMODE.nightVision = nil
	
	hook.Call("ResetZombieMenus", self)
	
	hook.Remove("PreRender", "PreRender.Fullbright")
	hook.Remove("PostRender", "PostRender.Fullbright")
	hook.Remove("PreDrawHUD", "PreDrawHUD.Fullbright")
	
	placingShockWave = false
	placingZombie = false
	placingRally = false
	
	zombieMenu = nil
	
	mouseX, mouseY  = 0, 0
	isDragging = false
	
	gui.EnableScreenClicker(false)
end

function GM:OnScreenSizeChange(new_w, new_h)
	-- This could be unwise but it seems to be the only way to fresh font sizes
	hook.Call("SetupFonts", GAMEMODE)
end

net.Receive("zm_infostrings", function(length)
	GAMEMODE.MapInfo = net.ReadString()
	GAMEMODE.HelpInfo = net.ReadString()
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
		if scripted_ents.GetType(ent:GetClass()) == nil then return end
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