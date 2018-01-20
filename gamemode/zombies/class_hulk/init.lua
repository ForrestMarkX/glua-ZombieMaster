NPC.HullType = HULL_MEDIUM_TALL
NPC.HullSizeMins = Vector(13, 13, 90)
NPC.HullSizeMaxs = Vector(-13, -13, 0)

function NPC:OnScaledDamage(npc, hitgroup, dmginfo)
	if hitgroup == HITGROUP_LEFTLEG or hitgroup == HITGROUP_RIGHTLEG then
		dmginfo:ScaleDamage(2)
	end
end

function NPC:OnDamagedEnt(npc, ent, dmginfo)
	dmginfo:SetDamage(math.random(GetConVar("zm_zombie_poison_dmg_slash_min"):GetInt(), GetConVar("zm_zombie_poison_dmg_slash_max"):GetInt()))
end