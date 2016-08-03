local meta = FindMetaTable("Player")
if not meta then return end

function meta:ShouldNotCollide(ent)
	return ent:IsPlayer() and self:Team() == ent:Team() or ent:IsPlayerHolding()
end

function meta:IsZM()
	return self:Team() == TEAM_ZOMBIEMASTER
end

function meta:IsSurvivor()
	return self:Team() == TEAM_SURVIVOR
end

function meta:CanAfford(cost)
	return self:GetZMPoints() > cost
end

function meta:GetZMPoints()
	return self:GetDTInt(1)
end

function meta:GetZMPointIncome()
	return self:GetDTInt(2)
end

function meta:TraceLine(distance, mask, filter, start)
	start = start or self:GetShootPos()
	return util.TraceLine({start = start, endpos = start + self:GetAimVector() * distance, filter = filter or self, mask = mask})
end

function meta:MeleeTrace(distance, size, filter, start)
	return self:TraceHull(distance, MASK_SOLID, size, filter, start)
end

function meta:TraceHull(distance, mask, size, filter, start)
	start = start or self:GetShootPos()
	return util.TraceHull({start = start, endpos = start + self:GetAimVector() * distance, filter = filter or self, mask = mask, mins = Vector(-size, -size, -size), maxs = Vector(size, size, size)})
end

function meta:DoubleTrace(distance, mask, size, mask2, filter)
	local tr1 = self:TraceLine(distance, mask, filter)
	if tr1.Hit then return tr1 end
	if mask2 then
		local tr2 = self:TraceLine(distance, mask2, filter)
		if tr2.Hit then return tr2 end
	end

	local tr3 = self:TraceHull(distance, mask, size, filter)
	if tr3.Hit then return tr3 end
	if mask2 then
		local tr4 = self:TraceHull(distance, mask2, size, filter)
		if tr4.Hit then return tr4 end
	end

	return tr1
end

if not meta.OldAlive then
	meta.OldAlive = meta.Alive
	function meta:Alive()
		if self:Team() == TEAM_ZOMBIEMASTER then
			return true
		end

		return self:OldAlive()
	end
end

local TEAM_SPECTATOR = TEAM_SPECTATOR
function meta:IsSpectator()
	return self:Team() == TEAM_SPECTATOR
end

function meta:SyncAngles()
	local ang = self:EyeAngles()
	ang.pitch = 0
	ang.roll = 0
	return ang
end
meta.GetAngles = meta.SyncAngles

function meta:GetForward()
	return self:SyncAngles():Forward()
end

function meta:GetUp()
	return self:SyncAngles():Up()
end

function meta:GetRight()
	return self:SyncAngles():Right()
end

local VoiceSets = {}

VoiceSets["male"] = {
	["PainSoundsLight"] = {
		Sound("vo/npc/male01/ow01.wav"),
		Sound("vo/npc/male01/ow02.wav"),
		Sound("vo/npc/male01/pain01.wav"),
		Sound("vo/npc/male01/pain02.wav"),
		Sound("vo/npc/male01/pain03.wav")
	},
	["PainSoundsMed"] = {
		Sound("vo/npc/male01/pain04.wav"),
		Sound("vo/npc/male01/pain05.wav"),
		Sound("vo/npc/male01/pain06.wav")
	},
	["PainSoundsHeavy"] = {
		Sound("vo/npc/male01/pain07.wav"),
		Sound("vo/npc/male01/pain08.wav"),
		Sound("vo/npc/male01/pain09.wav")
	},
	["DeathSounds"] = {
		Sound("vo/npc/male01/no02.wav"),
		Sound("ambient/voices/citizen_beaten1.wav"),
		Sound("ambient/voices/citizen_beaten3.wav"),
		Sound("ambient/voices/citizen_beaten4.wav"),
		Sound("ambient/voices/citizen_beaten5.wav"),
		Sound("vo/npc/male01/pain07.wav"),
		Sound("vo/npc/male01/pain08.wav")
	}
}

VoiceSets["barney"] = {
	["PainSoundsLight"] = {
		Sound("vo/npc/Barney/ba_pain02.wav"),
		Sound("vo/npc/Barney/ba_pain07.wav"),
		Sound("vo/npc/Barney/ba_pain04.wav")
	},
	["PainSoundsMed"] = {
		Sound("vo/npc/Barney/ba_pain01.wav"),
		Sound("vo/npc/Barney/ba_pain08.wav"),
		Sound("vo/npc/Barney/ba_pain10.wav")
	},
	["PainSoundsHeavy"] = {
		Sound("vo/npc/Barney/ba_pain05.wav"),
		Sound("vo/npc/Barney/ba_pain06.wav"),
		Sound("vo/npc/Barney/ba_pain09.wav")
	},
	["DeathSounds"] = {
		Sound("vo/npc/Barney/ba_ohshit03.wav"),
		Sound("vo/npc/Barney/ba_no01.wav"),
		Sound("vo/npc/Barney/ba_no02.wav"),
		Sound("vo/npc/Barney/ba_pain03.wav")
	}
}

