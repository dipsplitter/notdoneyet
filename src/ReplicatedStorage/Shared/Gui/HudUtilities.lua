local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local UiFramework = Framework.GetShared("UiFramework")
local LayoutParser = Framework.GetShared("LayoutParser")

local Client = Framework.GetClient("Client")

local HudUtilities = {}

function HudUtilities.InitializeClientConnections(layout, componentModules, activeElements)
	if Client.Character then
		HudUtilities.OnCharacterAdded(layout, componentModules, activeElements)
	end
	Client.CharacterAddedSignal:Connect(function()
		HudUtilities.OnCharacterAdded(layout, componentModules, activeElements)
	end)

	Client.CharacterDiedSignal:Connect(function(character)
		for name, component in activeElements do
			component:OnClientDeath()
		end
	end)
end

function HudUtilities.OnCharacterAdded(layout, componentModules, activeElements)
	for hudElementName, data in layout do
		if hudElementName == "Name" then
			continue
		end
		
		local module = componentModules[hudElementName]
		if not module then
			continue
		end

		local currentHudElement = activeElements[hudElementName]
		if not currentHudElement then
			activeElements[hudElementName] = module.Create()
			currentHudElement = activeElements[hudElementName]
		end
		
		currentHudElement:OnHudInitialize()
	end
	
	LayoutParser.ApplyLayoutsToComponents(componentModules, layout)
end

function HudUtilities.SetParent(object, resource)
	local parent = object.Parent
	
	if not parent or not (typeof(parent) == "Instance" and parent:IsA("ScreenGui")) then
		object.Parent = UiFramework.GetScreenGui(resource.ScreenGui or "Hud")
	end
end

return HudUtilities
