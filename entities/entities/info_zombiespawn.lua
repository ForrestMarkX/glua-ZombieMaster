AddCSLuaFile()

ENT.Base = "info_node_base"
ENT.Type = "anim"
ENT.Model = Model("models/zombiespawner.mdl")

if CLIENT then
	ENT.GlowMat = Material("models/red2")
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
		return self:SpawnThink()
	end

	function ENT:SpawnThink()
		if #self.query <= 0 then
			self.m_bSpawning = false
			return false
		end
		
		if not self.m_bSpawning then
			return true
		end

		self:NextThink(CurTime() + GetConVar("zm_spawndelay"):GetFloat())

		local current_type = self.query[1]
		if not current_type then return end
		
		local pZM = current_type.ply
		if not IsValid(pZM) then return end

		if (GAMEMODE:GetCurZombiePop() + current_type.popCost) > GAMEMODE:GetMaxZombiePop() or not pZM:CanAfford(current_type.cost) then
			self:NextThink(CurTime() + GetConVar("zm_spawndelay"):GetFloat() + math.Rand(0.1, 0.2))
			return
		end

		self:CreateUnit(current_type)

		net.Start("zm_remove_queue")
			net.WriteInt(self:EntIndex(), 32)
		net.Send(pZM)
	
		table.remove(self.query, 1)
		
		return true
	end
	
	function ENT:CreateUnit(data)
		if self.m_bActive == false then return false end

		local spawnPoint = self:FindValidSpawnPoint()
		if spawnPoint:IsZero() then return false end
		
		local pZM = data.ply
		if not IsValid(pZM) then return false end
		
		local zombie = gamemode.Call("SpawnZombie", data.ply, data.type, spawnPoint + Vector(0, 0, 3), data.ply:GetAngles(), data.cost)
		if not IsValid(zombie) then return false end
		
		timer.Simple(0.25, function()
			if IsValid(self) then
				local rally = self:GetRallyEntity()
				if IsValid(rally) then
					zombie:ForceGo(rally:GetPos())
				end
			end
		end)

		return false
	end
	
	function ENT:KeyValue( key, value )
		self.BaseClass.KeyValue(self, key, value)
		
		key = string.lower(key)
		if key == "zombieflags" then
			self:SetZombieFlags(value)
		elseif key == "rallyname" then
			self.rallyName = value or self.rallyName
			
			timer.Simple(1, function()
				if not IsValid(self) then return end
				
				for _, entity in pairs(ents.FindByName(value)) do
					self:SetRallyEntity(entity)
				end
			end)
		elseif key == "nodename" then
			self.nodeName = value or self.nodeName
		end
	end
	
	--[[
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
		
		local tr = util.TraceHull({
			start = vSpawnPoint,
			endpos = vSpawnPoint + Vector( 0, 0, 1 ),
			maxs = Vector(13, 13, 72),
			mins = Vector(-13, -13, 0),
			mask = MASK_NPCSOLID
		})
		if tr.fraction ~= 1.0 then
			return vector:Zero()
		end
		
		return vector
	end
	--]]

	local nodePoints = {}
	function ENT:FindValidSpawnPoint()
		table.Empty(nodePoints)
		
		if self.nodeName then
			local node = ents.FindByName(self.nodeName)[1]
			while IsValid(node) do
				table.insert(nodePoints, node)
				node = node:GetSpawnNode()
			end
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
				
				local tr = util.TraceHull({
					start = vSpawnPoint,
					endpos = vSpawnPoint - Vector(0, 0, 256),
					maxs = Vector(13, 13, 72),
					mins = Vector(-13, -13, 0),
					mask = MASK_NPCSOLID,
					filter = ents.FindByClass("npc_*")
				})
				if IsValid(tr.Entity) and tr.Entity:IsPlayer() then
					if node_idx ~= -1 then
						table.remove(untried_nodes, node_idx)
					end

					vSpawnPoint:Zero()
					continue
				end
				
				vSpawnPoint = tr.HitPos
			end
			
			local tr = util.TraceHull({
				start = vSpawnPoint,
				endpos = vSpawnPoint + Vector( 0, 0, 1 ),
				maxs = Vector(13, 13, 72),
				mins = Vector(-13, -13, 0),
				mask = MASK_NPCSOLID
			})
			if tr.Fraction ~= 1 then
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
	
	function ENT:StartSpawning()
		self:NextThink(CurTime() + GetConVar("zm_spawndelay"):GetFloat())
		self.m_bSpawning = true
	end
	
	function ENT:AddQuery(ply, zombietype, amount)
		if not self.m_bSpawning then
			self:StartSpawning()
		end
			
		local data = GAMEMODE:GetZombieData(zombietype)

		if data and #self.query < 18 then
			local zombieFlags = self:GetZombieFlags() or 0
			local allowed = gamemode.Call("CanSpawnZombie", data.Flag or 0, zombieFlags)
			if not allowed then return end
			
			if amount > 1 and amount < 19 then
				for i = 1, amount do
					if #self.query == 18 then
						ply:PrintTranslatedMessage(HUD_PRINTTALK, "queue_is_full")
					else
						table.insert(self.query, {type = zombietype, cost = data.Cost, ply = ply, popCost = data.PopCost})
					
						net.Start("zm_queue")
							net.WriteString(zombietype)
							net.WriteInt(self:EntIndex(), 32)
						net.Send(ply)
					end
				end
			else
				table.insert(self.query, {type = zombietype, cost = data.Cost, ply = ply, popCost = data.PopCost})
			
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
			self.query = {}
		else
			if #self.query > 0 then
				table.remove(self.query, 1)
			end
		end
	end
end