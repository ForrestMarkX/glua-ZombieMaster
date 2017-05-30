DEFINE_BASECLASS("class_default")

NPC.Class = "npc_zombie"
NPC.Name = translate.Get("npc_class_shambler")
NPC.Description = translate.Get("npc_description_shambler")
NPC.Icon = "VGUI/zombies/info_shambler"
NPC.Flag = FL_SPAWN_SHAMBLER_ALLOWED
NPC.Cost = GetConVar("zm_cost_shambler"):GetInt()
NPC.PopCost = GetConVar("zm_popcost_shambler"):GetInt()
NPC.Health = GetConVar("zm_zombie_health"):GetInt()

NPC.Model = {
	"models/zombie/zm_classic.mdl",
	"models/zombie/zm_classic_01.mdl",
	"models/zombie/zm_classic_02.mdl",
	"models/zombie/zm_classic_03.mdl",
	"models/zombie/zm_classic_04.mdl",
	"models/zombie/zm_classic_05.mdl",
	"models/zombie/zm_classic_06.mdl",
	"models/zombie/zm_classic_07.mdl",
	"models/zombie/zm_classic_08.mdl",
	"models/zombie/zm_classic_09.mdl"
}

function NPC:OnTakeDamage(npc, attacker, inflictor, dmginfo)
	if bit.band(dmginfo:GetDamageType(), DMG_BLAST) ~= 0 then
		dmginfo:SetDamageType(DMG_BULLET)
		dmginfo:SetDamage(dmginfo:GetDamage() * 2)
	end
		
	return BaseClass.OnTakeDamage(self, npc, attacker, inflictor, dmginfo)
end

function NPC:OnDamagedEnt(npc, ent, dmginfo)
	local damage = dmginfo:GetDamage()
	if damage == cvars.Number("sk_zombie_dmg_one_slash", 0) or damage == cvars.Number("sk_zombie_dmg_both_slash", 0) then
		dmginfo:SetDamage(GetConVar("zm_zombie_dmg_one_slash"):GetInt())
	end
end