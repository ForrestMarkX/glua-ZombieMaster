AddCSLuaFile()
DEFINE_BASECLASS("player_zm")

local PLAYER = {}

function PLAYER:CreateMove(cmd)
	if not isDragging and vgui.CursorVisible() then
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
			render.DrawQuadEasy(pos, Vector(0, 0, 1), 40, 40, colour)
			render.DrawQuadEasy(pos, Vector(0, 0, -1), 40, 40, colour)
			
			render.SetMaterial(healtheffect)
			render.DrawQuadEasy(pos, Vector(0, 0, 1), 38, 28, Color(255, 255, 255))
			render.DrawQuadEasy(pos, Vector(0, 0, -1), 38, 28, Color(255, 255, 255))
		end
	end
end

function PLAYER:BindPress(bind, pressed)
	if bind == "impulse 100" and pressed then
		RunConsoleCommand("zm_power_nightvision")
		return true
	end
end

function PLAYER:PostThink()
	if self.Player:IsOnFire() then
		self.Player:Extinguish()
	end
	
	if GAMEMODE.Income_Time ~= 0 and GAMEMODE.Income_Time <= CurTime() then
		self.Player:AddZMPoints(self.Player:GetZMPointIncome())
		GAMEMODE.Income_Time = CurTime() + GetConVar("zm_incometime"):GetInt()
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
			self.Player:SetPos(specplayer:GetPos())
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
			self.Player:SetPos(specplayer:GetPos())
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