NPC.Class = "npc_dragzombie"
NPC.Name = translate.Get("npc_class_drifter")
NPC.Description = translate.Get("npc_description_drifter")
NPC.Icon = "VGUI/zombies/info_drifter"
NPC.Flag = FL_SPAWN_DRIFTER_ALLOWED
NPC.Cost = GetConVar("zm_cost_drifter"):GetInt()
NPC.PopCost = GetConVar("zm_popcost_immolator"):GetInt()
NPC.Health = GetConVar("zm_dragzombie_health"):GetInt()

NPC.Model = "models/humans/zm_draggy.mdl"

if SERVER then
	NPC.ClearCapabilities = true
	NPC.Capabilities = bit.bor(CAP_MOVE_GROUND, CAP_INNATE_MELEE_ATTACK1, CAP_SQUAD, CAP_SKIP_NAV_GROUND_CHECK)
end

function NPC:OnScaledDamage(npc, hitgroup, dmginfo)
	return false
end