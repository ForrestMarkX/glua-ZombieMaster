include("shared.lua")
include("cl_credits.lua")
include("cl_utility.lua")
include("cl_killicons.lua")
include("cl_scoreboard.lua")
include("cl_dermaskin.lua")
include("cl_entites.lua")

include("cl_zm_options.lua")
include("cl_targetid.lua")
include("cl_hud.lua")
include("cl_zombie.lua")
include("cl_powers.lua")

include("vgui/dmainhud.lua")
include("vgui/dteamheading.lua")
include("vgui/dzombiepanel.lua")
include("vgui/dpowerpanel.lua")
include("vgui/dmodelselector.lua")
include("vgui/dclickableavatar.lua")
include("vgui/dcrosshairinfo.lua")
include("vgui/dhintpanel.lua")
include("vgui/dlobby.lua")
include("vgui/dhealthhud.lua")

local zombieMenu = nil

GM.ItemEnts = {}
GM.SilhouetteEnts = {}
GM.QuadDraws = {}

ZM_Vision = CreateMaterial("ZM_Vision_Material_LD", "VertexLitGeneric", {
    ["$basetexture"] = "models/debug/debugwhite",
    ["$model"] = 1,
    ["$ignorez"] = 1
})

local nightVision_ColorMod = {
    ["$pp_colour_addr"]         = -1,
    ["$pp_colour_addg"]         = -0.35,
    ["$pp_colour_addb"]         = -1,
    ["$pp_colour_brightness"]     = 0.8,
    ["$pp_colour_contrast"]        = 1.1,
    ["$pp_colour_colour"]         = 0,
    ["$pp_colour_mulr"]         = 0 ,
    ["$pp_colour_mulg"]         = 0.028,
    ["$pp_colour_mulb"]         = 0
}

local lobbyMenu_ColorMod = {
    ["$pp_colour_contrast"] = 1,
    ["$pp_colour_colour"] = 0,
    ["$pp_colour_addr"] = 0,
    ["$pp_colour_addg"] = 0,
    ["$pp_colour_addb"] = 0,
    ["$pp_colour_brightness"] = 0,
    ["$pp_colour_mulr"] = 0,
    ["$pp_colour_mulg"] = 0,
    ["$pp_colour_mulb"] = 0
}

GM.playerReadyList = {}
function GM:PostClientInit()
    net.Start("zm_player_ready")
    net.SendToServer()
    
    self.ZM_Center_Hints = vgui.Create("zm_tippanel")
    self.ZM_Center_Hints:SetSize(ScrW() * 0.1, ScrH() * 0.05)
    self.ZM_Center_Hints:InvalidateLayout(true)
    self.ZM_Center_Hints:AlignBottom(ScrH() * 0.25)
    self.ZM_Center_Hints:ParentToHUD()
    
    if GetConVar("zm_debug_nolobby"):GetBool() then return end
    
    local bRoundActive = self:GetRoundActive() or team.NumPlayers(TEAM_ZOMBIEMASTER) > 0
    if not bRoundActive then
        self:OpenLobbyMenu()
    end
end

function GM:OnReloaded()
    self.bLUARefresh = true
    
    if IsValid(g_Scoreboard) then
        g_Scoreboard:Remove()
    end
    
    if LocalPlayer():IsZM() then
        gamemode.Call("RemoveZMPanels")
        gamemode.Call("CreateVGUI")
    end
    
    hook.Call("BuildZombieDataTable", self)
    hook.Call("SetupNetworkingCallbacks", self)
    hook.Call("SetupCustomItems", self)
    
    if IsValid(GAMEMODE.HumanHealthHUD) then
        GAMEMODE.HumanHealthHUD:Remove()
        GAMEMODE.HumanHealthHUD = vgui.Create("CHudHealthInfo")
    end
    
    self.bLUARefresh = false
end

function GM:InitPostEntity()
    hook.Call("PostClientInit", self)
    
    local ammotbl = hook.Call("GetCustomAmmo", self)
    if table.Count(ammotbl) > 0 then
        for _, ammo in pairs(ammotbl) do
            game.AddAmmoType({name = ammo.Type, dmgtype = ammo.DmgType, tracer = ammo.TracerType, plydmg = 0, npcdmg = 0, force = 2000, maxcarry = ammo.MaxCarry})
        end
    end
    
    vgui.CreateFromTable({
        Base = "Panel",
        Paint = function() return true end,
        PerformLayout = function()
            hook.Run("OnScreenSizeChange", ScrW(), ScrH())
        end
    }):ParentToHUD()
