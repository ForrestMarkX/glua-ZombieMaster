local meta = FindMetaTable("Player")
if not meta then return end

function meta:ShouldNotCollide(ent)
	return ent:IsPlayerHolding()
end

function meta:IsZM()
	return self:Team() == TEAM_ZOMBIEMASTER
end

function meta:IsSurvivor()
	return self:Team() == TEAM_SURVIVOR
end

function meta:IsSpectator()
	return self:Team() == TEAM_SPECTATOR
end

meta.OldSpectate = meta.OldSpectate or meta.Spectate
function meta:Spectate(obsmode)
	self:SetNoTarget(true)
	if obsmode == OBS_MODE_ROAMING then
		self:SetMoveType(MOVETYPE_NOCLIP)
	end
	
	self:OldSpectate(obsmode)
end

meta.OldUnSpectate = meta.OldUnSpectate or meta.UnSpectate
function meta:UnSpectate()
	self:SetNoTarget(false)
	self:OldUnSpectate()
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

if not meta.OldAlive then
	meta.OldAlive = meta.Alive
	function meta:Alive()
		if self:IsZM() then
			return true
		end

		return self:OldAlive()
	end
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