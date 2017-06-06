NPC.Class = ""
NPC.Name = ""
NPC.Description = ""
NPC.Icon = ""
NPC.Flag = 0
NPC.Cost = 0
NPC.PopCost = 0
NPC.SortIndex = 0

NPC.Hidden = true
NPC.DelaySetModel = false

NPC.Health = 0
NPC.Model = "models/zombie/zm_classic.mdl"
NPC.HullType = HULL_HUMAN
NPC.SolidType = SOLID_BBOX
NPC.MoveType = MOVETYPE_STEP
NPC.SkinNum = 3
NPC.BloodColor = BLOOD_COLOR_RED

if SERVER then
	NPC.SpawnFlags = bit.bor(SF_NPC_LONG_RANGE, SF_NPC_FADE_CORPSE, SF_NPC_ALWAYSTHINK, SF_NPC_NO_PLAYER_PUSHAWAY)
	NPC.Capabilities = bit.bor(CAP_MOVE_GROUND, CAP_INNATE_MELEE_ATTACK1, CAP_SQUAD, CAP_SKIP_NAV_GROUND_CHECK, CAP_OPEN_DOORS)
end

function NPC:OnSpawned(npc)
	npc:SetBloodColor(self.BloodColor)
	
	if self.Capabilities then
		npc:CapabilitiesClear()
		npc:CapabilitiesAdd(self.Capabilities)
	end
	
	if self.HullType then
		npc:SetHullType(self.HullType)
	end
	
	if self.HullSizeMins and self.HullSizeMaxs then
		timer.Simple(0.1, function()
			if not IsValid(npc) then return end
			npc:SetCollisionBounds(self.HullSizeMins, self.HullSizeMaxs)
		end)
	end
	
	if (self.SkinNum or 0) > 0 then
		npc:SetSkin(math.random(0, self.SkinNum))
	end
	
	npc.IsEngineNPC = self.IsEngineNPC
	npc.NextBreakableScan = CurTime()
	
	npc:SetSolid(self.SolidType)
	npc:SetMoveType(self.MoveType)
	npc:SetNW2Bool("selected", false)
	npc:SetNW2Bool("bDead", false)
	
	if self.Health and self.Health ~= 0 then
		npc:SetHealth(self.Health)
	end
	
	if self.MaxYawSpeed then
		npc:SetMaxYawSpeed(self.MaxYawSpeed)
	end

	npc:UpdateEnemy(npc:FindEnemy())
end

