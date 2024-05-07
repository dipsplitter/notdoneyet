--[[
	How is UI organized?
	
	SCRIPTS
	- Elements: classes with general base functionalities that can be overriden or implemented with components
		- Ex: ValueBar
	- Components: modules that extend base components via composition
		- Ex: HealthBar extends ValueBar by adding listeners to the client's health
		- Should reference resource in a variable named RESOURCE and should return a table with member "Object" that references the created class
	- Services: singletons that dictate how a particular UI menu or HUD works, communicates with components
	
	DATA
	- Layouts: descriptions of the relative positions of UI elements within a larger component (e.g. ScreenGui, major frame)
	- Schemes: definitions of globals such as colors, fonts, border styles, icons, etc.
	- Resources: dictate the visual appearance of a UI component or wrapper, used to override its template
	- Templates: the default "look" of a given UI component, can be overriden if its resource definition differs
	
	RESOURCE FORMAT
	
	Name: same as component name
	ScreenGui: the default ScreenGui parent of the component
	
	Config: settings for the component script
	
	Globals: declare aliases for fonts, colors, borders, and other scheme entries
	
	Animations:
	- Styles: tween info objects
	- Animation name:
		- StopEvents, StartEvents: array of animations to stop or start after the specified timestamp
		- Component name: information below will be used to animate the component
			- Style: which style to use
			- GoalProperties
			
	Components:
	- Component name:
		- Type: the Roblox class name
		- FieldName: should be the same as the component name, how the component will be identified
			- Main: implied as the root component; all other components will be parented under Main by default
		- Dynamic: if true, the parser will not automatically create the component when the resource is applied
		- Parent: the field name of the component's parent; automatically the component called "Main"
]]
local CollectionService = game:GetService("CollectionService")

local Gui = script.Parent
local ScreenGuiFolder = Gui.ScreenGui
local ResourceFolder = Gui.Resources
local LayoutsFolder = Gui.Layouts
local SchemesFolder = Gui.Schemes
local ServicesFolder = Gui.Services
local ComponentsFolder = Gui.Components
local TemplatesFolder = Gui.Templates
local ElementsFolder = Gui.Elements

--local Parser = require(Gui.ResourceParser)

local Players = game:GetService("Players")
local playerGui = Players.LocalPlayer.PlayerGui

local UiFramework = {}

function UiFramework.Initialize()
	task.spawn(function()
		for i, screenGui in ScreenGuiFolder:GetChildren() do
			screenGui:Clone().Parent = playerGui
		end

		local startTime = os.clock()
		for i, service in ServicesFolder:GetChildren() do
			require(service)
		end
		
		require(script.Parent.UiViewHandler)

		print(`[UI]: All services loaded in {os.clock() - startTime} seconds.`)
	end)
end

function UiFramework.GetResource(resourceName)
	return require(ResourceFolder:FindFirstChild(`Res_{resourceName}`, true))
end

function UiFramework.GetLayout(layoutName)
	return require(LayoutsFolder:FindFirstChild(layoutName, true))
end

function UiFramework.GetComponent(componentName)
	return require(ComponentsFolder:FindFirstChild(componentName, true))
end

function UiFramework.GetElement(elementName)
	return require(ElementsFolder:FindFirstChild(elementName, true))
end

function UiFramework.GetService(serviceName)
	return require(ServicesFolder:FindFirstChild(serviceName))
end

function UiFramework.GetScreenGui(screenGui)
	return playerGui:FindFirstChild(screenGui)
end

function UiFramework.GetPlayerGui()
	return playerGui
end

function UiFramework.GetTemplate(templateName)

end

function UiFramework.ApplyResource(gui, resourceData)
	if type(resourceData) == "string" then
		resourceData = UiFramework.GetResource(resourceData)
	end
	
	local parser = require(Gui.ResourceParser).new(resourceData)
	parser:LoadGui(gui)
	parser:ApplyResource()
	
	return parser.LoadedGui
end

function UiFramework.CreateComponent(resourceData)
	if type(resourceData) == "string" then
		resourceData = UiFramework.GetResource(resourceData)
	end
	
	local name = resourceData.Name
	local folder = TemplatesFolder:FindFirstChild(name)
	
	local template
	if folder then
		template = folder[name]
	else
		template = Instance.new(resourceData.Main.Type or "Frame")
		template.Name = name
	end
	
	return UiFramework.ApplyResource(template, resourceData)
end

function UiFramework.SetText(labelType, text)
	for i, textItem in CollectionService:GetTagged(labelType) do
		textItem.Text = text
	end
end

function UiFramework.ReloadScheme()
	for i, service in ServicesFolder:GetChildren() do
		task.spawn(function()
			local module = require(service)
			module.OnSchemeReload()
		end)
	end
end

return UiFramework