end

local function NPCRenderOverride(self)
    if self.DrawingSilhouette then
        GAMEMODE:CallZombieFunction(self, "Draw")
        return
    end
    
    if GAMEMODE:CallZombieFunction(self, "PreDraw") then return end
    
    GAMEMODE:CallZombieFunction(self, self.FadeFinished and "Draw" or "SpawnDraw")
    GAMEMODE:CallZombieFunction(self, "PostDraw")
end
function GM:NetworkEntityCreated(ent)
    if ent:IsNPC() then
        if ent:IsScripted() then
            ent:SetNoDraw(true)
            
            timer.Simple(0, function()
                ent.Time = 0.55
                ent.LifeTime = CurTime() + ent.Time
                
                ent:SetNoDraw(false)
                ent.fadeAlpha = 0
                ent.RenderOverride = NPCRenderOverride
            end)
        else
            ent.Time = 0.55
            ent.LifeTime = CurTime() + ent.Time
            
            ent.fadeAlpha = 0
            ent.RenderOverride = NPCRenderOverride
        end
    end
end

function GM:PostGamemodeLoaded()
    language.Add("revolver_ammo", "Revolver Ammo")
    language.Add("molotov_ammo", "Molotov Ammo")
    
    hook.Call("SetupFonts", GAMEMODE)
end

function GM:SetupFonts()
    surface.CreateFont("zm_powerhud_smaller", {font = "Consolas", size = ScreenScale(6)})
    surface.CreateFont("zm_powerhud_small", {font = "Consolas", size = ScreenScale(7)})
    
    surface.CreateFont("OptionsHelp", {font = "Verdana RU", size = ScreenScale(7), weight = 450})
    surface.CreateFont("OptionsHelpBig", {font = "Verdana RU", size = ScreenScale(8), weight = 450})

    surface.CreateFont("zm_hud_font_tiny", {font = "Verdana RU", size = ScreenScale(6), weight = 1000})
    surface.CreateFont("zm_hud_font_smaller", {font = "Verdana RU", size = ScreenScale(5), weight = 1000})
    surface.CreateFont("zm_hud_font_small", {font = "Verdana RU", size = ScreenScale(9), weight = 1000})
    surface.CreateFont("zm_hud_font_normal", {font = "Verdana RU", size = ScreenScale(14), weight = 1000})
    surface.CreateFont("zm_hud_font_big", {font = "Verdana RU", size = ScreenScale(24), weight = 1000})
    surface.CreateFont("zm_hud_font_bigger", {font = "Verdana RU", size = ScreenScale(30), weight = 1000})
    surface.CreateFont("zm_hud_font_huge", {font = "Verdana RU", size = ScreenScale(42), weight = 1000})
    
    surface.CreateFont("zm_game_text_small", {font = "Dead Font Walking", size = ScreenScale(9)})
    surface.CreateFont("zm_game_text", {font = "Dead Font Walking", size = ScreenScale(11)})
    
    surface.CreateFont("ZMHudNumbers", {font = "Monofonto", size = ScreenScale(30), weight = 0})
    surface.CreateFont("ZMHudNumbersSmall", {font = "Monofonto", size = ScreenScale(22), weight = 0})
    
    surface.CreateFont("ZMScoreBoardTitle", {font = "Verdana RU", size = ScreenScale(11)})
    surface.CreateFont("ZMScoreBoardTitleSub", {font = "Verdana RU", size = ScreenScale(5), weight = 1000})
    surface.CreateFont("ZMScoreBoardPlayer", {font = "Verdana RU", size = ScreenScale(5)})
    surface.CreateFont("ZMScoreBoardPlayerSmall", {font = "arial", size = ScreenScale(7)})
    surface.CreateFont("ZMScoreBoardHeading", {font = "Verdana RU", size = ScreenScale(8)})

    surface.CreateFont("ZMScoreBoardPlayerBold", {font = "Verdana RU", size = ScreenScale(5), weight = 1000, outline = true, antialias = false})
    surface.CreateFont("ZMScoreBoardPlayerSmallBold", {font = "arial", size = ScreenScale(7), weight = 1000, outline = true, antialias = false})
    
    surface.CreateFont("ZMDeathFonts", {font = "zmweapons", extended = false, size = ScreenScale(40), weight = 500})
