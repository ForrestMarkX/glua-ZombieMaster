NPC.Class = "npc_fastzombie"
NPC.Name = translate.Get("npc_class_banshee")
NPC.Description = translate.Get("npc_description_banshee")
NPC.Icon = "VGUI/zombies/info_banshee"
NPC.Flag = FL_SPAWN_BANSHEE_ALLOWED
NPC.Cost = GetConVar("zm_cost_banshee"):GetInt()
NPC.PopCost = GetConVar("zm_popcost_banshee"):GetInt()

NPC.Model = {"models/zombie/zm_fast.mdl"}