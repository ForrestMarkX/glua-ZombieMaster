local zombieData = {}
function GM:AddZombieType(name, data)
	zombieData[name] = data
end

function GM:GetZombieTable(bShowDefault)
	local zombietab = table.Copy(zombieData)
	if not bShowDefault then
		zombietab["class_default"] = nil
	end
	
	return zombietab
end

function GM:GetZombieData(class)
	for _, data in pairs(zombieData) do
		if data.Class == class then
			return data
		end
	end
end

function GM:CallZombieFunction(npc, func, ...)
	local zombie = self:GetZombieData(npc:GetClass())
	if not zombie then return end
	
	local func_tocall = zombie[func]
	if func_tocall then
		return func_tocall(zombie, npc, ...)
	end
end

function GM:BuildZombieDataTable()
	for k, v in pairs(zombieData) do
		if k ~= "class_default" then
			if not v.Base then v.Base = "class_default" end
			local basetable = zombieData[v.Base]
			if basetable then
				table.Inherit(v, basetable)
			end
		end
		
		baseclass.Set(k, v)
	end
end

function GM:CanSpawnZombie(flag, iZombieFlags)
	return iZombieFlags <= 0 or bit.band(iZombieFlags, flag) ~= 0
end

function GM:GetCurZombiePop()
	return GetGlobalInt("m_iZombiePopCount", 0)
end

function GM:GetMaxZombiePop()
	return GetConVar("zm_zombiemax"):GetInt()
end

local function AddZombieTypes(filename, directory, bWasFolderType)
	local fname = string.StripExtension(string.lower(filename))
	if bWasFolderType and (fname == "init" or fname == "shared" or fname == "cl_init") then
		if SERVER and fname == "cl_init" then 
			AddCSLuaFile(directory)
			return
		elseif CLIENT and fname == "init" then 
			return
		end
		
		if SERVER and fname ~= "init" then AddCSLuaFile(directory) end
		include(directory)
	elseif not bWasFolderType then
		AddCSLuaFile(directory)
		include(directory)
	end
end

local path = GM.FolderName.."/gamemode/zombies/"
local files, directories = file.Find(path.."*", "LUA")
for i, directory in ipairs(directories) do
	NPC = {}
	for i, filename in ipairs(file.Find(path..directory.."/*.lua", "LUA")) do
		AddZombieTypes(filename, "zombies/"..directory.."/"..filename, true)
	end
	GM:AddZombieType(directory, NPC)
	NPC = nil
end

for i, filename in ipairs(files) do
	if string.GetExtensionFromFilename(filename) == "lua" then
		NPC = {}
		AddZombieTypes(filename, "zombies/"..filename)
		GM:AddZombieType(string.StripExtension(filename), NPC)
		NPC = nil
	end
end