concommand.Add("printdxinfo", function()
	print("DX Level: "..tostring(render.GetDXLevel()))
	print("Supports HDR: "..tostring(render.SupportsHDR()))
	print("Supports Pixel Shaders 1.4: "..tostring(render.SupportsPixelShaders_1_4()))
	print("Supports Pixel Shaders 2.0: "..tostring(render.SupportsPixelShaders_2_0()))
	print("Supports Vertex Shaders 2.0: "..tostring(render.SupportsVertexShaders_2_0()))
end)

local function GetViewModelPosition(self, pos, ang)
	return pos + ang:Forward() * -256, ang
end

function DontDrawViewModel()
	if SWEP then
		SWEP.GetViewModelPosition = GetViewModelPosition
	end
end

-- Scales the screen based around 1080p but doesn't make things TOO tiny on low resolutions.
function BetterScreenScale()
	return math.Clamp(ScrH() / 1080, 0.6, 1)
end

function render.GetLightRGB(pos)
	local vec = render.GetLightColor(pos)
	return vec.r, vec.g, vec.b
end

function EasyLabel(parent, text, font, textcolor)
	local dpanel = vgui.Create("DLabel", parent)
	if font then
		dpanel:SetFont(font or "DefaultFont")
	end
	dpanel:SetText(text)
	dpanel:SizeToContents()
	if textcolor then
		dpanel:SetTextColor(textcolor)
	end
	dpanel:SetKeyboardInputEnabled(false)
	dpanel:SetMouseInputEnabled(false)

	return dpanel
end

function EasyButton(parent, text, xpadding, ypadding)
	local dpanel = vgui.Create("DButton", parent)
	if textcolor then
		dpanel:SetFGColor(textcolor or color_white)
	end
	if text then
		dpanel:SetText(text)
	end
	dpanel:SizeToContents()

	if xpadding then
		dpanel:SetWide(dpanel:GetWide() + xpadding * 2)
	end

	if ypadding then
		dpanel:SetTall(dpanel:GetTall() + ypadding * 2)
	end

	return dpanel
end

function draw.OutlinedBox( x, y, w, h, thickness, clr )
	surface.SetDrawColor( clr )
	for i=0, thickness - 1 do
		surface.DrawOutlinedRect( x + i, y + i, w - i * 2, h - i * 2 )
	end
end

function draw.DrawSimpleRect(x, y, w, h, col)
	surface.SetDrawColor(col)
	surface.DrawRect(x, y, w, h)
end

function draw.DrawSimpleOutlined(x, y, w, h, col)
	surface.SetDrawColor(col)
	surface.DrawOutlinedRect(x, y, w, h)
end

function draw.DrawDoubleOutlined(x, y, w, h, col)
	surface.SetDrawColor(col)
	surface.DrawOutlinedRect(x, y, w, h)
	surface.DrawOutlinedRect(x + 1, y + 1, w - 2, h - 2)
end

function draw.DrawTexture(x, y, w, h, color, texture)
	surface.SetDrawColor(color)
	surface.SetTexture(texture)
	surface.DrawTexturedRect(x, y, w, h)
end

draw.SimpleRect = draw.DrawSimpleRect
draw.SimpleOutlined = draw.DrawSimpleOutlined
draw.DoubleOutlined = draw.DrawDoubleOutlined

function draw.DrawProgressBar(x, y, w, h, progress)
	local maxWidth = progress
	
	if progress >= (w - 4) then
		maxWidth = w - 4
	end
	
	draw.DrawSimpleRect(x +2, y +2, maxWidth, h -4, Color(221, 181, 0, 255))
	draw.DrawSimpleOutlined(x, y, w, h, Color(221, 181, 0, 255))
end

function util.GetTextSize(font, text)
	surface.SetFont(font)
	return surface.GetTextSize(text)
end