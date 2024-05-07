local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local InstanceCreator = Framework.GetShared("InstanceCreator")
local ParticleEmitterUtilities = Framework.GetShared("ParticleEmitterUtilities")
local TableUtilities = Framework.GetShared("TableUtilities")

local Debris = game:GetService("Debris")

local WorkspaceVisuals = workspace.Visuals
local VisualBase = script.VisualBase

local VisualEffect = {}
VisualEffect.__index = VisualEffect
VisualEffect.ClassName = "VisualEffect"
setmetatable(VisualEffect, BaseClass)

function VisualEffect.new(folder, params)
	local self = BaseClass.new()
	setmetatable(self, VisualEffect)
	
	self.ReferenceModule = folder
	self.Base = params.Base or InstanceCreator.Clone(self.ReferenceModule:FindFirstChild("Base") or VisualBase, params)
	self.Schema = params or {} -- TODO: Data modules
	self.BaseInstances = {}
	self.ActiveInstances = {}
	
	self:LogBaseInstances()
	self:SetParents()
	
	self.AutoCleanup = true
	
	if self:HasBaseParent() then
		self:AddConnections({
			Cleanup = self.Base.Destroying:Connect(function()
				self:Destroy()
			end)
		})
	end
	
	return self
end

function VisualEffect:HasBaseParent()
	return typeof(self.Base) == "Instance"
end

function VisualEffect:CloneInstance(baseInstanceName)
	if typeof(baseInstanceName) == "Instance" then
		baseInstanceName = baseInstanceName.Name
	end
	
	local clone = self.BaseInstances[baseInstanceName]:Clone()
	table.insert(self.ActiveInstances, clone)
	clone:SetAttribute("ID", #self.ActiveInstances)
	
	self:AddConnections({
		[`{clone.Name}Destroying{clone:GetAttribute("ID")}`] = clone.Destroying:Connect(function()
			self:CleanupConnection(`{clone.Name}Destroying{clone:GetAttribute("ID")}`)
			
			self.ActiveInstances[clone:GetAttribute("ID")] = nil

			if #self.ActiveInstances == 0 then
				self:Destroy()
			end
		end)
	})
	
	return clone
end

function VisualEffect:LogBaseInstances()
	local instancesFolder = self.ReferenceModule:FindFirstChild("Instances")
	if not instancesFolder then
		return
	end
	
	for i, instance in pairs(self.ReferenceModule.Instances:GetChildren()) do
		local clone = instance:Clone()
		self.BaseInstances[clone.Name] = clone
	end
end

function VisualEffect:GetBaseInstance(name)
	return self.BaseInstances[name]
end

function VisualEffect:SetParents()
	if typeof(self.Base) ~= "Instance" then
		return
	end
	
	for i, instance in pairs(self.BaseInstances) do
		local clone = self:CloneInstance(instance)
		clone.Parent = clone:GetAttribute("Parent") or self.Base
	end
	
	self.Base.Parent = WorkspaceVisuals
end

function VisualEffect:ScheduleDeletion()
	local destroyTime = self.Schema.DestroyTime or 5
	if self:HasBaseParent() then
		Debris:AddItem(self.Base, destroyTime)
	else
		for name, instance in self.ActiveInstances do
			Debris:AddItem(instance, destroyTime)
		end
	end
end

function VisualEffect:TriggerEvent(eventName)
	if eventName == "Stop" then
		self:StopSequence()
	end
end

function VisualEffect:StartSequence()
	self:EnableAll()
	
	self:ScheduleDeletion()
end

function VisualEffect:StopSequence()
	self:DisableAll()
end

function VisualEffect:EnableAll()
	for i, instance in self.ActiveInstances do
		if instance:IsA("ParticleEmitter") then
			ParticleEmitterUtilities.Activate(instance)
		end
	end
end

function VisualEffect:DisableAll()
	for i, instance in self.ActiveInstances do
		if instance:IsA("ParticleEmitter") then
			ParticleEmitterUtilities.Deactivate(instance)
		end
	end
end

function VisualEffect:Destroy()
	for name, instance in self.BaseInstances do
		self.BaseInstances[name] = nil
		instance:Destroy()
	end
	BaseClass.Destroy(self)
end

return VisualEffect
