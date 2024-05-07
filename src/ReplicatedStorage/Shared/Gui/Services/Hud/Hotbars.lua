local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local UiFramework = Framework.GetShared("UiFramework")
local HudUtilities = Framework.GetShared("HudUtilities")
local LayoutParser = Framework.GetShared("LayoutParser")

local HotbarLayout = UiFramework.GetLayout("Hotbars")
LayoutParser.Apply(HotbarLayout)

local Client = Framework.GetClient("Client")

local componentModules = {
	ItemsHotbar = UiFramework.GetComponent("ItemsHotbar"),
}
local activeElements = {}

local Hotbars = {}

function Hotbars.OnSchemeReload()
	for name, module in componentModules do
		module.OnSchemeReload()
	end
end

HudUtilities.InitializeClientConnections(HotbarLayout, componentModules, activeElements)

return Hotbars