end
GM:SetupFonts()

function GM:PreCleanupMap()
    if GAMEMODE.ParsedTextObjects then
        table.Empty(GAMEMODE.ParsedTextObjects)
    end
end

function GM:GenerateClickedQuadTable(mat, endtime, aimVector, filter)
    aimVector = aimVector or LocalPlayer():GetAimVector()
    endtime = endtime or 0.3
    filter = filter or {LocalPlayer()}
    
    local click_delta = CurTime()

    local tr = util.QuickTrace(LocalPlayer():GetShootPos(), aimVector * 10000, filter)
    local quadang = tr.HitNormal:Angle()
    quadang:RotateAroundAxis(quadang:Right(), 90)
    
    return {Material = mat, TexW = mat:Width(), TexH = mat:Height(), Delta = CurTime(), EndTime = CurTime() + endtime, Pos = tr.HitPos + tr.HitNormal, Ang = quadang}
end

function GM:PrePlayerDraw(ply)
    if LocalPlayer() == ply then
        if not player_manager.RunClass(ply, "PreDraw") then return true end
    else
        if not player_manager.RunClass(LocalPlayer(), "PreDrawOther", ply) then return true end
    end
end

function GM:PostPlayerDraw(pl)
    if LocalPlayer() == ply then
        player_manager.RunClass(ply, "PostDraw")
    else
        player_manager.RunClass(LocalPlayer(), "PostDrawOther", ply)
    end
end

function GM:ShouldSelectionIgnoreEnt(ent)
    return not (ent:GetClass() == "info_zombiespawn" or ent:GetClass() == "info_manipulate")
end

