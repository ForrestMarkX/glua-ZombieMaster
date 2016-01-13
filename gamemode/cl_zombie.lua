--[[
	- Angry Lawyer: April 17, 2007 -
	
	Note about ZombieFlags 
	These are set by adding the following numbers together: 

	0 - Everything 
	1 - Shamblers 
	2 - Banshees 
	4 - Hulks 
	8 - Drifters
	16 - Immolators
	
	Max: 31
]]

local function CanSpawnZombie(flag)
	local allowed = {}
	allowed[1] = false
	allowed[2] = false
	allowed[4] = false
	allowed[8] = false
	allowed[16] = false
	
	if flag == 0 then
		return true
	else
		for i = 1, 5 do
			if (flag - 16) >= 0 then
				flag = flag -16
				allowed[16] = true
			end

			if (flag - 8) >= 0 then
				flag = flag -8
				allowed[8] = true
			end

			if (flag - 4) >= 0 then
				flag = flag -4
				allowed[4] = true
			end

			if (flag - 2) >= 0 then
				flag = flag -2
				allowed[2] = true
			end

			if (flag - 1) >= 0 then
				flag = flag -1
				allowed[1] = true
			end
		end
		
		return allowed
	end
	
	return false
end

local zombieMenus = {}

function GM:GetZombieMenus()
	return zombieMenus
end

function GM:ResetZombieMenus()
	for k, v in pairs(zombieMenus) do
		v:Remove()
	end
	
	zombieMenus = {}
end

net.Receive("zm_queue", function(len)
	local type = net.ReadString()
	local id = ents.GetByIndex(net.ReadInt(32))
	local menu = zombieMenus[id]
	
	if menu then
		menu:AddQueue(type)
	end
end)

net.Receive("zm_remove_queue", function(um)
	local id = ents.GetByIndex(net.ReadInt(32))
	local menu = zombieMenus[id]
	
	if menu then
		menu:UpdateQueue()
	end
end)