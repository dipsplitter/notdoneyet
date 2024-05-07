local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local UiFramework = Framework.GetShared("UiFramework")
local LayoutParser = Framework.GetShared("LayoutParser")
local UiViewHandler = Framework.GetShared("UiViewHandler")

local Client = Framework.GetClient("Client")

local HudLayout = UiFramework.GetLayout("Hud")
LayoutParser.Apply(HudLayout)

local componentServices = {
	PlayerStatus = require(script.PlayerStatus),
	CharacterIndicators = require(script.CharacterIndicators),
	ItemStatus = require(script.ItemStatus),
	Hotbars = require(script.Hotbars)
}

local Hud = {
	
}

function Hud.ToggleVisible(state)
	
end

function Hud.OnSchemeReload()
	for componentName, service in componentServices do
		service.OnSchemeReload()
	end
end

if Client.Character then
	UiViewHandler.Enable("Hud")
end
Client.CharacterAddedSignal:Connect(function()
	UiViewHandler.Enable("Hud")
end)

Client.CharacterDiedSignal:Connect(function()
	UiViewHandler.Disable("Hud")
end)

return Hud