local lastwarntim = -1
function GM:Think()
    player_manager.RunClass(LocalPlayer(), "Think")
    
    for index, npc in pairs(self.iZombieList) do
        self:CallZombieFunction(npc, "Think")
    end
    
    if IsValid(self.HiddenCSEnt) then
        local tr = util.QuickTrace(LocalPlayer():GetShootPos(), gui.ScreenToVector(gui.MousePos()) * 10000, player.GetAll())
        self.HiddenCSEnt:SetPos(tr.HitPos)
        
        local ang = LocalPlayer():EyeAngles()
        ang.x = 0.0
        ang.z = 0.0
        self.HiddenCSEnt:SetAngles(ang)
    end
    
    if IsValid(self.PlayerLobby) and self:GetRoundActive() then 
        self.PlayerLobby:Remove()
    end
    
    if not self:GetRoundActive() then
        local endtime = self:GetReadyCount()
        if endtime ~= -1 then
            local timleft = math.max(0, endtime - CurTime())
            if timleft <= 5 and lastwarntim ~= math.ceil(timleft) then
                lastwarntim = math.ceil(timleft)
                if 0 < lastwarntim then
                    surface.PlaySound("buttons/lightswitch2.wav")
                end
            end
        end
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
        
        table.insert(self.SilhouetteEnts, ent)
    end
    
    if ent:GetClass() == "item_zm_ammo" or ent:GetClass() == "item_ammo_revolver" or ent:IsWeapon() then
        self.ItemEnts[#self.ItemEnts + 1] = ent
    end
end

function GM:EntityRemoved(ent)
    if ent:IsNPC() then
        table.RemoveByValue(self.iZombieList, ent)
        table.RemoveByValue(self.SilhouetteEnts, ent)
    end
    
    if ent:GetClass() == "item_zm_ammo" or ent:GetClass() == "item_ammo_revolver" or ent:IsWeapon() then
        table.RemoveByValue(self.ItemEnts, ent)
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

function GM:GUIMousePressed(mouseCode, aimVector)
    player_manager.RunClass(LocalPlayer(), "MousePressed", mouseCode, aimVector)
end

function GM:GUIMouseReleased(mouseCode, aimVector)
    player_manager.RunClass(LocalPlayer(), "MouseReleased", mouseCode, aimVector)
end

function GM:PlayerBindPress(ply, bind, pressed)
    if player_manager.RunClass(ply, "BindPress", bind, pressed) then return true end
end

function GM:CreateVGUI()
    if IsValid(self.trapPanel) then
        trapPanel:Remove()
    end
    
    gui.EnableScreenClicker(true)
    self.powerMenu = vgui.Create("zm_powerpanel")
    
    self.InfoHUD = vgui.Create("zm_mainhud")
    self.InfoHUD:SetSize(ScrW() * 0.15, ScrH() * 0.1)
    self.InfoHUD:AlignBottom(3)
    self.InfoHUD:ParentToHUD()
    
    self.ToolPan_Center_Tip = vgui.Create("DPanel")
    self.ToolPan_Center_Tip:SetVisible(false)
    self.ToolPan_Center_Tip:SetSize(ScrW() * 0.1, ScrH() * 0.03)
    self.ToolPan_Center_Tip:InvalidateLayout(true)
    self.ToolPan_Center_Tip:Center()
    self.ToolPan_Center_Tip:AlignBottom(10)
    self.ToolPan_Center_Tip:ParentToHUD()
    
    function self.ToolPan_Center_Tip:Think()
        if GAMEMODE.ToolPan_Center_Tip ~= self then
            self:Remove()
        end
    end
    
    self.ToolLab_Center_Tip = vgui.Create("DLabel", self.ToolPan_Center_Tip)
    self.ToolLab_Center_Tip:SetTextColor(color_white)
    self.ToolLab_Center_Tip:SetFont("OptionsHelpBig")
                
    timer.Simple(0.25, function()
        if not IsValid(self.powerMenu) then
            self.powerMenu = vgui.Create("zm_powerpanel")
        else
            self.powerMenu:SetVisible(true)
        end
    end)
    
    gamemode.Call("SetupZMPowers")
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
    
    if IsValid(ent) then
        if ent:IsNPC() then
            table.RemoveByValue(self.iZombieList, ent)
            table.RemoveByValue(self.SilhouetteEnts, ent)
            
            if ent.LastHitPhysBone then
                local phys = ragdoll:GetPhysicsObjectNum(ent.LastHitPhysBone)
                phys:ApplyForceOffset((ent.LastDamageForce or vector_origin) * ((ent.LastDamageAmount or 10) * 0.5), ent.LastHitPos or vector_origin)
            else
                for i=0, ragdoll:GetPhysicsObjectCount() - 1 do
                    local phys = ragdoll:GetPhysicsObjectNum(i)
                    phys:ApplyForceCenter((ent.LastDamageForce or vector_origin) * 0.5)
                end
            end
            
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
        elseif ent:IsPlayer() then
            ragdoll:SetSubMaterial(ent.bSkinReplacmentIndex, ent.bSkinReplacmentMat)
        end
    end
end

local mat_Copy = Material( "pp/copy" )
local mat_Add = Material( "pp/add" )
local rt_Store = render.GetScreenEffectTexture( 0 )
local rt_Buffer = render.GetScreenEffectTexture( 1 )
function GM:PostDrawEffects()
    if LocalPlayer():IsSurvivor() and not self.bDisableHalos then
        local rt_Scene = render.GetRenderTarget()
        render.CopyRenderTargetToTexture(rt_Store)

        render.Clear(0, 0, 0, 255, false, true)

        cam.Start3D()
        render.SetStencilEnable(true)
            render.SuppressEngineLighting(true)
                render.SetStencilWriteMask(1)
                render.SetStencilTestMask(1)
                render.SetStencilReferenceValue(1)

                render.SetStencilCompareFunction(STENCIL_ALWAYS)
                render.SetStencilPassOperation(STENCIL_REPLACE)
                render.SetStencilFailOperation(STENCIL_KEEP)
                render.SetStencilZFailOperation(STENCIL_KEEP)
                
                for k, v in pairs(self.ItemEnts) do
                    if not IsValid(v) or not v:ShouldDrawOutline() then continue end
                    v:DrawModel()
                end

                render.SetStencilCompareFunction(STENCIL_EQUAL)
                render.SetStencilPassOperation(STENCIL_KEEP)

                cam.Start2D()
                    surface.SetDrawColor(self.HaloColor)
                    surface.DrawRect(0, 0, ScrW(), ScrH())
                cam.End2D()
            render.SuppressEngineLighting(false)
        render.SetStencilEnable(false)
        cam.End3D()

        render.CopyRenderTargetToTexture(rt_Buffer)
        render.SetRenderTarget(rt_Scene)
        
        mat_Copy:SetTexture("$basetexture", rt_Store)
        render.SetMaterial(mat_Copy)
        
        render.DrawScreenQuad()

        render.SetStencilEnable(true)
            render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_NOTEQUAL)

            mat_Add:SetTexture("$basetexture", rt_Buffer)
            render.SetMaterial(mat_Add)

            render.DrawScreenQuadEx(0, 0, ScrW() + self.HaloWidth, ScrH() + self.HaloWidth)
            render.DrawScreenQuadEx(0, 0, ScrW() - self.HaloWidth, ScrH() - self.HaloWidth)
        render.SetStencilEnable(false)

        render.SetStencilTestMask(0)
        render.SetStencilWriteMask(0)
        render.SetStencilReferenceValue(0)
    end
