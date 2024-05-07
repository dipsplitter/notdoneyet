local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local ResourceParser = Framework.GetShared("ResourceParser")
local GetSchemeGlobal = Framework.GetShared("GetSchemeGlobal")

local ParseFunctions = {}

function ParseFunctions.SizeScale(propsTable, component, value)
	local componentSize = component.Size
	local sizeX = componentSize.X
	local sizeY = componentSize.Y

	propsTable[component].Size = UDim2.new(sizeX.Scale * value, sizeX.Offset * value, sizeY.Scale * value, sizeY.Offset * value)
end

function ParseFunctions.PositionDelta(propsTable, component, value)
	local currentPosition
	
	if component:IsA("BillboardGui") then
		currentPosition = component.StudsOffset
		propsTable[component].StudsOffset = currentPosition + value
	else
		currentPosition = component.Position
		propsTable[component].Position = currentPosition + value
	end
end

-- This is incredibly annoying
function ParseFunctions.TextStroke(propsTable, component, value, resource)
	local uiTextStroke = component:FindFirstChild("TextStroke", true)

	if not uiTextStroke then
		return
	end
	
	local props = propsTable[uiTextStroke]
	if not props then
		propsTable[uiTextStroke] = {}
		props = propsTable[uiTextStroke]
	end
	
	props.Transparency = value.Transparency
	props.Thickness = value.Thickness
	props.Color = GetSchemeGlobal.Typed(resource, "Colors", value.Color)
end

-- It's... the exact same
function ParseFunctions.Stroke(propsTable, component, value, resource)
	local uiStroke = component:FindFirstChild("UIStroke", true)

	if not uiStroke then
		return
	end

	local props = propsTable[uiStroke]
	if not props then
		propsTable[uiStroke] = {}
		props = propsTable[uiStroke]
	end

	props.Transparency = value.Transparency
	props.Thickness = value.Thickness
	props.Color = GetSchemeGlobal.Typed(resource, "Colors", value.Color)
end


local ParseAnimationProperties = {}

-- Used for parsing initial states too
function ParseAnimationProperties.ParseGoals(component, props, resource)
	if not props then
		return {}
	end
	
	local result = {
		[component] = {}
	}

	for name, value in props do
		-- Check if the object has the property
		local success, results = pcall(function()
			return component[name]
		end)
		success = success and not component:FindFirstChild(name)

		if not success then
			ParseFunctions[name](result, component, value, resource)
		else
			if type(value) == "string" then
				value = GetSchemeGlobal.Untyped(resource, value)
			end
			result[component][name] = value
		end
	end

	return result
end

function ParseAnimationProperties.ParseInitials(component, goalProps)
	local result = {}
	
	for instance, goals in goalProps do
		result[instance] = {}
		local currentEntry = result[instance]
		
		for propertyName in goals do
			currentEntry[propertyName] = instance[propertyName]
		end
	end
	
	return result
end

return ParseAnimationProperties
