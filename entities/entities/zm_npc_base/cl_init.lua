include("shared.lua")

local startVal = 0
local endVal = 1
local fadeSpeed = 1.6

ENT.fadeAlpha = 0

function ENT:Initialize()
	self.fadeAlpha = 0
end

function ENT:Draw()
	if self.fadeAlpha < 1 then
		self.fadeAlpha = self.fadeAlpha + fadeSpeed * FrameTime()
		self.fadeAlpha = math.Clamp(self.fadeAlpha, startVal, endVal)
		
		render.SetBlend(self.fadeAlpha)
		self:DrawModel()
		render.SetBlend(1)
	else
		self:DrawModel()
	end
end