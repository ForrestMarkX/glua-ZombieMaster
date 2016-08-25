NPC.Class = ""
NPC.Name = ""
NPC.Description = ""
NPC.Icon = ""
NPC.Flag = 0
NPC.Cost = 0
NPC.PopCost = 0
NPC.SortIndex = 0

NPC.Hidden = true

NPC.Health = 0
NPC.Model = {}

if SERVER then
	NPC.SpawnFlags = bit.bor(SF_ZOMBIE_WANDER_ON_IDLE, SF_NPC_FADE_CORPSE, SF_NPC_ALWAYSTHINK, SF_NPC_NO_PLAYER_PUSHAWAY)
	NPC.Capabilities = nil

	NPC.Friends = {"npc_zombie", "npc_poisonzombie", "npc_burnzombie", "npc_dragzombie"}
end

function NPC:OnSpawned(npc)
	npc:SetBloodColor(BLOOD_COLOR_RED)
	
	npc:SetKeyValue("wakeradius", 32768)
	npc:SetKeyValue("wakesquad", 1)
	npc:SetNPCState(NPC_STATE_IDLE)
	
	if self.Capabilities then
		npc:CapabilitiesClear()
		npc:CapabilitiesAdd(self.Capabilities)
	end
	
	if self.Health and self.Health ~= 0 then
		npc:SetHealth(self.Health)
	end
end

function NPC:OnScaledDamage(npc, hitgroup, dmginfo)
end

function NPC:OnTakeDamage(npc, attacker, inflictor, dmginfo)
	local damage = dmginfo:GetDamage()
	if npc:Health() <= damage then
		dmginfo:SetDamageType(bit.bor(dmginfo:GetDamageType(), DMG_REMOVENORAGDOLL))
	end
	
	local atkowner = attacker.OwnerClass
	if IsValid(attacker) and attacker:GetClass() == "env_fire" and atkowner and atkowner == "npc_burnzombie" then
		dmginfo:SetDamageType(DMG_GENERIC)
		dmginfo:SetDamage(0)
		dmginfo:ScaleDamage(0)
		return
	end
	
	if not IsValid(npc:GetEnemy()) and IsValid(attacker) then
		npc:ForceGotoEnemy(attacker, attacker:GetPos())
		
		for k, v in pairs(npcs.FindByClass("npc_*")) do
			if IsValid(v) and v:IsNPC() and not IsValid(v:GetEnemy()) then
				npc:ForceGotoEnemy(v, attacker:GetPos())
			end
		end
	end
end

function NPC:OnKilled(npc, attacker, inflictor)
	local owner = npc:GetOwner()
	if IsValid(owner) and owner:IsPlayer() then
		local popCost = self.PopCost
		local population = GAMEMODE:GetCurZombiePop()

		popCost = popCost or 1

		GAMEMODE:TakeCurZombiePop(popCost)
	end
	
	if IsValid(attacker) and attacker:IsPlayer() then
		attacker:AddFrags(1)
	end
	
	net.Start("zm_spawnclientragdoll")
		net.WriteEntity(npc)
	net.Broadcast()
end