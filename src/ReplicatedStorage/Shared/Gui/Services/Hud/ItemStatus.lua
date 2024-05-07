local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local UiFramework = Framework.GetShared("UiFramework")
local HudUtilities = Framework.GetShared("HudUtilities")

local ItemStatusLayout = UiFramework.GetLayout("ItemStatus")
local Client = Framework.GetClient("Client")

local componentModules = {
	AmmoCounter = UiFramework.GetComponent("AmmoCounter"),
}
local activeElements = {}

local ItemStatus = {}

function ItemStatus.OnSchemeReload()
	for name, module in componentModules do
		module.OnSchemeReload()
	end
end
HudUtilities.InitializeClientConnections(ItemStatusLayout, componentModules, activeElements)

return ItemStatus
