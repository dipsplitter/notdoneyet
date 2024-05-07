local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local RecycledSpawn = Framework.GetShared("RecycledSpawn")
local PropertySetters =  Framework.GetShared("UiPropertySetters")
local ResourceUtilities = Framework.GetShared("ResourceUtilities")
local ComponentParser = Framework.GetShared("ComponentParser")
local CreateUiComponent = Framework.GetShared("CreateUiComponent")

local specialKeys = {
	Fonts = true,
	Colors = true,
	Config = true,
	Animations = true,
	Name = true,
	ScreenGui = true,
	Component = true,
	Override = true,
	States = true,
}

local ResourceParser = {}
ResourceParser.__index = ResourceParser

function ResourceParser.new(resourceModule)
	local self = {
		Resource = resourceModule,
		
		Components = {},
		
		LoadedGui = nil
	}
	setmetatable(self, ResourceParser)
	
	self:LoadResource(resourceModule)
	
	return self
end

function ResourceParser:LoadResource(module)
	self.Resource = module
	
	if module.Override then
		self.Override = true
		self.Resource = ResourceUtilities.MergeWithParentResource(module)
	end
	
	for keyName in self do
		if specialKeys[keyName] then
			self[keyName] = nil
		end
	end
	
	-- Register fonts, colors, etc.
	for keyName in module do
		if specialKeys[keyName] then
			self[keyName] = module[keyName]
		end
	end
	
	-- Unnecessary keys
	self.Config = nil
	self.Animations = nil
end

-- Load templates or pre-existing object
function ResourceParser:LoadGui(guiObject)
	table.clear(self.Components)
	
	if not guiObject then
		return
	end
	
	self.LoadedGui = guiObject
	self.Components.Main = self.LoadedGui
	
	for i, child in guiObject:GetDescendants() do
		local fieldName = child.Name
		
		if self.Resource[fieldName] then
			self.Components[fieldName] = child
		end
	end
end

function ResourceParser:SetDetails(componentName)
	for functionName in ComponentParser do
		local data = self.Resource[componentName]
		local gui = self.Components[componentName]
	
		ComponentParser[functionName](gui, data, self.Resource)
	end
end

function ResourceParser:SetDetailsOverride(componentName)
	for functionName in PropertySetters do
		local data = self.Resource[componentName]
		local gui = self.Components[componentName]

		PropertySetters[functionName](gui, data, self.Resource)
	end
end

function ResourceParser:ApplyLayoutOverrides()
	RecycledSpawn(self.SetDetails, self, "Main")
end

function ResourceParser:ApplyAsOverride()
	for componentName in self.Components do
		RecycledSpawn(self.SetDetailsOverride, self, componentName)
	end
end

function ResourceParser:ApplyResource()
	self:Create("Main")
	self:SetDetails("Main")
	
	for componentName, data in self.Resource do
		--[[
			Skip non-component sub-tables, 
			don't automatically create dynamic components, 
			we've already created Main
			don't bother with disabled elements
		]]
		if specialKeys[componentName] or data.Dynamic == true or componentName == "Main" or data.Enabled == false then
			continue
		end
		
		self:Create(componentName)
		
		-- Create all sub-components and set all colors
		RecycledSpawn(self.SetDetails, self, componentName)
	end
	
	local main = self.Components.Main
	local templatesFolder = main:FindFirstChild("Templates")
	
	if not templatesFolder then
		templatesFolder = Instance.new("Folder")
		templatesFolder.Name = "Templates"
		templatesFolder.Parent = main
	end
	
	-- Parent all components
	for componentName, data in self.Resource do
		if specialKeys[componentName] or componentName == "Main" then
			continue
		end
		
		local component = self.Components[componentName]
		if not component then
			continue
		end
		
		-- Parent to the templates folder if the component was marked as a template
		if data.Template == true then
			component.Visible = false
			component.Parent = templatesFolder
			continue
		end
		
		-- Don't reparent if it's already correct
		local parent = data.Parent or "Main"
		if component.Parent == parent then
			continue
		end
		
		component.Parent = self.Components[parent]
	end
end

function ResourceParser:Create(componentName)
	if self.Components[componentName] then
		return
	end
	
	local gui = CreateUiComponent(self.Resource[componentName])
	
	if componentName == "Main" then
		gui.Name = self.Resource.Name
		gui:SetAttribute(self.Resource.Name, true)
		if not self.LoadedGui then
			self.LoadedGui = gui
		end
	else
		gui.Name = componentName
	end
	
	self.Components[componentName] = gui
end

return ResourceParser