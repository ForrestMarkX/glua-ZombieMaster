AddCSLuaFile()
DEFINE_BASECLASS("player_zm")

local PLAYER = {}

function PLAYER:PostOnDeath(inflictor, attacker)
	BaseClass.PostOnDeath(self, inflictor, attacker)
	
	timer.Simple(1, function()
		if IsValid(self.Player) and self.Player:IsSpectator() and self.Player:GetObserverMode() ~= OBS_MODE_ROAMING then
			self.Player:Spectate(OBS_MODE_ROAMING)
		end
	end)
end

function PLAYER:PostThink()
	if self.Player:IsOnFire() then
		self.Player:Extinguish()
	end
	
	if self.Player:GetObserverMode() == OBS_MODE_ROAMING then 
		if self.Player:KeyPressed(IN_ATTACK) then
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
		elseif self.Player:KeyPressed(IN_ATTACK2) then
			self.Player.SpectatedPlayerKey = (self.Player.SpectatedPlayerKey or 0) - 1

			local players = {}

			for k, v in pairs(team.GetPlayers(TEAM_SURVIVOR)) do
				if v:Alive() and v ~= self.Player then
					table.insert(players, v)
				end
			end
			
			if self.Player.SpectatedPlayerKey < 0 then
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
end

player_manager.RegisterClass("player_spectator", PLAYER, "player_zm")