function NPC:SetupModel(npc)
	if not self.Model then return end
	
	local mdl = ""
	if type(self.Model) == "table" then
		mdl = self.Model[math.random(#self.Model)]
	else
		mdl = self.Model
	end
	
	if self.DelaySetModel then
		npc:SetModelDelayed(0, mdl)
	else
		npc:SetModel(mdl)
	end
	
	npc.CurrentModel = mdl
end

function NPC:OnScaledDamage(npc, hitgroup, dmginfo)
	local damagetype = dmginfo:GetDamageType()
	if damagetype ~= DMG_CLUB then
		if hitgroup == HITGROUP_HEAD then
			if bit.band(damagetype, DMG_BUCKSHOT) ~= 0 then
				local flDist = 1024
				if IsValid(dmginfo:GetAttacker()) then
					flDist = (npc:GetPos() - dmginfo:GetAttacker():GetPos()):Length()
				end

				if flDist <= ZOMBIE_BUCKSHOT_TRIPLE_DAMAGE_DIST then
					dmginfo:ScaleDamage(3)
				end
			else
				dmginfo:ScaleDamage(2)
			end
		elseif hitgroup == HITGROUP_LEFTLEG or hitgroup == HITGROUP_RIGHTLEG then
			dmginfo:ScaleDamage(0.25)
		end
	end
end

function NPC:OnTakeDamage(npc, attacker, inflictor, dmginfo)
	local damage = dmginfo:GetDamage()
	if damage > 0 and bit.band(dmginfo:GetDamageType(), DMG_BULLET) ~= 0 then
		local effect = EffectData()
			effect:SetOrigin(dmginfo:GetDamagePosition())
			effect:SetMagnitude(math.Rand(damage * 0.25, damage * 0.6))
			effect:SetScale(math.max(128, math.Rand(damage, damage * 4)))
		util.Effect("bloodstream", effect)
	end
	
	if IsValid(attacker) then
		local atkowner = attacker:GetOwner()
		if IsValid(attacker) and attacker:GetClass() == "env_fire" and IsValid(atkowner) and atkowner:GetClass() == "npc_burnzombie" then
			dmginfo:SetDamageType(DMG_BULLET)
			dmginfo:SetDamage(0)
			dmginfo:ScaleDamage(0)
			return true
		end
		
		if not IsValid(npc:GetEnemy()) and attacker:IsPlayer() then
			if npc.UpdateEnemy then
				npc:UpdateEnemy(attacker)
			else
				npc:SetEnemy(attacker)
				npc:SetTarget(attacker)
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
	
	if npc.IsEngineNPC then
		npc:SetModel(npc.CurrentModel)
	else
		net.Start("zm_spawnclientragdoll")
			net.WriteEntity(npc)
		net.Broadcast()
	end
	
	if IsValid(attacker) and attacker:IsPlayer() then
		attacker:AddFrags(1)
	end
end

function NPC:Think(npc)
	if npc:HasCondition(COND_RECEIVED_ORDERS) then
		npc.FoundBreakable = false
		npc.BreakableEnt = nil
		npc.NextBreakableScan = CurTime() + 5.0
	end
	
	if (npc.NextBreakableScan and CurTime() >= npc.NextBreakableScan) or npc.FoundBreakable then
		local enemy = npc:GetEnemy()
		if not (IsValid(enemy) and enemy:IsPlayer()) then
			if not IsValid(npc.BreakableEnt) then
				for _, ent in pairs(ents.FindInSphere(npc:WorldSpaceCenter(), 64)) do
					if string.sub(ent:GetClass(), 0, 5) == "func_" then
						if ent:Health() > 0 and not ent:IsNPC() and not ent:IsPlayer() then
							npc.BreakableEnt = ent
							npc.FoundBreakable = true
							npc:UpdateEnemy(ent)
							break
						end
					end
				end
				
				if not IsValid(npc.BreakableEnt) and npc.FoundBreakable then
					npc.FoundBreakable = false
				end
			else
				if npc:GetPos():Distance(npc.BreakableEnt:GetPos()) < (npc.GetClawAttackRange and npc:GetClawAttackRange() or 72) and not npc:IsCurrentSchedule(SCHED_MELEE_ATTACK1) then
					npc:SetEnemy(npc.BreakableEnt)
					npc:SetTarget(npc.BreakableEnt)
					npc:SetSchedule(SCHED_TARGET_FACE)
					npc:SetSchedule(SCHED_MELEE_ATTACK1)
					
					if not npc.IsEngineNPC then
						npc.IsAttacking = true
						
						local seq = npc:SelectWeightedSequence(ACT_MELEE_ATTACK1)
						local len = npc:SequenceDuration(seq)
						timer.Simple(len, function()
							if not IsValid(npc) or not IsValid(npc.BreakableEnt) then return end
							npc.BreakableEnt:TakeDamage(npc.AttackDamage, npc, npc)
						end)
					end
				end
			end
		end
		
		npc.NextBreakableScan = CurTime() + 5.0
	end
	
	if npc.InDefenceMode and npc.NextDefenceCheck and CurTime() >= npc.NextDefenceCheck then
		if npc:GetPos():Distance(npc.AmbushPoint or npc:GetPos()) > 512 then
			npc:SetEnemy(NULL)
			npc:SetSchedule(SCHED_AMBUSH)
			npc:SetCondition(COND_ENEMY_UNREACHABLE)
			npc:ForceGo(npc.AmbushPoint or npc:GetPos())
		end
		
		npc.NextDefenceCheck = CurTime() + 1.0
	end
end

local circleMaterial 	   = Material("SGM/playercircle")
local healthcircleMaterial = Material("effects/zm_healthring")
local healthcolmax 		   = Color(20, 255, 20)
local healthcolmin 		   = Color(255, 0, 0)
function NPC:PostDraw(npc)
	if LocalPlayer():IsZM() and npc:Health() > 0 then
		local Health, MaxHealth = npc:Health(), npc:GetMaxHealth()
		local pos = npc:GetPos() + Vector(0, 0, 2)
		local colour = Color(0, 0, 0, 125)
		local healthfrac = math.max(Health, 0) / MaxHealth
		
		colour.r = Lerp(healthfrac, healthcolmin.r, healthcolmax.r)
		colour.g = Lerp(healthfrac, healthcolmin.g, healthcolmax.g)
		colour.b = Lerp(healthfrac, healthcolmin.b, healthcolmax.b)
		
		render.SetMaterial(healthcircleMaterial)
		render.DrawQuadEasy(pos, Vector(0, 0, 1), 40, 40, colour)
		render.DrawQuadEasy(pos, -Vector(0, 0, 1), 40, 40, colour)
		
		if npc.bIsSelected then
			render.SetMaterial(circleMaterial)
			render.DrawQuadEasy(pos, Vector(0, 0, 1), 40, 40, colour, (CurTime() * 50) % 360)
			render.DrawQuadEasy(pos, -Vector(0, 0, 1), 40, 40, colour, (CurTime() * 50) % 360)
		end
	end
end