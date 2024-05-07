local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local UiFramework = Framework.GetShared("UiFramework")
local HudUtilities = Framework.GetShared("HudUtilities")

local PlayerStatusLayout = UiFramework.GetLayout("PlayerStatus")
local Client = Framework.GetClient("Client")

local componentModules = {
	HealthBar = UiFramework.GetComponent("HealthBar"),
	ArmorBar = UiFramework.GetComponent("ArmorBar"),
}
local activeElements = {}

local PlayerStatus = {}

function PlayerStatus.OnSchemeReload()
	for name, module in componentModules do
		module.OnSchemeReload()
	end
end
HudUtilities.InitializeClientConnections(PlayerStatusLayout, componentModules, activeElements)

return PlayerStatus

