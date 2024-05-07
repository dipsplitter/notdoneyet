local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local GetSchemeGlobal = Framework.GetShared("GetSchemeGlobal")
local RbxAssets = Framework.GetShared("RbxAssets")
local AssetService = Framework.GetShared("AssetService")
local InstanceUtilities = Framework.GetShared("InstanceUtilities")

local CollectionService = game:GetService("CollectionService")

local Gui = script.Parent
local SchemesFolder = Gui.Schemes

local schemes = {
	Fonts = require(SchemesFolder.Fonts),
	Colors = require(SchemesFolder.Colors),
}

local anchorPoints = {
	Center = Vector2.new(0.5, 0.5),
	TopRight = Vector2.new(1, 0),
	TopLeft = Vector2.new(0, 0),
	Top = Vector2.new(0.5, 0),

	Left = Vector2.new(0, 0.5),
	Right = Vector2.new(1, 0.5),

	BottomLeft = Vector2.new(0, 1),
	BottomRight = Vector2.new(1, 1),
	Bottom = Vector2.new(0.5, 1),
}

local function GetGuiChild(parent, className, childName)
	local existing
	if childName then
		existing = InstanceUtilities.FindFirstChildOfClassNameAndName(parent, className, childName)
	else
		existing = parent:FindFirstChildOfClass(className)
	end

	if existing then
		return existing
	else
		local instance = Instance.new(className)

		if childName then
			instance.Name = childName
		end

		instance.Parent = parent
		return instance
	end
end

local function GetColorSequence(values, resource)
	local keypointsArray = {}
	for i, keypointData in values do
		local t = keypointData[1]
		local color = GetSchemeGlobal.Typed(resource, "Colors", keypointData[2])
		table.insert(keypointsArray, ColorSequenceKeypoint.new(t, color))
	end

	return ColorSequence.new(keypointsArray)
end

local UiPropertySetters = {}

function UiPropertySetters.AspectRatio(gui, data)
	local aspectRatioData = data.AspectRatio
	if not aspectRatioData then
		return
	end
	
	local uiAspectRatio = GetGuiChild(gui, "UIAspectRatioConstraint")
	
	if type(aspectRatioData) == "table" then

		uiAspectRatio.AspectRatio = aspectRatioData.Ratio
		
		if aspectRatioData.Type then
			uiAspectRatio.AspectType = aspectRatioData.Type
		end
		
		if aspectRatioData.Axis then
			uiAspectRatio.DominantAxis = aspectRatioData.Axis
		end
		
	elseif type(aspectRatioData) == "number" then

		uiAspectRatio.AspectRatio = aspectRatioData

	end
end

function UiPropertySetters.Padding(gui, data)
	data = data.Padding
	if not data then
		return
	end
	
	local uiPadding = GetGuiChild(gui, "UIPadding")
	
	local verticalPadding = data.Vertical
	if verticalPadding then
		uiPadding.PaddingTop = verticalPadding
		uiPadding.PaddingBottom = verticalPadding
	end

	local horizontalPadding = data.Horizontal
	if horizontalPadding then
		uiPadding.PaddingLeft = horizontalPadding
		uiPadding.PaddingRight = horizontalPadding
	end

	-- Apply specific padding next
	if data.Left then
		uiPadding.PaddingLeft = data.Left
	end

	if data.Right then
		uiPadding.PaddingRight = data.Right
	end

	if data.Top then
		uiPadding.PaddingTop = data.Top
	end

	if data.Bottom then
		uiPadding.PaddingBottom = data.Bottom
	end
end

function UiPropertySetters.ListLayout(gui, data)
	if not data.ListLayout then
		return
	end
	
	local uiListLayout = GetGuiChild(gui, "UIListLayout")
	
	for propertyName, property in data.ListLayout do
		pcall(function()
			uiListLayout[propertyName] = property
		end)
	end
end

function UiPropertySetters.FlexBehavior(gui, data)
	if not data.FlexBehavior then
		return
	end

	local uiFlexItem = GetGuiChild(gui, "UIFlexItem")

	for propertyName, property in data.FlexBehavior do
		pcall(function()
			uiFlexItem[propertyName] = property
		end)
	end
end

