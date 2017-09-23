/*
	Made by Zombine
*/

local PANEL = {}

local clrNormal = Color(255, 255, 255, 255)
local clrCaution = Color(255, 48, 0, 255)

local CLIP_PERC_THRESHOLD = 0.75
local HEALTH_WARNING_THRESHOLD = 25
local QUICKINFO_EVENT_DURATION = 1.0
local QUICKINFO_BRIGHTNESS_FULL = 255
local QUICKINFO_BRIGHTNESS_DIM = 64
local QUICKINFO_FADE_IN_TIME = 0.5
local QUICKINFO_FADE_OUT_TIME = 2.0

surface.CreateFont("CrosshairBars", {
	font = "HL2Cross",
	antialias = true,
	size = 57,
	weight = 0,
	additive = true,
})

local function DrawVerticalProgressCharacter(panel, font, empty, full, x, y, w, h, progress, color)
	local inv = 1 - progress
	local invHeight = math.Round(h * inv)

	local scissorx, scissory = panel:LocalToScreen(x, y)

	surface.SetFont(font)
	surface.SetTextPos(x, y)
	surface.SetTextColor(color)

	render.SetScissorRect(scissorx, scissory, scissorx + w, scissory + invHeight, true)
	surface.DrawText(empty)
	render.SetScissorRect(0, 0, 0, 0, false)

	surface.SetFont(font)
	surface.SetTextPos(x, y)
	surface.SetTextColor(color)

	render.SetScissorRect(scissorx, scissory + invHeight, scissorx + w, scissory + h, true)
	surface.DrawText(full)
	render.SetScissorRect(0, 0, 0, 0, false)
end

function PANEL:Init()
	self.leftEmptyBracket = "{"
	self.leftFullBracket = "["
	self.rightEmptyBracket = "}"
	self.rightFullBracket = "]"

	self.m_lastAmmo = 0
	self.m_warnAmmo = false
	self.m_ammoFade = 0

	self.m_lastHealth = 0
	self.m_warnHealth = false
	self.m_healthFade = 0

	self.m_flLastEventTime = 0
	self.m_bFadedOut = false

	surface.SetFont("CrosshairBars")

	self.barw, self.barh = surface.GetTextSize(self.leftFullBracket)

	self:ParentToHUD()
end

function PANEL:Think()
	// see if we should fade in/out
	local bFadeOut = false

	// check if the state has changed
	if self.m_bFadedOut ~= bFadeOut then
		self.m_bFadedOut = bFadeOut

		self.m_bDimmed = false

		if bFadeOut then
			self.m_AnimList = nil
			self:AlphaTo(0, 0.25, 0)
		else
			self.m_AnimList = nil
			self:AlphaTo(QUICKINFO_BRIGHTNESS_FULL, QUICKINFO_FADE_IN_TIME, 0.0)
		end
	elseif not self.m_bFadedOut then
		// If we're dormant, fade out
		if self:EventTimeElapsed() then
			if not self.m_bDimmed then
				self.m_bDimmed = true
				self.m_AnimList = nil
				self:AlphaTo(QUICKINFO_BRIGHTNESS_DIM, QUICKINFO_FADE_OUT_TIME, 0.0)
			end
		elseif self.m_bDimmed then
			// Fade back up, we're active
			self.m_bDimmed = false
			self.m_AnimList = nil
			self:AlphaTo(QUICKINFO_BRIGHTNESS_FULL, QUICKINFO_FADE_IN_TIME, 0.0)
		end
	end
end

function PANEL:UpdateEventTime()
	self.m_flLastEventTime = CurTime()
end

function PANEL:EventTimeElapsed()
	if (CurTime() - self.m_flLastEventTime) > QUICKINFO_EVENT_DURATION then
		return true
	end

	return false
end

