local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local RecycledSpawn = Framework.GetShared("RecycledSpawn")
local ResourceParser = Framework.GetShared("ResourceParser")
local ResourceUtilities = Framework.GetShared("ResourceUtilities")

local UiAnimator = require(script.UiAnimator)

local GuiObject = {}
GuiObject.__index = GuiObject

function GuiObject.new(params)
	local self = {
		Resource = ResourceUtilities.MergeWithParentResource(params.Resource),
		Ui = params.Ui,
		Components = {},
		
		States = {},
		CurrentState = "Default",
	}
	setmetatable(self, GuiObject)
	
	self:RegisterComponents()
	self.Animator = UiAnimator.new(self.Ui, self.Resource)
	
	return self
end

function GuiObject:SetState(stateName)
	local states = self.Resource.States
	if not states then
		return
	end
	
	if stateName == self.CurrentState then
		return
	end
	
	local statesResource = states[stateName]

	self.CurrentState = if statesResource then stateName else "Default"
	
	self:ApplyResourceOverride(statesResource)
end

function GuiObject:GetConfig(keyName)
	local config = self.Resource.Config
	if not config then
		return
	end
	return config[keyName]
end

function GuiObject:RegisterComponents()
	if not self.Ui then
		return
	end
	
	for i, descendant in self.Ui:GetDescendants() do
		local descendantFieldName = descendant.Name
		if self.Resource[descendantFieldName] then
			self.Components[descendantFieldName] = descendant
		end
	end
	
	self.Components.Main = self.Ui
end

function GuiObject:Animate(animationName)
	RecycledSpawn(self.Animator.Animate, self.Animator, animationName)
end

function GuiObject:IsAnimationActive(animationName)
	return self.Animator:IsAnimationActive(animationName)
end

function GuiObject:Stop(animationName)
	RecycledSpawn(self.Animator.Stop, self.Animator, animationName)
end

function GuiObject:SetVisible(componentName, state)
	if type(componentName) == "string" then
		self.Components[componentName].Visible = state
	elseif type(componentName) == "table" then
		for name, value in componentName do
			self.Components[name].Visible = value
		end
	end
end

function GuiObject:ApplyResourceOverride(resource)
	local parser = ResourceParser.new(resource or self.Resource)
	parser:LoadGui(self.Ui)
	
	parser:ApplyAsOverride()
end

function GuiObject:Destroy()
	self.Ui:Destroy()
	self.AutoCleanup = true
	BaseClass.Destroy(self)
end

return GuiObject