function UiPropertySetters.GridLayout(gui, data)
	if not data.GridLayout then
		return
	end

	local uiGridLayout = GetGuiChild(gui, "UIGridLayout")

	for propertyName, property in data.GridLayout do
		pcall(function()
			uiGridLayout[propertyName] = property
		end)
	end
end

function UiPropertySetters.Size(gui, data)
	local sizeX = data.SizeX
	local sizeY = data.SizeY
	
	if not sizeX and not sizeY then
		return
	end

	local newSize
	
	if sizeX and sizeY then
		newSize = UDim2.new(sizeX, sizeY)
	elseif sizeX then
		newSize = UDim2.new(sizeX, gui.Size.Y)
	elseif sizeY then
		newSize = UDim2.new(gui.Size.X, sizeY)
	end

	if newSize then
		gui.Size = newSize
	end
	
	-- Doesn't apply to billboards
	if gui:IsA("GuiObject") then
		gui.AutomaticSize = data.AutomaticSize or Enum.AutomaticSize.None
	end

end

function UiPropertySetters.SizeConstraint(gui, data)
	local max = data.MaxSize
	local min = data.MinSize
	
	if not max and not min then
		return
	end
	
	local uiSizeConstraint = GetGuiChild(gui, "UISizeConstraint")
	
	uiSizeConstraint.MaxSize = max or Vector2.new(math.huge, math.huge)
	uiSizeConstraint.MinSize = min or Vector2.zero
end

function UiPropertySetters.Position(gui, data)
	local anchorPoint = data.AnchorPoint
	if anchorPoint then
		if type(anchorPoint) == "string" then
			anchorPoint = anchorPoints[anchorPoint]
		end

		gui.AnchorPoint = anchorPoint
	end
	
	local posX = data.PosX
	local posY = data.PosY
	
	if posX and posY then
		gui.Position = UDim2.new(posX, posY)
	elseif posX then
		gui.Position = UDim2.new(posX, gui.Position.Y)
	elseif posY then
		gui.Position = UDim2.new(gui.Position.X, posY)
	end
end

function UiPropertySetters.BorderStroke(gui, data, resource)
	data = data.Stroke
	if not data then
		return
	end
	
	local uiStroke = GetGuiChild(gui, "UIStroke")
	
	if data.Thickness then
		uiStroke.Thickness = data.Thickness
	end

	if data.Transparency then
		uiStroke.Transparency = data.Transparency
	end

	if data.Color and resource then
		uiStroke.Color = GetSchemeGlobal.Typed(resource, "Colors", data.Color)
	end

	if data.LineJoinMode then
		uiStroke.LineJoinMode = data.LineJoinMode
	end
	
	uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
end

function UiPropertySetters.Gradient(gui, data, resource)
	data = data.Gradient
	if not data then
		return
	end
	
	local uiGradient = GetGuiChild(gui, "UIGradient")
	
	for propertyName, value in data do
		-- Parse a ColorSequence
		if propertyName == "Color" and type(value) == "table" and resource then
			uiGradient.Color = GetColorSequence(value, resource)
		else
			pcall(function()
				uiGradient[propertyName] = value
			end)
		end
	end
	
end

function UiPropertySetters.Corner(gui, data)
	if not data.CornerRadius then
		return
	end
	
	local uiCorner = GetGuiChild(gui, "UICorner")
	
	uiCorner.CornerRadius = data.CornerRadius
end

local function TextStroke(gui, data, resource)
	local uiStroke = GetGuiChild(gui, "UIStroke", "TextStroke")

	if data.Thickness then
		uiStroke.Thickness = data.Thickness
	end

	if data.Transparency then
		uiStroke.Transparency = data.Transparency
	end

	if data.Color and resource then
		uiStroke.Color = GetSchemeGlobal.Typed(resource, "Colors", data.Color)
	end

	if data.Corner then
		uiStroke.LineJoinMode = data.Corner
	end
	
	uiStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
end