function PANEL:DrawWarning(x, y, icon, time)
	local scale	= math.floor(math.abs(math.sin(CurTime() * 8)) * 128)

	// Only fade out at the low point of our blink
	if time <= (FrameTime() * 200.0) then
		if scale < 40 then
			time = 0.0

			return time
		else
			// Counteract the offset below to survive another frame
			time = time + (FrameTime() * 200.0)
		end
	end

	// Update our time
	time = time - (FrameTime() * 200.0)
	local caution = clrCaution
	caution.a = scale * 255

	surface.SetFont("CrosshairBars")
	surface.SetTextColor(caution)
	surface.SetTextPos(x, y)
	surface.DrawText(icon)

	return time
end

local scalar = 138.0 / 255.0
local hud_quickinfo = GetConVar("hud_quickinfo")

function PANEL:Paint(w, h)
	if not hook.Run("HUDShouldDraw", "CHudQuickInfo") then
		return
	end

	if hud_quickinfo:GetInt() == 0 then
		return
	end

	local player = LocalPlayer()

	local weapon = player:GetActiveWeapon()

	if not IsValid(weapon) then return end

	local halfWidth, halfHeight = w / 2, h / 2

	DisableClipping(true)

	// Check our health for a warning
	local health = player:Health()

	if health ~= self.m_lastHealth then
		self.m_lastHealth = health

		self:UpdateEventTime()

		if health <= HEALTH_WARNING_THRESHOLD then
			if not self.m_warnHealth then
				self.m_healthFade = 255
				self.m_warnHealth = true

				player:EmitSound("HUDQuickInfo.LowHealth")
			end
		else
			self.m_warnHealth = false
		end
	end

	local ammo = weapon:Clip1()

	if ammo ~= self.m_lastAmmo then
		self.m_lastAmmo	= ammo

		self:UpdateEventTime()

		// Find how far through the current clip we are
		local ammoPerc = ammo / weapon:GetMaxClip1()

		// Warn if we're below a certain percentage of our clip's size
		if (weapon:GetMaxClip1() > 1) and (ammoPerc <= (1.0 - CLIP_PERC_THRESHOLD)) then
			if not self.m_warnAmmo then
				self.m_ammoFade = 255
				self.m_warnAmmo = true

				player:EmitSound("HUDQuickInfo.LowAmmo")
			end
		else
			self.m_warnAmmo = false
		end
	end

	local sinScale = math.floor(math.abs(math.sin(CurTime() * 8)) * 128)

	if self.m_healthFade > 0.0 then
		self.m_healthFade = self:DrawWarning(halfWidth - self.barw * 2, halfHeight - self.barh / 2, self.leftFullBracket, self.m_healthFade)
	else
		local healthPerc = health / player:GetMaxHealth()
		healthPerc = math.Clamp(healthPerc, 0.0, 1.0)

		local healthColor = self.m_warnHealth and clrCaution or clrNormal

		if self.m_warnHealth then
			healthColor.a = 255 * sinScale
		else
			healthColor.a = 255 * scalar
		end

		DrawVerticalProgressCharacter(self, "CrosshairBars", self.leftEmptyBracket, self.leftFullBracket, halfWidth - self.barw * 2, halfHeight - self.barh / 2, self.barw, self.barh, healthPerc, healthColor)
	end

	if self.m_ammoFade > 0.0 then
		self.m_ammoFade = self:DrawWarning(halfWidth + self.barw, halfHeight - self.barh / 2, self.rightFullBracket, self.m_ammoFade)
	else
		local ammoPerc

		if weapon:GetMaxClip1() <= 0 then
			ammoPerc = 1
		else
			ammoPerc = (ammo / weapon:GetMaxClip1())
			ammoPerc = math.Clamp(ammoPerc, 0.0, 1.0)
		end

		local ammoColor = self.m_warnAmmo and clrCaution or clrNormal

		if self.m_warnAmmo then
			ammoColor.a = 255 * sinScale
		else
			ammoColor.a = 255 * scalar
		end

		DrawVerticalProgressCharacter(self, "CrosshairBars", self.rightEmptyBracket, self.rightFullBracket, halfWidth + self.barw, halfHeight - self.barh / 2, self.barw, self.barh, ammoPerc, ammoColor)
	end

	DisableClipping(false)
end

vgui.Register("CHudQuickInfo", PANEL)