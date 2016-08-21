if CLIENT then return end

ENT.Type = "brush"

local valid = {
	"prop_physics",
	"func_physbox",
	"prop_physics_override",
	"prop_physics_multiplayer",
	"func_physbox_multiplayer"
}
local function PassesFlag(entity)
	local class = entity:GetClass()
	return table.HasValue(valid, class)
end

function ENT:Initialize()
	self:SetTrigger(true)
	self.m_iCountToFire = self.m_iCountToFire or 0
	self.m_bActive = self.m_bActive or false
	self.m_iTriggerFlags = self.m_iTriggerFlags or 0
	self.Entities = {}
end

function ENT:KeyValue(key, value)
	key = string.lower(key)
	if key == "active" then
		self.m_bActive = tonumber(value) == 1
	elseif key == "counttofire" then
		self.m_iCountToFire = tonumber(value) or self.m_iCountToFire
	elseif key == "triggerflags" then
		self.m_iTriggerFlags = tonumber(value) or self.m_iTriggerFlags
	elseif string.sub(key, 1, 2) == "on" then
		self:AddOnOutput(key, value)
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
	elseif name == "count" then
		if #self.Entities >= self.m_iCountToFire then
			self:Input("OnCount", self)
		else
			self:Input("OnNotCount", self)
		end
	elseif string.sub(name, 1, 2) == "on" then
		self:FireOutput(name, activator, caller, args)
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

function ENT:IsTouchedBy(ent)
	return table.HasValue(self.Entities, ent)
end

function ENT:StartTouch(ent)
	if not self:PassesTriggerFilters(ent) then return end
	table.insert(self.Entities, ent)
end

function ENT:Touch(ent)
	if not self:PassesTriggerFilters(ent) then return end
	if not table.HasValue(self.Entities, ent) then table.insert(self.Entities, ent) end
end

function ENT:EndTouch(ent)
	if not self:IsTouchedBy(ent) then return end
	table.RemoveByValue(self.Entities, ent)
end

function ENT:PassesTriggerFilters(entity)
	local flag = self.m_iTriggerFlags
	return (flag == 1 and entity:IsPlayer() and entity:IsSurvivor()) or (flag == 2 and entity:IsNPC()) or (flag == 3 and PassesFlag(entity))
end