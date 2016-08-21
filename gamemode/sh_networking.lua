// Copyright (c) 2014 CodingDirect, LLC

/*
entities = { }
	entity = { }
		var = { key = name, value = value, type = type lastchg = time }
		
enthooks = { }
	entity = { }
		hookent = { }
			var = { 1 }
*/

local ENTITY = FindMetaTable("Entity")

local entities = {}
local changedents = {}
local types = {"Angle", "Bool", "Entity", "Float", "Long", "Short", "String", "Vector"}

local type = type
local SERVER = SERVER
local CLIENT = CLIENT
local Entity = Entity
local CurTime = CurTime
local pairs = pairs
local tostring = tostring
local tobool = tobool
local hook = hook
local tonumber = tonumber

local function set(entity, name, newvalue, ntype)
	if not entities[entity] then
		entities[entity] = {}
	end

	if entities[entity][name] and entities[entity][name].value == newvalue then
		return false
	end
	
	if SERVER then
		if not changedents[entity] then
			changedents[entity] = {}
		end

		changedents[entity][name] = {value = newvalue, type = ntype, delete = false}
	
		if newvalue == nil then
			changedents[entity][name].delete = true
			entities[entity][name] = nil
			return true
		end
	end
	
	entities[entity][name] = {value = newvalue, type = ntype}
	return true
end

local function get(entity, name, default)
	if entities[entity] and entities[entity][name] then
		if entities[entity][name].type == "Entity" then
			local value = Entity(entities[entity][name].value)
			if IsValid(value) then
				return value
			else
				return default
			end
		else
			return entities[entity][name].value
		end
	else
		return default
	end
end

if SERVER then

util.AddNetworkString("shnet_recv_shared")
util.AddNetworkString("shnet_rem_shared")
util.AddNetworkString("shnet_remove_shared")

function syncjoin(Player)
	if Player.LastDemoStart and Player.LastDemoStart >= CurTime() then
		Player:ConCommand("stop")
		return
	end

	Player.LastDemoStart = CurTime() + 5
	
	for ent, vars in pairs(entities) do
		for name, var in pairs(vars) do
			net.Start("shnet_recv_shared")
				net.WriteInt(ent, 32)
				net.WriteString(tostring(name))
				net.WriteString(var.type)
				local ntype = var.type
				if ntype == "Entity" then
					ntype = "Short"
				end
				if ntype == "Long" then
					net.WriteInt(var.value, 32)
				elseif ntype == "Short" then
					net.WriteInt(var.value, 32)
				else
					net["Write"..ntype](var.value)
				end
			net.Send( Player )
		end
	end
end
hook.Add("PlayerInitialSpawn", "syncjoin", syncjoin)
concommand.Add("demorestart", syncjoin)

local function sync()
	for ent, vars in pairs(changedents) do
		for name, var in pairs(vars) do
			if var.delete then
				net.Start("shnet_rem_shared")
					net.WriteInt(ent, 32)
					net.WriteString(tostring(name))
				net.Broadcast()
			else
				net.Start("shnet_recv_shared")
					net.WriteInt(ent, 32)
					net.WriteString(tostring(name))
					net.WriteString(var.type)
					local ntype = var.type
					if ntype == "Entity" then
						ntype = "Short"
					end
					if ntype == "Long" then
						net.WriteInt(var.value, 32)
					elseif ntype == "Short" then
						net.WriteInt(var.value, 32)
					else
						net["Write"..ntype](var.value)
					end
				net.Broadcast()
			end
		end
	end
	changedents = {}
end
hook.Add("Tick", "netsync", sync)

local function entremoved(ent)
	local index = ent:EntIndex()
	net.Start("shnet_remove_shared")
		net.WriteInt(index, 32)
	net.Broadcast()
	entities[index] = nil
	
	for entity, vars in pairs(changedents) do
		for name, var in pairs(vars) do
			if var.type == "Entity" and var.value == index then
				entities[entity][name] = nil
				
				if not changedents[entity] then
					changedents[entity] = {}
				end

				changedents[entity][name] = {delete = true}
			end
		end
	end
