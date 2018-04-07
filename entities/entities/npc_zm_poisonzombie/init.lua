AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

ENT.AttackDamage = 50
ENT.AttackRange  = 85
ENT.FootStepTime = 0.4
ENT.CanSwatPhysicsObjects = false

ENT.AttackSounds = "NPC_PoisonZombie.Attack"
ENT.DeathSounds  = "NPC_PoisonZombie.Die"
ENT.PainSounds   = "NPC_PoisonZombie.Pain"
ENT.MoanSounds   = "NPC_PoisonZombie.Idle"
ENT.AlertSounds     = "NPC_PoisonZombie.Alert"