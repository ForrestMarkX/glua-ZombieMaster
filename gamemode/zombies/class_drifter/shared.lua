NPC.Class = "npc_dragzombie"
NPC.Name = translate.Get("npc_class_drifter")
NPC.Description = translate.Get("npc_description_drifter")
NPC.Icon = "VGUI/zombies/info_drifter"
NPC.Flag = FL_SPAWN_DRIFTER_ALLOWED
NPC.Cost = GetConVar("zm_cost_drifter"):GetInt()
NPC.PopCost = GetConVar("zm_popcost_immolator"):GetInt()
NPC.Health = GetConVar("zm_dragzombie_health"):GetInt()

NPC.Model = "models/humans/zm_draggy.mdl"