end

function GM:AddQuadDraw(tab)
    table.insert(self.QuadDraws, tab)
end

local glowmat = Material("dev/glow_color")
function GM:PostDrawOpaqueRenderables()
    for i, tab in ipairs(self.QuadDraws) do
        local fraction = math.TimeFraction(tab.Delta, tab.EndTime, CurTime())
        local w, h = 0, 0
        if tab.bGrow then
            w = Lerp(fraction, 0, tab.TexW)
            h = Lerp(fraction, 0, tab.TexH)
        else
            w = Lerp(fraction, tab.TexW, 0)
            h = Lerp(fraction, tab.TexH, 0)
        end
        
        render.SuppressEngineLighting(true)
        render.OverrideDepthEnable(true, true)
        
        render.SetMaterial(tab.Material)
        render.DrawQuadEasy(tab.Pos + Vector( 0, 0, 1 ), Vector(0, 0, 1), w, h, Color(255, 255, 255))     
        
        render.OverrideDepthEnable(false, false)
        render.SuppressEngineLighting(false)
        
        if fraction >= 1 then table.remove(self.QuadDraws, i) end
    end
    
    if LocalPlayer():IsZM() then
        if cvars.Number("zm_vision_quality", 0) >= 2 then
            if cvars.Bool("zm_silhouette_zmvision_only") and not self.nightVision then return end
            
            render.MaterialOverride(glowmat)
            render.OverrideDepthEnable(true, false)

            render.SetStencilEnable(true)

            render.SetStencilReferenceValue(2)
            render.SetStencilWriteMask(2)
            render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
            render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
            render.SetStencilFailOperation(STENCILOPERATION_KEEP)
            render.SetStencilZFailOperation(STENCILOPERATION_KEEP)

            render.SetBlend(0)
            render.OverrideAlphaWriteEnable(true, false)
            render.OverrideColorWriteEnable(true, false)

            for k, v in pairs(self.SilhouetteEnts) do
                if not v.ShouldDrawSilhouette then continue end
                
                v.DrawingSilhouette = true
                v:DrawModel()
                v.DrawingSilhouette = false
            end

            render.OverrideAlphaWriteEnable(false, true)
            render.OverrideColorWriteEnable(false, true)

            render.OverrideDepthEnable(false, false)

            render.SetStencilReferenceValue(3)
            render.SetStencilTestMask(2)
            render.SetStencilWriteMask(1)
            render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_NOTEQUAL)
            render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
            render.SetStencilZFailOperation(STENCILOPERATION_REPLACE)
            render.SetStencilFailOperation(STENCILOPERATION_KEEP)

            render.SetBlend(1)
            local brightness = cvars.Number("zm_cl_silhouette_strength", 1)
            render.SetColorModulation((self.SilhouetteColor.r/255) * brightness, (self.SilhouetteColor.g/255) * brightness, (self.SilhouetteColor.b/255) * brightness)

            for k, v in pairs(self.SilhouetteEnts) do
                if not v.ShouldDrawSilhouette then continue end
                
                v.DrawingSilhouette = true
                v:DrawModel()
                v.DrawingSilhouette = false
            end

            render.MaterialOverride()
            render.SetStencilEnable(false)
        end
    end
end

