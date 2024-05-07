local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

local Gui = script.Parent
local ScreenGuiFolder = Gui.ScreenGui

local screenGuis = {}
local fallbackGuis = {}
local layerQueues = {}

local displayOrders = {}

for i, screenGui in playerGui:GetChildren() do
	if not screenGui:IsA("ScreenGui") then
		continue
	end
	
	screenGuis[screenGui.Name] = screenGui
	displayOrders[screenGui.Name] = screenGui.DisplayOrder
	
	-- The active attribute
	screenGui:SetAttribute("Active", false)
	
	local category = screenGui:GetAttribute("Category")
	if category then
		layerQueues[category] = {}
		if screenGui:GetAttribute("Fallback") then
			fallbackGuis[category] = screenGui
		end
	end
end

local UiViewHandler = {}

function UiViewHandler.Enable(screenGuiName)
	local screenGui = playerGui[screenGuiName]
	
	local category = screenGui:GetAttribute("Category")
	
	if category then
		table.insert(layerQueues[category], screenGui)
	end
	
	local shouldBeImmediatelyVisible = true
	
	for name, screenGuiObject in screenGuis do
		-- Disable screen guis of a lower order? (probably wrong)
		if displayOrders[screenGuiName] > displayOrders[name] then
			screenGuiObject.Enabled = false
		end
		
		-- If there's a currently active gui with a higher priority, don't enable our current gui
		if screenGuiObject:GetAttribute("Active") == true and displayOrders[name] > displayOrders[screenGuiName] then
			shouldBeImmediatelyVisible = false
		end
	end
	
	screenGui.Enabled = shouldBeImmediatelyVisible
	screenGui:SetAttribute("Active", true)
end

function UiViewHandler.Disable(screenGuiName)
	local screenGui = playerGui[screenGuiName]

	local category = screenGui:GetAttribute("Category")
	
	if category then
		local queue = layerQueues[category]
		
		for i, screenGuiObject in queue do
			if screenGuiObject.Name == screenGuiName then
				table.remove(queue, i)
			end
		end
		
		local uiToEnable = queue[#queue]
		if not uiToEnable then
			uiToEnable = fallbackGuis[category]
		end
		-- Enable the next layer down if it exists
		-- If not, enable the fallback
		if uiToEnable then
			uiToEnable.Enabled = true
			uiToEnable:SetAttribute("Active", true)
		end
	end
	
	screenGui.Enabled = false
	screenGui:SetAttribute("Active", false)
	
	-- Enable a previously active screen gui with the highest display order
	local greatestDisplayOrder, correspondingGui = -math.huge, nil
	for screenGuiName, screenGuiObject in screenGuis do
		if not screenGuiObject:GetAttribute("Active") or screenGuiObject.Name == screenGui.Name then
			continue
		end
		
		local displayOrder = screenGuiObject.DisplayOrder
		if displayOrder > greatestDisplayOrder then
			greatestDisplayOrder = displayOrder
			correspondingGui = screenGuiObject
		end
	end
	
	if correspondingGui then
		correspondingGui.Enabled = true
	end
end

function UiViewHandler.DisableCategory(categoryName)
	local queue = layerQueues[categoryName]
	if not queue then
		return
	end
	
	if #queue == 0 then
		return
	end
	
	for i, screenGuiObject in queue do
		screenGuiObject.Enabled = false
		screenGuiObject:SetAttribute("Active", false)
	end
end

function UiViewHandler.EnableCategory(categoryName)
	local queue = layerQueues[categoryName]
	if not queue then
		return
	end

	local mostRecentLayer = queue[#queue]
	if not mostRecentLayer then
		mostRecentLayer = fallbackGuis[categoryName]
	end
	
	if mostRecentLayer then
		mostRecentLayer.Enabled = true
		mostRecentLayer:SetAttribute("Active", true)
	end
end

return UiViewHandler
