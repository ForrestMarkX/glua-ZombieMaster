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

function GM:CallZombieFunction(class, func, ...)
	local zombie = self:GetZombieData(class)
	if not zombie then return end
	
	local func_tocall = zombie[func]
	if func_tocall then
		return func_tocall(zombie, ...)
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

for i, filename in ipairs(file.Find(GM.FolderName.."/gamemode/zombies/*.lua", "LUA")) do
	AddCSLuaFile("zombies/"..filename)
	NPC = {}
	include("zombies/"..filename)
	
	GM:AddZombieType(string.StripExtension(filename), NPC)
	
	NPC = nil
end