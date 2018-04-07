local PANEL = {}

function PANEL:Init()
    self:SetMouseInputEnabled(true)
    self:SetKeyboardInputEnabled(true)
    self:SetCursor("hand")
end

function PANEL:OnMousePressed(code)
    if code == MOUSE_FIRST then
        self:DoClick()
    end
end

function PANEL:SetEnabled(b)
    if not b then
        self:SetMouseInputEnabled(false)
        self:SetKeyboardInputEnabled(false)
        self:SetCursor("none")
    else
        self:SetMouseInputEnabled(true)
        self:SetKeyboardInputEnabled(true)
        self:SetCursor("hand")
    end
end

function PANEL:DoClick()
end

vgui.Register("DClickableAvatar", PANEL, "AvatarImage")