VoiceSets["female"] = {
	["PainSoundsLight"] = {
		Sound("vo/npc/female01/pain01.wav"),
		Sound("vo/npc/female01/pain02.wav"),
		Sound("vo/npc/female01/pain03.wav")
	},
	["PainSoundsMed"] = {
		Sound("vo/npc/female01/pain04.wav"),
		Sound("vo/npc/female01/pain05.wav"),
		Sound("vo/npc/female01/pain06.wav")
	},
	["PainSoundsHeavy"] = {
		Sound("vo/npc/female01/pain07.wav"),
		Sound("vo/npc/female01/pain08.wav"),
		Sound("vo/npc/female01/pain09.wav")
	},
	["DeathSounds"] = {
		Sound("vo/npc/female01/no01.wav"),
		Sound("vo/npc/female01/ow01.wav"),
		Sound("vo/npc/female01/ow02.wav"),
		Sound("vo/npc/female01/goodgod.wav"),
		Sound("ambient/voices/citizen_beaten2.wav")
	}
}

VoiceSets["alyx"] = {
	["PainSoundsLight"] = {
		Sound("vo/npc/Alyx/gasp03.wav"),
		Sound("vo/npc/Alyx/hurt08.wav")
	},
	["PainSoundsMed"] = {
		Sound("vo/npc/Alyx/hurt04.wav"),
		Sound("vo/npc/Alyx/hurt06.wav"),
		Sound("vo/Citadel/al_struggle07.wav"),
		Sound("vo/Citadel/al_struggle08.wav")
	},
	["PainSoundsHeavy"] = {
		Sound("vo/npc/Alyx/hurt05.wav"),
		Sound("vo/npc/Alyx/hurt06.wav")
	},
	["DeathSounds"] = {
		Sound("vo/npc/Alyx/no01.wav"),
		Sound("vo/npc/Alyx/no02.wav"),
		Sound("vo/npc/Alyx/no03.wav"),
		Sound("vo/Citadel/al_dadgordonno_c.wav"),
		Sound("vo/Streetwar/Alyx_gate/al_no.wav")
	}
}

VoiceSets["combine"] = {
	["PainSoundsLight"] = {
		Sound("npc/combine_soldier/pain1.wav"),
		Sound("npc/combine_soldier/pain2.wav"),
		Sound("npc/combine_soldier/pain3.wav")
	},
	["PainSoundsMed"] = {
		Sound("npc/metropolice/pain1.wav"),
		Sound("npc/metropolice/pain2.wav")
	},
	["PainSoundsHeavy"] = {
		Sound("npc/metropolice/pain3.wav"),
		Sound("npc/metropolice/pain4.wav")
	},
	["DeathSounds"] = {
		Sound("npc/combine_soldier/die1.wav"),
		Sound("npc/combine_soldier/die2.wav"),
		Sound("npc/combine_soldier/die3.wav")
	}
}

VoiceSets["monk"] = {
	["PainSoundsLight"] = {
		Sound("vo/ravenholm/monk_pain01.wav"),
		Sound("vo/ravenholm/monk_pain02.wav"),
		Sound("vo/ravenholm/monk_pain03.wav"),
		Sound("vo/ravenholm/monk_pain05.wav")
	},
	["PainSoundsMed"] = {
		Sound("vo/ravenholm/monk_pain04.wav"),
		Sound("vo/ravenholm/monk_pain06.wav"),
		Sound("vo/ravenholm/monk_pain07.wav"),
		Sound("vo/ravenholm/monk_pain08.wav")
	},
	["PainSoundsHeavy"] = {
		Sound("vo/ravenholm/monk_pain09.wav"),
		Sound("vo/ravenholm/monk_pain10.wav"),
		Sound("vo/ravenholm/monk_pain12.wav")
	},
	["DeathSounds"] = {
		Sound("vo/ravenholm/monk_death07.wav")
	}
}

