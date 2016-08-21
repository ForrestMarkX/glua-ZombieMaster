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
		if #self.query > 0 then
			local data = self.query[1]
			
			if data and IsValid(data.ply) then
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
							local zombie = gamemode.Call("SpawnZombie", data.ply, data.type, spawnPoint + Vector(0, 0, 3), data.ply:GetAngles(), data.cost)
							
							timer.Simple(0.5, function()
								if IsValid(self) then
									local rally = self:GetRallyEntity()
									if IsValid(rally) then
										zombie:ForceGoto(rally:GetPos())
									end
								end
							end)
						
							net.Start("zm_remove_queue")
								net.WriteInt(self:EntIndex(), 32)
							net.Send(data.ply)
						
							table.remove(self.query, 1)
						end
					else
						local zombie = gamemode.Call("SpawnZombie", data.ply, data.type, spawnPoint + Vector(0, 0, 3), data.ply:GetAngles(), data.cost)
						
						timer.Simple(0.5, function()
							if IsValid(self) then
								local rally = self:GetRallyEntity()
								if IsValid(rally) then
									zombie:ForceGoto(rally:GetPos())
								end
							end
						end)
					
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
		local vector = Vector(0, 0, 0)
		repeat
			local angle = self:GetAngles()
			local vForward = angle:Forward()
			local vRight = angle:Right()
			local vUp = angle:Up()
			
			local xDeviation = math.random(-128, 128)
			local yDeviation = math.random(-128, 128)

			vector = self:GetPos() + (vForward * 64)
			vector.x = vector.x + xDeviation
			vector.y = vector.y + yDeviation
		until util.IsInWorld(vector)
		
		local entities = ents.FindInBox(vector + Vector(-16, -16, 0), vector + Vector(16, 16, 64))
		for k, v in pairs(entities) do
			if IsValid(v) and v:IsNPC() then
				return self:GetSuitableVector()
			end
		end
		
		return vector
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
		
		if vSpawnPoint:IsZero() then
			vSpawnPoint = self:GetSuitableVector()
		end

		return vSpawnPoint, isNode
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

		if data and #self.query < 18 then
			local zombieFlags = self:GetZombieFlags() or 0
			local allowed = gamemode.Call("CanSpawnZombie", zombieFlags)
			if allowed and type(allowed) == "table" and not allowed[data.flag] then return end
			
			if amount > 1 and amount < 19 then
				for i = 1, amount do
					if #self.query == 18 then
						ply:PrintMessage(HUD_PRINTTALK, "Queue is full!")
					else
						table.insert(self.query, {type = zombietype, cost = data.cost, ply = ply, popCost = data.popCost})
					
						net.Start("zm_queue")
							net.WriteString(zombietype)
							net.WriteInt(self:EntIndex(), 32)
						net.Send(ply)
					end
				end
			else
				table.insert(self.query, {type = zombietype, cost = data.cost, ply = ply, popCost = data.popCost})
			
				net.Start("zm_queue")
					net.WriteString(zombietype)
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