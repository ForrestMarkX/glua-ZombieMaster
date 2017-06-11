AddCSLuaFile()
DEFINE_BASECLASS("player_zm")

local PLAYER = {}

function PLAYER:Spawn()
	BaseClass.Spawn(self)
	
	self.Player:Flashlight(false)
	self.Player:CrosshairDisable()
	self.Player:RemoveEffects(EF_DIMLIGHT)
end

function PLAYER:SetupMove(mv, cmd)
	if cmd:GetMouseWheel() ~= 0 then
		mv:SetOrigin(mv:GetOrigin() + Vector(0, 0, (cmd:GetMouseWheel() * 20)))
	end
	
	if CLIENT then
		if not hook.Call("IsMenuOpen", GAMEMODE) and (input.WasMousePressed(MOUSE_WHEEL_UP) or input.WasMousePressed(MOUSE_WHEEL_DOWN)) then
			if vgui.CursorVisible() then
				local c_x, c_y = input.GetCursorPos()
				
				gui.EnableScreenClicker(false)
				timer.Simple(0, function() 
					gui.EnableScreenClicker(true) 
					input.SetCursorPos(c_x, c_y)
				end)
			end
		end
	end
end

function PLAYER:CreateMove(cmd)
	if not isDragging and vgui.CursorVisible() then
		if system.IsWindows() and not system.HasFocus() then return end
		
		local menuopen = hook.Call("IsMenuOpen", GAMEMODE)
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

local healthcircleMaterial = Material("effects/zm_healthring")
local healtheffect		   = Material("effects/yellowflare")
function PLAYER:PreDraw(ply)
	if ply:IsSurvivor() and ply:Alive() then
		local plHealth, plMaxHealth = ply:Health(), ply:GetMaxHealth()
		if plHealth > 0 then
			local pos = ply:GetPos() + Vector(0, 0, 2)
			local colour = Color(0, 0, 0, 125)
			local healthfrac = math.max(plHealth, 0) / plMaxHealth
			
			colour.r = math.Approach(255, 20, math.abs(255 - 20) * healthfrac)
			colour.g = math.Approach(0, 255, math.abs(0 - 255) * healthfrac)
			colour.b = math.Approach(0, 20, math.abs(0 - 20) * healthfrac)
			
			render.SetMaterial(healthcircleMaterial)
			render.DrawQuadEasy(pos + Vector(0, 0, 1), Vector(0, 0, 1), 40, 40, colour)
			
			render.SetMaterial(healtheffect)
			render.DrawQuadEasy(pos + Vector(0, 0, 1), Vector(0, 0, 1), 40, 40, Color(255, 255, 255))
		end
	end
	
	return BaseClass.PreDraw(self, ply)
end

if CLIENT then
	local skullMaterial  = surface.GetTextureID("VGUI/miniskull")
	local popMaterial	 = surface.GetTextureID("VGUI/minifigures")
	local selection_color_outline = Color(255, 0, 0, 255)
	local selection_color_box 	  = Color(120, 0, 0, 80)
	function PLAYER:DrawHUD()
		local h, w = ScrH(), ScrW()
		
		-- Resources + Income.
		draw.DrawSimpleRect(5, h - 43, 150, 38, Color(60, 0, 0, 200))
		draw.DrawSimpleOutlined(5, h - 43, 150, 38, color_black)
		
		surface.SetDrawColor(color_white)
		surface.SetTexture(skullMaterial)
		surface.DrawTexturedRect(7, h - 41, 32, 32)
		
		draw.DrawText(tostring(LocalPlayer():GetZMPoints()), "zm_powerhud_small", 60, h - 42, color_white, 1)
		
		if LocalPlayer():GetZMPointIncome() then
			draw.DrawText("+ " .. LocalPlayer():GetZMPointIncome(), "zm_powerhud_smaller", 90, h - 24, color_white, 1)
		end
		
		-- Population.
		draw.DrawSimpleRect(5, h - 62, 100, 18, Color(60, 0, 0, 200))
		draw.DrawSimpleOutlined(5, h - 62, 100, 18, color_black)
		
		surface.SetDrawColor(color_white)
		surface.SetTexture(popMaterial)
		surface.DrawTexturedRect(6, h - 61, 16, 16)
		
		draw.DrawText(GAMEMODE:GetCurZombiePop() .. "/" .. GAMEMODE:GetMaxZombiePop(), "zm_powerhud_smaller", 60, h - 62, color_white, 1)

		if isDragging then
			local x, y = gui.MousePos()
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

function PLAYER:BindPress(bind, pressed)
	if bind == "impulse 100" and pressed then
		RunConsoleCommand("zm_power_nightvision")
		return true
	elseif bind == "+speed" and pressed then
		if not self.Player:KeyDown(IN_DUCK) then
			gui.EnableScreenClicker(not vgui.CursorVisible())
			
			if IsValid(GAMEMODE.powerMenu) then
				if vgui.CursorVisible() then
					GAMEMODE.powerMenu:SetVisible(true)
				else
					GAMEMODE.powerMenu:SetVisible(false)
				end
			end
			
			return true
		end
	elseif bind == "+duck" then
		if pressed then
			RunConsoleCommand("+speed")
		else
			RunConsoleCommand("-speed")
		end
		
		return true
	end
end

function PLAYER:Think()
	BaseClass.Think(self)
	
	if GAMEMODE.Income_Time and GAMEMODE.Income_Time ~= 0 and GAMEMODE.Income_Time <= CurTime() then
		self.Player:AddZMPoints(self.Player:GetZMPointIncome())
		
		local time = GetConVar("zm_incometime"):GetInt()
		GAMEMODE.Income_Time = CurTime() + math.random(time, time * 2)
	end
end

function PLAYER:PostThink()
	if self.Player:IsOnFire() then
		self.Player:Extinguish()
	end
	
	if self.Player:KeyPressed(IN_RELOAD) then
		self.Player.SpectatedPlayerKey = (self.Player.SpectatedPlayerKey or 0) + 1
		local players = {}

		for k, v in pairs(team.GetPlayers(TEAM_SURVIVOR)) do
			if v:Alive() and v ~= self.Player then
				table.insert(players, v)
			end
		end
		
		if self.Player.SpectatedPlayerKey > #players then
			self.Player.SpectatedPlayerKey = 0
			return
		end

		self.Player:StripWeapons()
		local specplayer = players[self.Player.SpectatedPlayerKey]

		if specplayer then
			self.Player:SetPos(specplayer:EyePos())
		end
	elseif self.Player:KeyPressed(IN_USE) then
		self.Player.SpectatedPlayerKey = (self.Player.SpectatedPlayerKey or 0) - 1

		local players = {}

		for k, v in pairs(team.GetPlayers(TEAM_SURVIVOR)) do
			if v:Alive() and v ~= self.Player then
				table.insert(players, v)
			end
		end
		
		if self.Player.SpectatedPlayerKey <= 0 then
			self.Player.SpectatedPlayerKey = #players
			return
		end

		self.Player:StripWeapons()
		local specplayer = players[self.Player.SpectatedPlayerKey]

		if specplayer then
			self.Player:SetPos(specplayer:EyePos())
		end
	end
end

function PLAYER:ShouldTaunt(act)
	return false
end

function PLAYER:CanSuicide()
	if not GAMEMODE:GetRoundEnd() then	
		hook.Call("TeamVictorious", GAMEMODE, true, "zombiemaster_submit")
	end
	
	return false
end

player_manager.RegisterClass("player_zombiemaster", PLAYER, "player_zm")