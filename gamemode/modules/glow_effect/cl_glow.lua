local mat_Copy		= Material( "pp/copy" )
local mat_Add		= Material( "pp/add" )
local rt_Store		= render.GetScreenEffectTexture( 0 )
local rt_Buffer		= render.GetScreenEffectTexture( 1 )

local List = {}
local RenderEnt = NULL

outline = {}
function outline.Add(ents, color)
	local t =
	{
		Ents = ents,
		Color = color
	}

	List[#List + 1] = t
end

function outline.RenderedEntity()
	return RenderEnt
end

function outline.Render(entry)
	local rt_Scene = render.GetRenderTarget()
	render.CopyRenderTargetToTexture(rt_Store)

	render.Clear(0, 0, 0, 255, false, true)

	cam.Start3D()
		render.SetStencilEnable( true )
			render.SuppressEngineLighting(true)
			
				render.SetStencilWriteMask(1)
				render.SetStencilTestMask(1)
				render.SetStencilReferenceValue(1)

				render.SetStencilCompareFunction(STENCIL_ALWAYS)
				render.SetStencilPassOperation(STENCIL_REPLACE)
				render.SetStencilFailOperation(STENCIL_KEEP )
				render.SetStencilZFailOperation(STENCIL_KEEP)
				
				for k, v in pairs(entry.Ents) do
					if not IsValid(v) or not v:ShouldDrawOutline() then continue end
					RenderEnt = v
					v:DrawModel()
				end

				RenderEnt = NULL

				render.SetStencilCompareFunction(STENCIL_EQUAL)
				render.SetStencilPassOperation(STENCIL_KEEP)

				cam.Start2D()
					surface.SetDrawColor( entry.Color )
					surface.DrawRect( 0, 0, ScrW(), ScrH() )
				cam.End2D()

			render.SuppressEngineLighting(false)
		render.SetStencilEnable(false)
	cam.End3D()

	render.CopyRenderTargetToTexture(rt_Buffer)

	render.SetRenderTarget(rt_Scene)
	mat_Copy:SetTexture("$basetexture", rt_Store)
	render.SetMaterial(mat_Copy)
	render.DrawScreenQuad()

	render.SetStencilEnable(true)
		render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_NOTEQUAL)

		mat_Add:SetTexture("$basetexture", rt_Buffer)
		render.SetMaterial(mat_Add)

		render.DrawScreenQuadEx(0, 0, ScrW() + 2, ScrH() + 2)
		render.DrawScreenQuadEx(0, 0, ScrW() - 2, ScrH() - 2)
	render.SetStencilEnable(false)

	render.SetStencilTestMask(0)
	render.SetStencilWriteMask(0)
	render.SetStencilReferenceValue(0)
end

hook.Add("PostDrawEffects", "RenderOutlines", function()
	hook.Run("PreDrawOutline")

	if #List == 0 then return end

	for k, v in ipairs(List) do
		outline.Render(v)
	end

	List = {}
end)