local spec_overlay = Material("zm_overlay.png", "smooth unlitgeneric nocull")
function GM:RenderScreenspaceEffects()
    if LocalPlayer():IsSpectator() then
        if not self:GetRoundActive() and IsValid(self.PlayerLobby) then
            DrawColorModify(lobbyMenu_ColorMod)
        else
            render.SetMaterial(spec_overlay)
            render.DrawScreenQuad()
        end
    elseif LocalPlayer():IsZM() then
        if self.nightVision then
            if cvars.Number("zm_cl_nightvision_type") == 0 then
                self.nightVisionCur = self.nightVisionCur or 0.5
                
                if self.nightVisionCur < 0.995 then 
                    self.nightVisionCur = self.nightVisionCur + 0.02 *(1 - self.nightVisionCur)
                end
            
                nightVision_ColorMod["$pp_colour_brightness"] = self.nightVisionCur * 0.8
                nightVision_ColorMod["$pp_colour_contrast"]   = self.nightVisionCur * 1.1
            
                DrawColorModify(nightVision_ColorMod)
                DrawBloom(0, self.nightVisionCur * 3.6, 0.1, 0.1, 1, self.nightVisionCur * 0.5, 0, 1, 0)
            else
                local dlight = DynamicLight(LocalPlayer():EntIndex())
                if dlight then
                    dlight.pos = EyePos()
                    dlight.r = 255
                    dlight.g = 25
                    dlight.b = 8
                    dlight.brightness = 6
                    dlight.Decay = 1000
                    dlight.Size = 2048
                    dlight.DieTime = CurTime() + 5
                end
            end
        end
    end
end

function GM:RestartRound()
    gamemode.Call("RemoveZMPanels")
    
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

function GM:RemoveZMPanels()
    if IsValid(self.trapPanel) then
        trapPanel:Remove()
    end
    
    if IsValid(self.powerMenu) then
        self.powerMenu:Remove()
    end
    
    if IsValid(self.ToolPan_Center) then
        self.ToolPan_Center_Tip:Remove()
    end
    
    if IsValid(self.ToolLab_Center_Tip) then
        self.ToolLab_Center_Tip:Remove()
    end
    
    if IsValid(self.InfoHUD) then
        self.InfoHUD:Remove()
    end
end
    
function GM:OnScreenSizeChange(new_w, new_h)
    -- This could be unwise but it seems to be the only way to fresh font sizes
    hook.Call("SetupFonts", GAMEMODE)
    
    if IsValid(LocalPlayer().QuickInfo) then
        LocalPlayer().QuickInfo:Remove()
        
        LocalPlayer().QuickInfo = vgui.Create("CHudQuickInfo")
        LocalPlayer().QuickInfo:Center()
    end  
    
    -- Couldn't figure out how to fix the panel sizing getting screwed up when changing to a lower res, recreating the panel fixes it
    if LocalPlayer():IsZM() and IsValid(self.powerMenu) then
        self.powerMenu:Remove()
        self.powerMenu = vgui.Create("zm_powerpanel")
        
        gamemode.Call("SetupZMPowers")
    end
end

function GM:PlayerSwitchWeapon(ply, oldwep, newwep)
    if IsValid(ply.QuickInfo) then
        if newwep.DrawQuickInfo and not ply.QuickInfo:IsVisible() then
            ply.QuickInfo:SetVisible(true)
        elseif not newwep.DrawQuickInfo and ply.QuickInfo:IsVisible() then
            ply.QuickInfo:SetVisible(false)
        end
    end
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
        if not ent:IsScripted() then return end
        ent:BecomeRagdollOnClient()
    end
end)

net.Receive("PlayerKilledByNPC", function(length)
    local victim = net.ReadEntity()
    if not IsValid(victim) then return end
    
    local inflictor    = net.ReadString()
    local attacker    = net.ReadString()
    
    GAMEMODE:AddDeathNotice(attacker, TEAM_ZOMBIEMASTER, inflictor, victim:Name(), victim:Team())
end)

net.Receive("PlayerKilled", function(length)
    local victim = net.ReadEntity()
    if not IsValid(victim) then return end
    
    local inflictor    = net.ReadString()
    local attacker = translate.Get("killmessage_something")
    
    GAMEMODE:AddDeathNotice(attacker, TEAM_UNASSIGNED, inflictor, victim:Name(), victim:Team())
end)

net.Receive("zm_coloredprintmessage", function(length)
    util.PrintMessage(net.ReadString(), LocalPlayer(), net.ReadTable())
end)

net.Receive("zm_sendlua", function(length)
    RunString(net.ReadString(), "SendLua")
end)

net.Receive("zm_updateclientreadytable", function(length)
    local bFullUpdate = net.ReadBool()
    if bFullUpdate then
        GAMEMODE.playerReadyList = net.ReadTable()
        return
    end
    
    local pl = net.ReadEntity()
    if not IsValid(pl) then return end
    
    local bReady = net.ReadBool()
    GAMEMODE.playerReadyList[pl] = bReady
end)