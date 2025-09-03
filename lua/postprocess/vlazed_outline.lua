local mat_outline = Material("pp/vlazed/outline")

local pp_outline = CreateClientConVar("pp_vlazedoutline", "0", true, false, "Enable outlines", 0, 1)
local pp_outlineDepthThreshold = CreateClientConVar("pp_vlazedoutline_depththreshold", "0.1", true, false)
local pp_outlineScale = CreateClientConVar("pp_vlazedoutline_scale", "1", true, false)
local pp_outlineDepthNormalThreshold = CreateClientConVar("pp_vlazedoutline_depthnormalthreshold", "1.0", true, false)
local pp_outlineDepthNormalThresholdScale =
	CreateClientConVar("pp_vlazedoutline_depthnormalthresholdscale", "0.00", true, false)
local pp_outlineNormalThreshold = CreateClientConVar("pp_vlazedoutline_normalthreshold", "1.59", true, false)

local pp_outlineColorRed = CreateClientConVar("pp_vlazedoutline_r", "0", true, false)
local pp_outlineColorGreen = CreateClientConVar("pp_vlazedoutline_g", "0", true, false)
local pp_outlineColorBlue = CreateClientConVar("pp_vlazedoutline_b", "0", true, false)
local pp_outlineColorAlpha = CreateClientConVar("pp_vlazedoutline_a", "255", true, false)

local pp_outlineDebug = CreateClientConVar("pp_vlazedoutline_debug", "0", true, false)
local pp_outlineDepthHigh = CreateClientConVar("pp_vlazedoutline_depthhigh", "1", true, false)
local pp_outlineDepthLow = CreateClientConVar("pp_vlazedoutline_depthlow", "0.01", true, false)

local pp_outlineLuminanceThreshold = CreateClientConVar("pp_vlazedoutline_luminancethreshold", "2", true, false)

local width, height = ScrW(), ScrH()

function render.DrawVlazedOutline()
	-- TODO: Use local variables

	render.UpdateScreenEffectTexture()
	mat_outline:SetFloat("$c0_z", pp_outlineDepthNormalThreshold:GetFloat())
	mat_outline:SetFloat("$c0_y", pp_outlineScale:GetInt())
	mat_outline:SetFloat("$c0_x", pp_outlineDepthThreshold:GetFloat())
	mat_outline:SetFloat("$c0_w", pp_outlineDepthNormalThresholdScale:GetFloat())
	mat_outline:SetFloat("$c1_x", pp_outlineNormalThreshold:GetFloat())

	mat_outline:SetFloat("$c1_z", pp_outlineDepthLow:GetFloat())
	mat_outline:SetFloat("$c1_w", pp_outlineDepthHigh:GetFloat())

	mat_outline:SetFloat("$c2_x", 1 / width)
	mat_outline:SetFloat("$c2_y", 1 / height)
	mat_outline:SetFloat("$c2_z", pp_outlineLuminanceThreshold:GetFloat())
	mat_outline:SetFloat("$c2_w", pp_outlineDebug:GetInt())

	-- TODO: Only calculate colors once after change
	mat_outline:SetFloat("$c3_x", pp_outlineColorRed:GetFloat() / 255)
	mat_outline:SetFloat("$c3_y", pp_outlineColorGreen:GetFloat() / 255)
	mat_outline:SetFloat("$c3_z", pp_outlineColorBlue:GetFloat() / 255)
	mat_outline:SetFloat("$c3_w", pp_outlineColorAlpha:GetFloat() / 255)
	render.SetMaterial(mat_outline)

	render.DrawScreenQuad()

	-- render.DrawScreenQuad()
end

local function enableOutlines()
	if pp_outline:GetBool() then
		hook.Add("RenderScreenspaceEffects", "vlazed_outline_hook", function()
			render.DrawVlazedOutline()
		end)
	else
		hook.Remove("RenderScreenspaceEffects", "vlazed_outline_hook")
	end
end

cvars.AddChangeCallback("pp_vlazedoutline", function(cvar, old, new)
	enableOutlines()
end, "vlazed_outline_callback")
enableOutlines()

list.Set("PostProcess", "Outline (vlazed)", {

	icon = "gui/postprocess/vlazedoutline.png",
	convar = "pp_vlazedoutline",
	category = "#shaders_pp",

	cpanel = function(CPanel)
		---@cast CPanel ControlPanel

		CPanel:Help("Draw an outline over the scene. More customization than the Sobel shader!")

		local options = {
			pp_vlazedoutline_scale = "2",
			pp_vlazedoutline_depththreshold = "0.1",
			pp_vlazedoutline_depthnormalthreshold = "1.0",
			pp_vlazedoutline_depthnormalthresholdscale = "0.0",
			pp_vlazedoutline_normalthreshold = "1.59",
			pp_vlazedoutline_luminancethreshold = "0.85",
			pp_vlazedoutline_r = "0",
			pp_vlazedoutline_g = "0",
			pp_vlazedoutline_b = "0",
			pp_vlazedoutline_a = "255",
			pp_vlazedoutline_debug = "0",
			pp_vlazedoutline_depthhigh = "1",
			pp_vlazedoutline_depthlow = "0.01",
		}
		CPanel:ToolPresets("vlazedoutline", options)

		CPanel:ColorPicker(
			"Color",
			"pp_vlazedoutline_r",
			"pp_vlazedoutline_g",
			"pp_vlazedoutline_b",
			"pp_vlazedoutline_a"
		)

		CPanel:CheckBox("Enable", "pp_vlazedoutline")
		CPanel:CheckBox("Debug", "pp_vlazedoutline_debug")

		CPanel:NumSlider("Scale", "pp_vlazedoutline_scale", 0, 10, 0)
		CPanel:NumSlider("Depth Threshold", "pp_vlazedoutline_depththreshold", 0, 1)
		CPanel:NumSlider("Depth Normal Threshold", "pp_vlazedoutline_depthnormalthreshold", 0, 1)
		CPanel:NumSlider("Depth Normal Threshold Scale", "pp_vlazedoutline_depthnormalthresholdscale", 0, 10)
		CPanel:NumSlider("Normal Threshold", "pp_vlazedoutline_normalthreshold", 0, 10)
		CPanel:NumSlider("Luminance Threshold", "pp_vlazedoutline_luminancethreshold", 0, 10)

		CPanel:NumSlider("Depth Near", "pp_vlazedoutline_depthlow", 0.01, 10)
		CPanel:NumSlider("Depth Far", "pp_vlazedoutline_depthhigh", 0, 10)
	end,
})
