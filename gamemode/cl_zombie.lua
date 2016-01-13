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