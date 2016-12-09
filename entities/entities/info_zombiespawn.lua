AddCSLuaFile()

ENT.Base = "info_node_base"
ENT.Type = "anim" 
ENT.Model = Model("models/zombiespawner.mdl")

if CLIENT then
	ENT.GlowMat = Material("models/red2")
	ENT.GlowColor = Color( 255, 200, 200 )
	ENT.GlowSize = 128
end

function ENT:SetupDataTables()
	self.BaseClass.SetupDataTables(self)
	self:NetworkVar("Int", 0, "ZombieFlags")
end

function ENT:Initialize()
	self.BaseClass.Initialize(self)

	if SERVER then
		self.m_bDidSpawnSetup = false
		self.m_bSpawning = false
		self.allowspawn = true
		
		self.nodeName = self.nodeName or nil
		self.rallyName = self.rallyName or nil
		self.spawndelay = 0
		self.spawn_queue = {}
	end
end

if SERVER then
	function ENT:SetRallyEntity(entity)
		if self.rallyEntity then
			self.rallyEntity:Remove()
		end
		
		self.rallyEntity = entity
	end
	
	function ENT:GetRallyEntity()
		return self.rallyEntity
	end
	
	function ENT:Think()
		if #self.spawn_queue <= 0 then
			self.m_bSpawning = false
			return
		end
		
		if not self.m_bActive then
			table.Empty(self.spawn_queue)
			return
		end
		
		local data = self.spawn_queue[1]
		if not data then return end
		
		local pZM = data.ply
		if not IsValid(pZM) then return end
		
		local resources, population = data.ply:GetZMPoints(), GAMEMODE:GetCurZombiePop()
		if ((population + data.popCost) > GAMEMODE:GetMaxZombiePop() or pZM:CanAfford(data.cost)) then
			self:NextThink(CurTime + GetConVar("zm_spawndelay"):GetFloat() + math.Rand(0.1, 0.2))
			return true
		end

		local spawnPoint = self:FindValidSpawnPoint()
		if spawnPoint:IsZero() then 
			self:NextThink(CurTime + GetConVar("zm_spawndelay"):GetFloat() + math.Rand(0.1, 0.2))
			return true
		end
		
		local zombie = gamemode.Call("SpawnZombie", data.ply, data.type, spawnPoint + Vector(0, 0, 3), data.ply:GetAngles(), data.cost)
		timer.Simple(0.25, function()
			if IsValid(self) then
				local rally = self:GetRallyEntity()
				if IsValid(rally) then
					zombie:ForceGoto(rally:GetPos())
				end
			end
		end)
		
		table.remove(self.spawn_queue, 1)
		
		net.Start("zm_remove_queue")
			net.WriteUInt(self:EntIndex(), 16)
		net.Send(pZM)
		
		self:NextThink(CurTime() + GetConVar("zm_spawndelay"):GetFloat())
		return true
	end
	
	function ENT:KeyValue( key, value )
		self.BaseClass.KeyValue(self, key, value)
		
		key = string.lower(key)
		if key == "zombieflags" then
			self:SetZombieFlags(value)
		elseif key == "rallyname" then
			self.rallyName = value or self.rallyName
			
			if IsValid(self) then
				for _, entity in ipairs(ents.FindByName(value)) do
					self:SetRallyEntity(entity)
				end
			end
		elseif key == "nodename" then
			self.nodeName = value or self.nodeName
		end
	end

	local nodePoints = {}
	function ENT:FindValidSpawnPoint()
		if not self.m_bDidSpawnSetup then
			table.Empty(nodePoints)
			
			if self.nodeName then
				local node = ents.FindByName(self.nodeName)[1]
				while IsValid(node) do
					table.insert(nodePoints, node)
					node = node:GetSpawnNode()
				end
			end

			self.m_bDidSpawnSetup = true
		end

		local vForward = self:GetAngles():Forward()
		local vSpawnPoint = Vector(0, 0, 0)
		
		local untried_nodes = table.Copy(nodePoints)
		local max_attempts = math.max(25, #untried_nodes)
		
		for i=1, max_attempts do
			local node_idx = -1

			if #untried_nodes > 0 then
				local idx = math.random(0, #untried_nodes - 1)
				local node = untried_nodes[idx]

				if node then
					vSpawnPoint = node:GetPos()
					node_idx = idx
				end
			end

			if node_idx == -1 then
				local xDeviation = math.random(-64, 64)
				local yDeviation = math.random(-64, 64)

				vSpawnPoint = self:GetPos() + (vForward * 32)
				vSpawnPoint.x = vSpawnPoint.x + xDeviation
				vSpawnPoint.y = vSpawnPoint.y + yDeviation
			end

			local tr = util.TraceHull({
				start = vSpawnPoint,
				endpos = vSpawnPoint + Vector( 0, 0, 1 ),
				maxs = Vector(13, 13, 72),
				mins = Vector(-13, -13, 0),
				filter = ents.FindByClass("npc_*"),
				mask = MASK_NPCSOLID
			})
			
			if tr.Fraction ~= 1.0 then
				if node_idx ~= -1 then
					table.remove(untried_nodes, node_idx)
				end

				vSpawnPoint:Zero()
			else 
				break
			end
		end

		return vSpawnPoint
	end
	
	function ENT:InputToggle()
		if self:GetActive() then
			self:SetActive(false)
			self:AddSolidFlags( FSOLID_NOT_SOLID )
			self:AddEffects( EF_NODRAW )
			
			if nodePoints then
				for _, node in pairs(nodePoints) do
					if IsValid(node) then node:AddEffects(EF_NODRAW) end
				end
			end
		else
			self:SetActive(true)
			self:RemoveSolidFlags( FSOLID_NOT_SOLID )
			self:RemoveEffects( EF_NODRAW )
			
			if nodePoints then
				for _, node in pairs(nodePoints) do
					if IsValid(node) then node:RemoveEffects(EF_NODRAW) end
				end
			end
		end
	end

	function ENT:InputHide()
		if self:GetActive() then
			self:SetActive(false)
			self:AddSolidFlags( FSOLID_NOT_SOLID )
			self:AddEffects( EF_NODRAW )
			
			if nodePoints then
				for _, node in pairs(nodePoints) do
					if IsValid(node) then  node:AddEffects(EF_NODRAW) end
				end
			end
		end
	end

	function ENT:InputUnhide()
		self:SetActive(true)
		self:RemoveSolidFlags( FSOLID_NOT_SOLID )
		self:RemoveEffects( EF_NODRAW )
		
		if nodePoints then
			for _, node in pairs(nodePoints) do
				if IsValid(node) then node:RemoveEffects(EF_NODRAW) end
			end
		end
	end
	
	function ENT:AddQuery(ply, zombietype, amount)
		local data = GAMEMODE:GetZombieData(zombietype)

		if data and #self.spawn_queue < 18 then
			local zombieFlags = self:GetZombieFlags() or 0
			local allowed = gamemode.Call("CanSpawnZombie", data.Flag or 0, zombieFlags)
			if not allowed then return end
			
			if amount > 1 and amount < 19 then
				for i = 1, amount do
					if #self.spawn_queue == 18 then
						ply:PrintTranslatedMessage(HUD_PRINTTALK, "queue_is_full")
					else
						table.insert(self.spawn_queue, {type = zombietype, cost = data.Cost, ply = ply, popCost = data.PopCost})
					
						net.Start("zm_queue")
							net.WriteString(zombietype)
							net.WriteInt(self:EntIndex(), 32)
						net.Send(ply)
					end
				end
			else
				table.insert(self.spawn_queue, {type = zombietype, cost = data.Cost, ply = ply, popCost = data.PopCost})
			
				net.Start("zm_queue")
					net.WriteString(zombietype)
					net.WriteInt(self:EntIndex(), 32)
				net.Send(ply)
			end
		else
			ply:PrintTranslatedMessage(HUD_PRINTTALK, "queue_is_full")
		end
	end

	function ENT:ClearQueue(clear)
		if clear then
			self.spawn_queue = {}
		else
			if #self.spawn_queue > 0 then
				table.remove(self.spawn_queue, #self.spawn_queue)
			end
		end
	end
end