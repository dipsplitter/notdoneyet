local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local UiFramework = Framework.GetShared("UiFramework")
local RecycledSpawn = Framework.GetShared("RecycledSpawn")
local PropertySetters =  Framework.GetShared("UiPropertySetters")
local ComponentParser = Framework.GetShared("ComponentParser")
local CreateUiComponent = Framework.GetShared("CreateUiComponent")

local playerGui = UiFramework.GetPlayerGui()

local LayoutParser = {}

function LayoutParser.Apply(layout)
	local parent
	if layout.ScreenGui then
		parent = UiFramework.GetScreenGui(layout.ScreenGui)
	else
		parent = playerGui:FindFirstChild(layout.Name, true)
	end
	
	for sublayoutName, data in layout do
		if sublayoutName == "ScreenGui" or sublayoutName == "Name" then
			continue
		end
		
		local gui = CreateUiComponent(data)
		gui.BackgroundTransparency = 1
		gui.Name = sublayoutName
		
		RecycledSpawn(function()
			for functionName in ComponentParser do
				ComponentParser[functionName](gui, data)
			end
		end)
		
		gui.Parent = parent
	end
end

-- Individual component
function LayoutParser.OverrideComponentPropertiesWithLayout(guiObject, componentName, layoutModule)
	if type(guiObject) == "table" then
		-- Get the base GuiObject object from the class
		local temp = guiObject.Object
		if temp then
			guiObject = temp
		end
	end 

	local components = guiObject.Components
	local componentLayout = layoutModule[componentName]	
	if not componentLayout or not components then
		return
	end
	
	local defaultParent = playerGui:FindFirstChild(layoutModule.Name or layoutModule.ScreenGui, true)
	
	RecycledSpawn(function()
		for elementName, data in componentLayout do
			if type(data) ~= "table" or PropertySetters[elementName] then
				continue
			end
			
			local gui = components[elementName]

			if not gui then
				continue
			end
			
			-- Directly set the properties without checking if we should
			for functionName in ComponentParser do
				PropertySetters[functionName](gui, componentLayout[elementName])
			end
		end
		
		local main = components.Main
		local parent = componentLayout.Parent
		if not parent then
			main.Parent = defaultParent
		else
			main.Parent = playerGui:FindFirstChild(parent, true)
		end
	end)
end

function LayoutParser.ApplyLayoutsToComponents(componentList, layoutModule)
	for componentName, module in componentList do
		local layoutEntry = layoutModule[componentName]
		
		if not layoutEntry then
			continue
		end
		
		local guiObject = module.Object
		if not guiObject then
			continue
		end
		LayoutParser.OverrideComponentPropertiesWithLayout(guiObject, componentName, layoutModule)
	end
end

return LayoutParser
