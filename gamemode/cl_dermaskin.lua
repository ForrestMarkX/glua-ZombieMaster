function GM:ForceDermaSkin()
	return "zm_skin"
end

local SKIN = {}

SKIN.PrintName = "Zombie Master Derma Skin"
SKIN.Author = "Forrest Mark X"
SKIN.DermaVersion = 1

SKIN.Colors = {}
SKIN.Colors.Panel = {}
SKIN.Colors.Panel.Normal = Color(60, 0, 0, 220)
SKIN.Colors.Panel.Border = Color(150, 0, 0, 255)

SKIN.Colours = {}

SKIN.Colours.Window = {}
SKIN.Colours.Window.TitleActive		= color_white
SKIN.Colours.Window.TitleInactive	= SKIN.Colours.Window.TitleActive

SKIN.Colours.Button = {}
SKIN.Colours.Button.Normal				= color_white
SKIN.Colours.Button.Hover				= Color(20, 200, 250)
SKIN.Colours.Button.Down				= Color(20, 20, 20)
SKIN.Colours.Button.Disabled			= Color(10, 10, 10)

SKIN.Colours.Tab = {}
SKIN.Colours.Tab.Active = {}
SKIN.Colours.Tab.Active.Normal		= GWEN.TextureColor( 4 + 8 * 4, 508 )
SKIN.Colours.Tab.Active.Hover		= GWEN.TextureColor( 4 + 8 * 5, 508 )
SKIN.Colours.Tab.Active.Down		= GWEN.TextureColor( 4 + 8 * 4, 500 )
SKIN.Colours.Tab.Active.Disabled	= GWEN.TextureColor( 4 + 8 * 5, 500 )

SKIN.Colours.Tab.Inactive = {}
SKIN.Colours.Tab.Inactive.Normal	= GWEN.TextureColor( 4 + 8 * 6, 508 )
SKIN.Colours.Tab.Inactive.Hover		= GWEN.TextureColor( 4 + 8 * 7, 508 )
SKIN.Colours.Tab.Inactive.Down		= GWEN.TextureColor( 4 + 8 * 6, 500 )
SKIN.Colours.Tab.Inactive.Disabled	= GWEN.TextureColor( 4 + 8 * 7, 500 )

SKIN.Colours.Label = {}
SKIN.Colours.Label.Default   = color_white
SKIN.Colours.Label.Bright    = Color(0, 0, 100)
SKIN.Colours.Label.Dark	     = Color(20, 20, 20)
SKIN.Colours.Label.Highlight = Color(20, 200, 250)

SKIN.Colours.Tree = {}
SKIN.Colours.Tree.Lines				= GWEN.TextureColor( 4 + 8 * 10, 508 ) ---- !!!
SKIN.Colours.Tree.Normal			= GWEN.TextureColor( 4 + 8 * 11, 508 )
SKIN.Colours.Tree.Hover				= GWEN.TextureColor( 4 + 8 * 10, 500 )
SKIN.Colours.Tree.Selected			= GWEN.TextureColor( 4 + 8 * 11, 500 )

SKIN.Colours.Properties = {}
SKIN.Colours.Properties.Line_Normal			= GWEN.TextureColor( 4 + 8 * 12, 508 )
SKIN.Colours.Properties.Line_Selected		= GWEN.TextureColor( 4 + 8 * 13, 508 )
SKIN.Colours.Properties.Line_Hover			= GWEN.TextureColor( 4 + 8 * 12, 500 )
SKIN.Colours.Properties.Title				= GWEN.TextureColor( 4 + 8 * 13, 500 )
SKIN.Colours.Properties.Column_Normal		= GWEN.TextureColor( 4 + 8 * 14, 508 )
SKIN.Colours.Properties.Column_Selected		= GWEN.TextureColor( 4 + 8 * 15, 508 )
SKIN.Colours.Properties.Column_Hover		= GWEN.TextureColor( 4 + 8 * 14, 500 )
SKIN.Colours.Properties.Border				= GWEN.TextureColor( 4 + 8 * 15, 500 )
SKIN.Colours.Properties.Label_Normal		= GWEN.TextureColor( 4 + 8 * 16, 508 )
SKIN.Colours.Properties.Label_Selected		= GWEN.TextureColor( 4 + 8 * 17, 508 )
SKIN.Colours.Properties.Label_Hover			= GWEN.TextureColor( 4 + 8 * 16, 500 )

