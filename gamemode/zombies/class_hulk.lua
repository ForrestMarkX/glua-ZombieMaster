NPC.Class = "npc_poisonzombie"
NPC.Name = translate.Get("npc_class_hulk")
NPC.Description = translate.Get("npc_description_hulk")
NPC.Icon = "VGUI/zombies/info_hulk"
NPC.Flag = FL_SPAWN_HULK_ALLOWED
NPC.Cost = GetConVar("zm_cost_hulk"):GetInt()
NPC.PopCost = GetConVar("zm_popcost_hulk"):GetInt()

NPC.Model = {"models/zombie/hulk.mdl"}

if SERVER then
	NPC.Capabilities = bit.bor(CAP_MOVE_GROUND, CAP_INNATE_MELEE_ATTACK1)
end

function NPC:OnScaledDamage(npc, hitgroup, dmginfo)
	if hitgroup == HITGROUP_LEFTLEG or hitgroup == HITGROUP_RIGHTLEG then
		dmginfo:ScaleDamage(1.5)
	end
end

local NextAttack = 0
function NPC:Think(npc)
	if not IsValid(npc) then return end
	
	local meleeAttacking = npc:GetActivity() == ACT_MELEE_ATTACK1
	local target = npc:GetEnemy()
	if IsValid(target) then
		if meleeAttacking and target:IsPlayer() and target:Crouching() then
			if NextAttack < CurTime() then
				NextAttack = CurTime() + 1
				
				local dmginfo = DamageInfo()
				dmginfo:SetDamage(20)
				dmginfo:SetAttacker(npc)
				dmginfo:SetDamageType(DMG_SLASH)
				target:TakeDamageInfo(dmginfo)
			end
		end
	end
end