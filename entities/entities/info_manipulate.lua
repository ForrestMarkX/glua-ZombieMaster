AddCSLuaFile()

ENT.Base = "info_node_base"
ENT.Type = "anim"
ENT.Model = Model("models/manipulatable.mdl")

if CLIENT then
	ENT.GlowMat = Material("models/orange")
	ENT.GlowColor = Color( 248, 124, 0 )
	ENT.GlowSize = 128
end

if CLIENT then return end

function ENT:InputToggle()
	self.BaseClass.InputToggle(self)
	for _, trigger in pairs(ents.FindByClass("info_manipulate_trigger")) do	
		if trigger:GetParent() == self then
			trigger:Remove()
		end
	end
end

function ENT:InputHide()
	self.BaseClass.InputHide(self)
	for _, trigger in pairs(ents.FindByClass("info_manipulate_trigger")) do	
		if trigger:GetParent() == self then
			trigger:Remove()
		end
	end
end

function ENT:Trigger(activator)
	self.BaseClass.Trigger(self, activator)
		
	self:Input("OnPressed", activator, self)
		
	for _, trigger in pairs(ents.FindByClass("info_manipulate_trigger")) do	
		if trigger:GetParent() == self then
			trigger:Remove()
		end
	end

	self.m_iTrapCount = 0
end