SKIN.Colours.Category = {}
SKIN.Colours.Category.Header				= GWEN.TextureColor( 4 + 8 * 18, 500 )
SKIN.Colours.Category.Header_Closed			= GWEN.TextureColor( 4 + 8 * 19, 500 )
SKIN.Colours.Category.Line = {}
SKIN.Colours.Category.Line.Text				= GWEN.TextureColor( 4 + 8 * 20, 508 )
SKIN.Colours.Category.Line.Text_Hover		= GWEN.TextureColor( 4 + 8 * 21, 508 )
SKIN.Colours.Category.Line.Text_Selected	= GWEN.TextureColor( 4 + 8 * 20, 500 )
SKIN.Colours.Category.Line.Button			= GWEN.TextureColor( 4 + 8 * 21, 500 )
SKIN.Colours.Category.Line.Button_Hover		= GWEN.TextureColor( 4 + 8 * 22, 508 )
SKIN.Colours.Category.Line.Button_Selected	= GWEN.TextureColor( 4 + 8 * 23, 508 )
SKIN.Colours.Category.LineAlt = {}
SKIN.Colours.Category.LineAlt.Text				= GWEN.TextureColor( 4 + 8 * 22, 500 )
SKIN.Colours.Category.LineAlt.Text_Hover		= GWEN.TextureColor( 4 + 8 * 23, 500 )
SKIN.Colours.Category.LineAlt.Text_Selected		= GWEN.TextureColor( 4 + 8 * 24, 508 )
SKIN.Colours.Category.LineAlt.Button			= GWEN.TextureColor( 4 + 8 * 25, 508 )
SKIN.Colours.Category.LineAlt.Button_Hover		= GWEN.TextureColor( 4 + 8 * 24, 500 )
SKIN.Colours.Category.LineAlt.Button_Selected	= GWEN.TextureColor( 4 + 8 * 25, 500 )

SKIN.Colours.TooltipText = GWEN.TextureColor( 4 + 8 * 26, 500 )

SKIN.colTextEntryText = color_white

local color_frame_background = Color(60, 0, 0, 220)
local color_frame_border = Color(150, 0, 0, 255)
SKIN.color_frame_background = color_frame_background
SKIN.color_frame_border = color_frame_border

function SKIN:PaintFrame(panel, w, h)
	draw.RoundedBoxHollow(3, 0, 0, w, h, color_frame_border)
	draw.RoundedBox(2, 2, 2, w - 4, h - 4, color_frame_background)
end

function SKIN:PaintPanel(panel, w, h)
	if not panel.m_bBackground then return end

	draw.RoundedBoxHollow(3, 0, 0, w, h, self.Colors.Panel.Border)
	draw.RoundedBox(2, 2, 2, w - 4, h - 4, self.Colors.Panel.Normal)
end

function SKIN:PaintButton(panel, w, h)
	if not panel.m_bBackground then return end

	local col = Color(89, 0, 0)
	local col2 = Color(52, 0, 0)
	if panel.Hovered then
		col = Color(145, 0, 0)
		col2 = Color(95, 0, 0, 220)
	end
	
	draw.RoundedBoxHollow(3, 0, 0, w, h, col)
	draw.RoundedBox(2, 2, 2, w - 4, h - 4, col2)
end

function SKIN:PaintComboBox(panel, w, h)
	self:PaintButton(panel, w, h)
end

local color_tab_active = Color(95, 0, 0, 220)
local color_tab_border = Color(145, 0, 0)
function SKIN:PaintPropertySheet(panel, w, h)
	draw.RoundedBoxHollow(3, 0, 0, w, h, color_tab_border)
	draw.RoundedBox(2, 2, 2, w - 4, h - 4, color_tab_active)
end

function SKIN:PaintTab(panel, w, h)
	if panel:GetPropertySheet():GetActiveTab() == panel then
		return self:PaintActiveTab(panel, w, h)
	end

	draw.RoundedBoxHollow(3, 0, 0, w, h, color_tab_border)
	draw.RoundedBox(2, 2, 2, w - 4, h - 4, color_tab_active)
end

local color_tab_active2 = Color(135, 0, 0, 220)
local color_tab_border2 = Color(218, 0, 0)
function SKIN:PaintActiveTab( panel, w, h )
	draw.RoundedBoxHollow(3, 0, 0, w, h, color_tab_border2)
	draw.RoundedBox(2, 2, 2, w - 4, h - 4, color_tab_active2)
end

function SKIN:PaintVScrollBar( panel, w, h )
	draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 100))
end

local color_grip_active = Color(135, 0, 0, 220)
local color_grip_border = Color(218, 0, 0)
function SKIN:PaintScrollBarGrip( panel, w, h )
	draw.RoundedBoxHollow(3, 0, 0, w, h, color_grip_border)
	draw.RoundedBox(2, 2, 2, w - 4, h - 4, color_grip_active)
end

local function PaintNotches( x, y, w, h, num )
	if not num then return end

	local space = w / num

	for i=0, num do
		surface.DrawRect(x + i * space, y + 4, 1, 5)
	end
end

function SKIN:PaintNumSlider( panel, w, h )
	surface.SetDrawColor(Color(255, 255, 255, 100))
	surface.DrawRect(8, h / 2 - 1, w - 15, 1)

	PaintNotches(8, h / 2 - 1, w - 16, 1, panel.m_iNotches)
end

function SKIN:PaintCollapsibleCategory( panel, w, h )
	if h < 21 then
		draw.RoundedBoxHollow(3, 0, 0, w, h, color_grip_border)
		draw.RoundedBox(2, 2, 2, w - 4, h - 4, color_grip_active)
	end

	draw.RoundedBoxHollow(3, 0, 0, w, 20, color_grip_border)
	draw.RoundedBox(2, 2, 2, w - 4, 16, color_grip_active)
end

derma.DefineSkin("zm_skin", "Zombie Master Derma Skin", SKIN, "Default")