AddCSLuaFile()
DEFINE_BASECLASS("player_basezm")

local PLAYER = {}

function PLAYER:Spawn()
    BaseClass.Spawn(self)
    
    self.Player:Flashlight(false)
    self.Player:RemoveEffects(EF_DIMLIGHT)
    
    self.Player:SendLua([[
        if cvars.Bool("zm_cl_enablehints") and IsValid(GAMEMODE.ZM_Center_Hints) then
            GAMEMODE.ZM_Center_Hints:SetHint(translate.Get("zm_hint_intro"))
            GAMEMODE.ZM_Center_Hints:SetActive(true, 3)
            
            timer.Simple(9, function()
                if not IsValid(GAMEMODE.ZM_Center_Hints) then return end
                
                GAMEMODE.ZM_Center_Hints:SetHint(translate.Format("zm_hint_movement", input.LookupBinding("+speed", true)))
                GAMEMODE.ZM_Center_Hints:SetActive(true, 3)
                
                timer.Simple(9, function()
                    if not IsValid(GAMEMODE.ZM_Center_Hints) then return end
                    
                    GAMEMODE.ZM_Center_Hints:SetHint(translate.Format("zm_hint_vision", input.LookupBinding("impulse 100", true)))
                    GAMEMODE.ZM_Center_Hints:SetActive(true, 3)
                end)
            end)
        end   
    ]])
end

function PLAYER:SetupMove(mv, cmd)
    if cmd:GetMouseWheel() ~= 0 then
        mv:SetOrigin(mv:GetOrigin() + Vector(0, 0, (cmd:GetMouseWheel() * self.Player:GetInfo("zm_cl_scrollspeed"))))
    end
    
    if CLIENT then
        if not hook.Call("IsMenuOpen", GAMEMODE) and (input.WasMousePressed(MOUSE_WHEEL_UP) or input.WasMousePressed(MOUSE_WHEEL_DOWN)) and vgui.CursorVisible() then
            RememberCursorPosition()
            gui.EnableScreenClicker(false)
            
            timer.Simple(0, function() 
                gui.EnableScreenClicker(true) 
                RestoreCursorPosition()
            end)
        end
    end
end

function PLAYER:CreateMove(cmd)
    if not isDragging and vgui.CursorVisible() then
        if system.IsWindows() and not system.HasFocus() then return end
        
        local menuopen = hook.Call("IsMenuOpen", GAMEMODE)
        if not menuopen then
            local mousex, mousey = gui.MousePos()
            local viewangle = cmd:GetViewAngles()
            local bSetViewAng = false
            
            if mousex <= SCROLL_THRESHOLD then
                viewangle.y = viewangle.y + ((RealFrameTime() * cvars.Number("cl_pitchspeed", 0)) * 0.5)
                bSetViewAng = true
            elseif mousex >= (ScrW() - SCROLL_THRESHOLD) then
                viewangle.y = viewangle.y - ((RealFrameTime() * cvars.Number("cl_pitchspeed", 0)) * 0.5)
                bSetViewAng = true
            end
            
            if mousey <= SCROLL_THRESHOLD then
                viewangle.p = viewangle.p - ((RealFrameTime() * cvars.Number("cl_pitchspeed", 0)) * 0.5)
                bSetViewAng = true
            elseif mousey >= (ScrH() - SCROLL_THRESHOLD) then
                viewangle.p = viewangle.p + ((RealFrameTime() * cvars.Number("cl_pitchspeed", 0)) * 0.5)
                bSetViewAng = true
            end
            
            if bSetViewAng then
                cmd:SetViewAngles(viewangle)
            end
        end
    end
end

local healthcircleMaterial = Material("effects/zm_healthring")
local healtheffect         = Material("effects/yellowflare")
local undovision           = false
function PLAYER:PreDrawOther(ply)
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
        
        local v_qual = GetConVar("zm_vision_quality"):GetInt()
        if v_qual == 1 and not self.Player:IsLineOfSightClear(ply) then
            if cvars.Bool("zm_silhouette_zmvision_only") and not GAMEMODE.nightVision then return true end
            
            undovision = true
            
            render.ModelMaterialOverride(ZM_Vision)
            render.SetColorModulation(1, 0, 0, 1)
        end
    end
    
    return BaseClass.PreDraw(self, ply)
end

function PLAYER:PostDrawOther(ply)
    if undovision then
        undovision = false
        
        render.ModelMaterialOverride()
        render.SetColorModulation(1, 1, 1)
    end
    
    return BaseClass.PostDraw(self, ply)
end

if CLIENT then
    local selection_color_outline = Color(255, 0, 0, 255)
    local selection_color_box     = Color(120, 0, 0, 80)
    function PLAYER:DrawHUD()
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

function PLAYER:ButtonDown(button)
    if SERVER then return end
    
    if button == cvars.Number("zm_killzombieskey", 0) then
        RunConsoleCommand("zm_power_killzombies")
    end
end

player_manager.RegisterClass("player_zombiemaster", PLAYER, "player_basezm")