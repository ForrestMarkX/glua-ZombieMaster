AddCSLuaFile()

ENT.Base = "info_node_base"
ENT.Type = "anim"
ENT.Model = Model("models/zombiespawner.mdl")

if CLIENT then
	ENT.GlowColor = Color( 237, 37, 37 )
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
		self.query = {}
	end
end

if SERVER then
	local function ComputeZM(ply, resources, population, cost, popCost)
		ply:TakeZMPoints(cost)
		gamemode.Call("SetCurZombiePop", GAMEMODE:GetCurZombiePop() + popCost)
	end
	
	function ENT:Think()
		if #self.query > 0 then
			local data = self.query[1]
			
			if data then
				local resources, population = data.ply:GetZMPoints(), GAMEMODE:GetCurZombiePop()

				if population + data.popCost < GAMEMODE:GetMaxZombiePop() and data.ply:CanAfford(data.cost) then
					local spawnPoint, node = self:FindValidSpawnPoint()
					
					if not node then
						local trace  = {}
						trace.start  = spawnPoint
						trace.endpos = trace.start + Vector(0, 0, 1)
						trace.mask 	 = MASK_NPCSOLID
					
						local tr = util.TraceLine(trace)

						if tr.Fraction >= 1 then
							local entity = ents.Create(data.type)
							entity:SetPos(spawnPoint + Vector(0, 0, 3))
							entity:Spawn()
							entity:SetOwner(data.ply)
							entity.popCost = data.popCost
							
							timer.Simple(0.5, function()
								if IsValid(self) and self:GetRallyEntity() then
									entity:SetLastPosition(self:GetRallyEntity():GetPos())
									entity:SetSchedule(SCHED_FORCED_GO_RUN)
								end
							end)
						
							ComputeZM(data.ply, resources, population, data.cost, data.popCost)
						
							net.Start("zm_remove_queue")
								net.WriteInt(self:EntIndex(), 32)
							net.Send(data.ply)
						
							table.remove(self.query, 1)
						end
					else
						local entity = ents.Create(data.type)
						entity:SetPos(spawnPoint + Vector(0, 0, 3))
						entity:Spawn()
						entity:SetOwner(data.ply)
						entity.popCost = data.popCost
						
						timer.Simple(0.5, function()
							if IsValid(self) and self:GetRallyEntity() then
								entity:SetLastPosition(self:GetRallyEntity():GetPos())
								entity:SetSchedule(SCHED_FORCED_GO_RUN)
							end
						end)

						ComputeZM(data.ply, resources, population, data.cost, data.popCost)
					
						net.Start("zm_remove_queue")
							net.WriteInt(self:EntIndex(), 32)
						net.Send(data.ply)
					
						table.remove(self.query, 1)
					end
				end
			end
		end
		
		self:NextThink(CurTime() + GetConVar("zm_spawndelay"):GetFloat())
		return true
	end
	
	function ENT:SetRallyEntity(entity)
		if self.rallyEntity then
			self.rallyEntity:Remove()
		end
		
		self.rallyEntity = entity
	end
	
	function ENT:GetRallyEntity()
		return self.rallyEntity
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
	
	function ENT:GetSuitableVector()
		local vector = self:GetPos()
		local random = math.random(1, 4)
		
		if random == 1 then
			vector = vector + (self:GetAngles():Forward() * 64)
		elseif random == 2 then
			vector = vector + (self:GetAngles():Forward() * -64)
		elseif random == 3 then
			vector = vector + (self:GetAngles():Right() * 64)
		elseif random == 4 then
			vector = vector + (self:GetAngles():Right() * -64)
		end
		
		local trace = {}
		trace.start = vector
		trace.endpos = trace.start - Vector(0, 0, 999999)
		trace.mask 	 = MASK_NPCSOLID
		trace.filter = {self}
		
		local tr = util.TraceLine(trace)
		
		if tr.HitPos then
			return tr.HitPos
		end
	end

	local nodePoints = {}
	function ENT:FindValidSpawnPoint()
		local isNode = false
		
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

		local vSpawnPoint = Vector(0,0,0)

		for _, node in pairs(nodePoints) do
			local taken  = false
			local entities = ents.FindByClass("npc_*")
			
			for k, v in pairs(entities) do
				if IsValid(v) and node:GetPos():Distance(v:GetPos() + Vector(0, 0, 25)) < 40 then
					taken = true
				end
			end
			
			if not taken then
				vSpawnPoint = node:GetPos()
				isNode = true
				break
			end
		end
		
		if not vSpawnPoint then
			vSpawnPoint = self:GetSuitableVector()
		end

		return vSpawnPoint, isNode
	end
	
	function ENT:AddQuery(ply, type, amount)
		local data = GAMEMODE:GetZombieData(type)

		if data and #self.query < 14 then
			if amount > 1 then
				for i = 1, amount do
					if #self.query == 14 then
						ply:PrintMessage(HUD_PRINTTALK, "Queue is full!")
					else
						table.insert(self.query, {type = type, cost = data.cost, ply = ply, popCost = data.popCost})
					
						net.Start("zm_queue")
							net.WriteString(type)
							net.WriteInt(self:EntIndex(), 32)
						net.Send(ply)
					end
				end
			else
				table.insert(self.query, {type = type, cost = data.cost, ply = ply, popCost = data.popCost})
			
				net.Start("zm_queue")
					net.WriteString(type)
					net.WriteInt(self:EntIndex(), 32)
				net.Send(ply)
			end
		else
			ply:PrintMessage(HUD_PRINTTALK, "Queue is full!")
		end
	end

	function ENT:ClearQueue(clear)
		if clear then
			self.query = {}
		else
			if #self.query > 0 then
				table.remove(self.query, 1)
			end
		end
	end
end