function UiPropertySetters.Text(gui, data, resource)
	if not gui:IsA("TextLabel") and not gui:IsA("TextBox") and not gui:IsA("TextButton") then
		return
	end
	
	local fontData
	if resource  then
		fontData = GetSchemeGlobal.Typed(resource, "Fonts", data.FontFace)
		
		if fontData then
			gui.FontFace = fontData.FontFace
		end
		
	end
	
	if data.RichText then
		gui.RichText = data.RichText
	end

	local labelText = data.LabelText or ""
	gui.Text = labelText

	-- TODO: Import utilities for this shit !!!

	-- Clear the text item's previous label tag and replace with the new one if it exists
	for i, tag in CollectionService:GetTags(gui) do
		CollectionService:RemoveTag(gui, tag)
	end
	if string.sub(labelText, #labelText, #labelText) == "%" and string.sub(labelText, 1, 1) == "%" then
		CollectionService:AddTag(gui, labelText)
	end
	
	if data.TextSize then
		gui.TextSize = data.TextSize
	end

	if data.TextScaled then
		gui.TextScaled = data.TextScaled
	end

	if data.TextTransparency then
		gui.TextTransparency = data.TextTransparency
	end

	if data.TextXAlignment then
		gui.TextXAlignment = data.TextXAlignment
	end

	if data.TextYAlignment then
		gui.TextYAlignment = data.TextYAlignment
	end
	
	if data.TextWrapped then
		gui.TextWrapped = data.TextWrapped
	end

	-- Color
	if data.TextColor and resource then
		gui.TextColor3 = GetSchemeGlobal.Typed(resource, "Colors", data.TextColor)
	end

	-- Bold, italics
	if data.FontWeight then
		gui.FontFace.Weight = Enum.FontWeight[data.FontWeight]
	end

	if data.FontStyle then
		gui.FontFace.Style = Enum.FontStyle[data.FontStyle]
	end
	
	if fontData and fontData.Stroke then
		TextStroke(gui, fontData.Stroke, resource)
	end

	if data.TextStroke then
		TextStroke(gui, data.TextStroke, resource)
	end
end

function UiPropertySetters.TextSizeConstraint(gui, data)
	local max = data.MaxTextSize
	local min = data.MinTextSize
	
	if not max and not min then
		return
	end
	
	local uiTextSizeConstraint = GetGuiChild(gui, "UITextSizeConstraint")
	
	uiTextSizeConstraint.MaxTextSize = max or 100
	uiTextSizeConstraint.MinTextSize = min or 1
end

function UiPropertySetters.Background(gui, data, resource)
	if data.BackgroundColor and resource then
		gui.BackgroundColor3 = GetSchemeGlobal.Typed(resource, "Colors", data.BackgroundColor)
	end

	if data.BackgroundTransparency then
		gui.BackgroundTransparency = data.BackgroundTransparency
	end
end

function UiPropertySetters.Misc(gui, data)
	if data.Visible == false then
		gui.Visible = false
	end

	if data.ZIndex then
		gui.ZIndex = data.ZIndex
	end

	if data.LayoutOrder then
		gui.LayoutOrder = data.LayoutOrder
	end
	
	if data.Rotation then
		gui.Rotation = data.Rotation
	end
end

function UiPropertySetters.Border(gui, data, resource)
	if data.BorderSize then
		gui.BorderSizePixel = data.BorderSize
	end
	
	if data.BorderColor and resource then
		gui.BorderColor3 = GetSchemeGlobal.Typed(resource, "Colors", data.BorderColor)
	end
	
	-- TEMP
	if data.BorderMode then
		gui.BorderMode = data.BorderMode
	end
end

function UiPropertySetters.Image(gui, data, resource)
	if not gui:IsA("ImageButton") and not gui:IsA("ImageLabel") then
		return
	end
	
	if data.ScaleType then
		gui.ScaleType = data.ScaleType
	else
		gui.ScaleType = Enum.ScaleType.Fit
	end
	
	if data.ImageColor and resource then
		gui.ImageColor3 = GetSchemeGlobal.Typed(resource, "Colors", data.ImageColor)
	end
	
	if data.ImageTransparency then
		gui.ImageTransparency = data.ImageTransparency
	end
	
	if data.Image then
		if RbxAssets.HasPrefix(data.Image) then
			gui.Image = data.Image
		else
			gui.Image = AssetService.Images(data.Image).Id
		end
	end
end

function UiPropertySetters.Button(gui, data)
	if data.Modal then
		gui.Modal = data.Modal
	end
	
	if data.AutoButtonColor then
		gui.AutoButtonColor = data.AutoButtonColor
	end
end

return UiPropertySetters
