local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local RecycledSpawn = Framework.GetShared("RecycledSpawn")
local PropertySetters =  Framework.GetShared("UiPropertySetters")
local GetSchemeGlobal = Framework.GetShared("GetSchemeGlobal")
local InstanceUtilities = Framework.GetShared("InstanceUtilities")

local function DestroyGuiChild(parent, className, childName)
	local existing = InstanceUtilities.FindFirstChildOfClassNameAndName(parent, className, childName)

	if existing then
		existing:Destroy()
	end
end

local ComponentParser = {}

--[[
	Data:
	1) Entire entry that has an "AspectRatio" key paired to a number
	2) An "AspectRatio" sub-table with "Ratio", "Type", and "Axis" keys
]]
function ComponentParser.AspectRatio(gui, data)
	local ratio = data.AspectRatio

	if not ratio then
		DestroyGuiChild(gui, "UIAspectRatioConstraint")
		return
	end

	PropertySetters.AspectRatio(gui, data)
end

--[[
	Data: a "Padding" sub-table within the entry
]]
function ComponentParser.Padding(gui, data)
	if not data.Padding then
		DestroyGuiChild(gui, "UIPadding")
		return
	end

	PropertySetters.Padding(gui, data)
end

--[[
	Data: sub-table "ListLayout"
]]
function ComponentParser.ListLayout(gui, data)
	if not data.ListLayout then
		DestroyGuiChild(gui, "UIListLayout")
		return
	end

	PropertySetters.ListLayout(gui, data)
end

function ComponentParser.FlexBehavior(gui, data)
	if not data.FlexBehavior then
		DestroyGuiChild(gui, "UIFlexItem")
		return
	end

	PropertySetters.FlexBehavior(gui, data)
end

function ComponentParser.GridLayout(gui, data)
	if not data.GridLayout then
		DestroyGuiChild(gui, "UIGridLayout")
		return
	end
	
	PropertySetters.GridLayout(gui, data)
end

function ComponentParser.Size(gui, data)
	PropertySetters.Size(gui, data)

	if data.MaxSize or data.MinSize then
		PropertySetters.SizeConstraint(gui, data)
	end
end

function ComponentParser.Position(gui, data)
	-- It must have a Position property
	if not gui:IsA("GuiObject") then
		return
	end

	PropertySetters.Position(gui, data)
end

--[[
	Data: a "Stroke" sub-table
	NOTE: This is for borders
]]
function ComponentParser.BorderStroke(gui, data, resource)
	if not data.Stroke then
		DestroyGuiChild(gui, "UIStroke")
		return
	end

	PropertySetters.BorderStroke(gui, data, resource)
end

function ComponentParser.Gradient(gui, data, resource)
	if not data.Gradient then
		DestroyGuiChild(gui, "UIGradient")
		return
	end

	PropertySetters.Gradient(gui, data, resource)
end

function ComponentParser.Corner(gui, data)
	local cornerRadius = data.CornerRadius
	if not cornerRadius then
		DestroyGuiChild(gui, "UICorner")
		return
	end

	PropertySetters.Corner(gui, data)
end

function ComponentParser.Text(gui, data, resource)
	if not gui:IsA("TextLabel") and not gui:IsA("TextBox") and not gui:IsA("TextButton") then
		return
	end

	if data.MaxTextSize or data.MinTextSize then
		PropertySetters.TextSizeConstraint(gui, data)
	else
		DestroyGuiChild(gui, "UITextSizeConstraint")
	end

	local fontStrokeData = GetSchemeGlobal.Typed(resource, "Fonts", data.FontFace)
	if fontStrokeData then
		fontStrokeData = fontStrokeData.Stroke
	end
	
	local resourceStrokeData = data.TextStroke
	if not fontStrokeData and not resourceStrokeData then
		DestroyGuiChild(gui, "UIStroke", "TextStroke")
	end

	PropertySetters.Text(gui, data, resource)
end

function ComponentParser.Image(gui, data, resource)
	if not gui:IsA("ImageLabel") and not gui:IsA("ImageButton") then
		return
	end

	PropertySetters.Image(gui, data, resource)
end

function ComponentParser.Background(gui, data, resource)
	PropertySetters.Background(gui, data, resource)
end

function ComponentParser.Misc(gui, data)
	PropertySetters.Misc(gui, data)
end

function ComponentParser.Border(gui, data, resource)
	PropertySetters.Border(gui, data, resource)
end

function ComponentParser.Button(gui, data)
	if not gui:IsA("GuiButton") then
		return
	end
	
	PropertySetters.Button(gui, data)
end

return ComponentParser
