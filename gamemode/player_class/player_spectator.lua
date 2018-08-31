AddCSLuaFile()
DEFINE_BASECLASS("player_basezm")

local PLAYER = {}

function PLAYER:Spawn()
    BaseClass.Spawn(self)
    
    self.Player:Flashlight(false)
    self.Player:RemoveEffects(EF_DIMLIGHT)
    
    self.Player:DrawShadow(false)
    self.Player:GodEnable()
end

function PLAYER:CanSuicide()
    return false
end

function PLAYER:PostOnDeath(inflictor, attacker)
    BaseClass.PostOnDeath(self, inflictor, attacker)
    
    timer.Simple(1, function()
        if IsValid(self.Player) and self.Player:IsSpectator() and self.Player:GetObserverMode() ~= OBS_MODE_ROAMING then
            self.Player:Spectate(OBS_MODE_ROAMING)
        end
    end)
end

function PLAYER:KeyPress(key)
    if SERVER and self.Player.AllowKeyPress then
		local specplayer = NULL
		local bChangeTarget = false
		if self.Player:KeyPressed(IN_RELOAD) then
			if self.Player:GetObserverMode() ~= OBS_MODE_ROAMING then
				self.Player:Spectate(OBS_MODE_ROAMING)
				self.Player:SpectateEntity(NULL)
			end
		elseif self.Player:KeyPressed(IN_ATTACK) then
			self.Player:StripWeapons()
			specplayer = self:GetNextViewablePlayer(1)
			bChangeTarget = true
		elseif self.Player:KeyPressed(IN_ATTACK2) then
			self.Player:StripWeapons()
			specplayer = self:GetNextViewablePlayer(-1)
			bChangeTarget = true
		end
		
		if bChangeTarget then
			if IsValid(specplayer) then
				self.Player:Spectate(OBS_MODE_CHASE)
				self.Player:SpectateEntity(specplayer)
			else
				self.Player:Spectate(OBS_MODE_ROAMING)
				self.Player:SpectateEntity(NULL)
			end
		end
    end
end

function PLAYER:CalcView(view)
    local target = self.Player:GetObserverTarget()
    if IsValid(target) and target:IsNPC() and self.Player:GetObserverMode() ~= OBS_MODE_ROAMING then
        local tr = {
            start = target:WorldSpaceCenter(),
            endpos = target:WorldSpaceCenter() - (view.angles:Forward() * 150),
            filter = {target}
        }
        local trace = util.TraceLine(tr)
        
        view.origin = trace.HitPos + trace.HitNormal * 10
    end
end

function PLAYER:PostThink()  
    if SERVER then
        if self.Player:IsOnFire() then
            self.Player:Extinguish()
        end
        
        if self.Player:GetObserverMode() ~= OBS_MODE_ROAMING then
            local target = self.Player:GetObserverTarget()
            if not IsValid(target) or (target.Alive and not target:Alive()) or (target.Team and target:Team() == TEAM_SPECTATOR) then
                self.Player:StripWeapons()
                self.Player:Spectate(OBS_MODE_ROAMING)
                self.Player:SpectateEntity(NULL)
            end
        end
    end
end

player_manager.RegisterClass("player_spectator", PLAYER, "player_basezm")