end
hook.Add("EntityRemoved", "netentremoved", entremoved)

else

local function receive(len, ply)
	local index = net.ReadInt(32)
	local name = net.ReadString()
	local ntype = net.ReadString()
	if ntype == "Entity" then
		local value = net.ReadInt(32)
		set(index, name, value, ntype)
	else
		local value
		if ntype == "Long" then
			value = net.ReadInt(32)
		elseif ntype == "Short" then
			value = net.ReadInt(32)
		elseif ntype == "Bit" then
			value = tobool(net.ReadBit())
		else
			value = net["Read" .. ntype]()
		end
		set(index, name, value, ntype)
	end
end
net.Receive("shnet_recv_shared", receive)

local function removed(len, ply)
	local index = net.ReadInt(32)
	local name = net.ReadString()
	if entities[index] then
		entities[index][name] = nil
	end
end
net.Receive("shnet_rem_shared", removed)

local function entremoved(len, ply)
	local index = net.ReadInt(32)
	entities[index] = nil
end
net.Receive("shnet_remove_shared", entremoved)

end

// ENTITY Shared Networking.

function ENTITY:GetSharedAngle(name, default)
	return get(self:EntIndex(), name, default)
end

function ENTITY:GetSharedBool(name, default)
	return get(self:EntIndex(), name, default)
end

function ENTITY:GetSharedEntity(name, default)
	return get(self:EntIndex(), name, default)
end

function ENTITY:GetSharedFloat(name, default)
	return get(self:EntIndex(), name, default)
end

function ENTITY:GetSharedInt(name, default)
	if default == nil then
		default = 0
	end
	return get(self:EntIndex(), name, default)
end

function ENTITY:GetSharedString(name, default)
	return get(self:EntIndex(), name, default)
end

function ENTITY:GetSharedVector( name, default )
	return get(self:EntIndex(), name, default);
end

function ENTITY:SetSharedAngle(name, value)
	return set(self:EntIndex(), name, value, "Angle")
end

function ENTITY:SetSharedBool(name, value)
	return set(self:EntIndex(), name, value, "Bit")
end

function ENTITY:SetSharedEntity(name, value)
	if IsValid(value) then
		return set(self:EntIndex(), name, value:EntIndex(), "Entity")
	else
		return set(self:EntIndex(), name, nil, "Entity")
	end
end

function ENTITY:SetSharedFloat(name, value)
	return set(self:EntIndex(), name, value, "Float")
end

function ENTITY:SetSharedInt(name, value)
	value = tonumber(value)
	return set(self:EntIndex(), name, value, "Long")
end

function ENTITY:SetSharedString(name, value)
	return set(self:EntIndex(), name, tostring(value), "String")
end

function ENTITY:SetSharedVector(name, value)
	return set(self:EntIndex(), name, value, "Vector")
end

// Global Shared Networked.

function GetSharedAngle(name, default)
	return get(-1, name, default)
end

function GetSharedBool(name, default)
	return get(-1, name, default)
end

function GetSharedEntity(name, default)
	return get(-1, name, default)
end

function GetSharedFloat(name, default)
	return get(-1, name, default)
end

function GetSharedInt(name, default)
	if default == nil then
		default = 0
	end
	return get(-1, name, default)
end

function GetSharedString(name, default)
	return get(-1, name, default)
end

function GetSharedVector(name, default)
	return get(-1, name, default)
end

function SetSharedAngle(name, value)
	return set(-1, name, value, "Angle")
end

function SetSharedBool(name, value)
	return set(-1, name, value, "Bit")
end

function SetSharedEntity(name, value)
	if IsValid(value) then
		return set(-1, name, value:EntIndex(), "Entity")
	else
		return set(-1, name, nil, "Entity")
	end
end

function SetSharedFloat(name, value)
	return set(-1, name, value, "Float")
end

function SetSharedInt(name, value)
	value = tonumber(value)
	return set(-1, name, value, "Long")
end

function SetSharedString(name, value)
	return set(-1, name, tostring(value), "String")
end

function SetSharedVector(name, value)
	return set(-1, name, value, "Vector")
end