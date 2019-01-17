if CLIENT then return end

ENT.Type = "brush"

function ENT:Initialize()
    self.m_bActive = self.m_bActive or false
    self:AddEFlags(EFL_FORCE_CHECK_TRANSMIT)
end

function ENT:KeyValue( key, value )
    key = string.lower(key)
    if key == "active" then
        self.m_bActive = tonumber(value) == 1
    end
end

function ENT:AcceptInput(name, caller, activator, arg)
    name = string.lower(name)
    if name == "toggle" then
        self:InputToggle()
        return true
    elseif name == "enable" then
        self:InputEnable()
        return true
    elseif name == "disable" then
        self:InputDisable()
        return true
    end
end

function ENT:InputToggle()
    self.m_bActive = not self.m_bActive
end

function ENT:InputDisable()
    self.m_bActive = false
end

function ENT:InputEnable()
    self.m_bActive = true
end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end