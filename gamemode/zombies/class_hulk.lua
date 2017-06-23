NPC.Class = "npc_poisonzombie"
NPC.Name = translate.Get("npc_class_hulk")
NPC.Description = translate.Get("npc_description_hulk")
NPC.Icon = "VGUI/zombies/info_hulk"
NPC.Flag = FL_SPAWN_HULK_ALLOWED
NPC.Cost = GetConVar("zm_cost_hulk"):GetInt()
NPC.PopCost = GetConVar("zm_popcost_hulk"):GetInt()
NPC.Health = GetConVar("zm_zombie_poison_health"):GetInt()
NPC.IsEngineNPC = true

NPC.Model = "models/zombie/hulk.mdl"
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