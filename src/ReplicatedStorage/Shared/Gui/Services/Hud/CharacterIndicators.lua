local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local UiFramework = Framework.GetShared("UiFramework")
local EnumService = Framework.GetShared("EnumService")
local IndicatorTypes = EnumService.GetEnum("Enum_IndicatorTypes")

local NETWORK = Framework.Network()
local IndicatorEvent = NETWORK.Event("Indicator")

local indicatorComponents = {}

local CharacterIndicators = {}

function CharacterIndicators.OnSchemeReload()
	
end

IndicatorEvent:Connect(function(args)
	local indicatorType = args.Type
	local newIndicator = indicatorComponents[indicatorType].Create(args)
end)

-- Initialize all indicator components
for indicatorType, value in IndicatorTypes do
	if type(value) == "function" then
		continue
	end
	
	indicatorComponents[indicatorType] = UiFramework.GetComponent(`{indicatorType}Indicator`)
end

return CharacterIndicators