function meta:PlayDeathSound()
	local snds = VoiceSets[self.VoiceSet].DeathSounds
	if snds then
		self:EmitSound(snds[math.random(1, #snds)])
	end
end

function meta:PlayPainSound()
	if CurTime() < self.NextPainSound then return end

	local snds

	local set = VoiceSets[self.VoiceSet]
	if set then
		local health = self:Health()
		if 70 <= health then
			snds = set.PainSoundsLight
		elseif 35 <= health then
			snds = set.PainSoundsMed
		else
			snds = set.PainSoundsHeavy
		end
	end

	if snds then
		local snd = snds[math.random(#snds)]
		if snd then
			self:EmitSound(snd)
			self.NextPainSound = CurTime() + SoundDuration(snd) - 0.1
		end
	end
end

function meta:TakeSpecialDamage(damage, damagetype, attacker, inflictor, hitpos, damageforce)
	attacker = attacker or self
	if not attacker:IsValid() then attacker = self end
	inflictor = inflictor or attacker
	if not inflictor:IsValid() then inflictor = attacker end

	local nearest = self:NearestPoint(inflictor:NearestPoint(self:LocalToWorld(self:OBBCenter())))

	local dmginfo = DamageInfo()
	dmginfo:SetDamage(damage)
	dmginfo:SetAttacker(attacker)
	dmginfo:SetInflictor(inflictor)
	dmginfo:SetDamagePosition(hitpos or nearest)
	dmginfo:SetDamageType(damagetype)
	if damageforce then
		dmginfo:SetDamageForce(damageforce)
	end
	self:TakeDamageInfo(dmginfo)

	return dmginfo
end

if SERVER then
	function meta:SetZMPoints(points)
		self:SetDTInt(1, points)
	end
	
	function meta:SetZMPointIncome(amount)
		self:SetDTInt(2, amount)
	end
	
	function meta:AddZMPoints(amount)
		local resources = self:GetZMPoints()
		self:SetZMPoints(resources + amount)
	end
	
	function meta:TakeZMPoints(amount)
		local resources = self:GetZMPoints()
		self:SetZMPoints(resources - amount)
	end

	function meta:ChangeTeam(teamid)
		local oldteam = self:Team()
		self:SetTeam(teamid)
		if oldteam ~= teamid then
			gamemode.Call("OnPlayerChangedTeam", self, oldteam, teamid)
		end
	end
	
	function meta:Gib()
		local pos = self:LocalToWorld(self:OBBCenter())

		local effectdata = EffectData()
			effectdata:SetEntity(self)
			effectdata:SetOrigin(pos)
		util.Effect("gib_player", effectdata, true, true)

		self.Gibbed = CurTime()

		timer.Simple(0, function()
			GAMEMODE.CreateGibs(GAMEMODE, pos, self:LocalToWorld(self:OBBMaxs()).z - pos.z)
		end)
	end
	
	function meta:UnSpectateAndSpawn()
		self:UnSpectate()
		self:Spawn()
	end
	
	meta.OldSetMaxHealth = FindMetaTable("Entity").SetMaxHealth
	function meta:SetMaxHealth(num)
		num = math.ceil(num)
		self:SetDTInt(0, num)
		self:OldSetMaxHealth(num)
	end
	
	function meta:RemoveAllStatus(bSilent, bInstant)
		if bInstant then
			for _, ent in pairs(ents.FindByClass("status_*")) do
				if not ent.NoRemoveOnDeath and ent:GetOwner() == self then
					ent:Remove()
				end
			end
		else
			for _, ent in pairs(ents.FindByClass("status_*")) do
				if not ent.NoRemoveOnDeath and ent:GetOwner() == self then
					ent.SilentRemove = bSilent
					ent:SetDie()
				end
			end
		end
	end

	function meta:RemoveStatus(sType, bSilent, bInstant, sExclude)
		local removed

		for _, ent in pairs(ents.FindByClass("status_"..sType)) do
			if ent:GetOwner() == self and not (sExclude and ent:GetClass() == "status_"..sExclude) then
				if bInstant then
					ent:Remove()
				else
					ent.SilentRemove = bSilent
					ent:SetDie()
				end
				removed = true
			end
		end

		return removed
	end

	function meta:GetStatus(sType)
		local ent = self["status_"..sType]
		if ent and ent:IsValid() and ent.Owner == self then return ent end
	end

	function meta:GiveStatus(sType, fDie)
		local cur = self:GetStatus(sType)
		if cur then
			if fDie then
				cur:SetDie(fDie)
			end
			cur:SetPlayer(self, true)
			return cur
		else
			local ent = ents.Create("status_"..sType)
			if ent:IsValid() then
				ent:Spawn()
				if fDie then
					ent:SetDie(fDie)
				end
				ent:SetPlayer(self)
				return ent
			end
		end
	end
end