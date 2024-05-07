--!native

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local ValueRetriever = Framework.GetShared("ValueRetriever")
local Signal = Framework.GetShared("Signal")

local ModifierEntry = require(script.ModifierEntry)

local ValueModifiers = {}
ValueModifiers.__index = ValueModifiers

function ValueModifiers.new(baseValue)
	local self = {
		Adds = {},
		Scales = {},
		BaseScales = {},
		FinalAdds = {},
		Clamps = {},
		
		Base = baseValue,
		
		AddFactor = 0,
		ScaleFactor = 1,
		BaseScaleFactor = 0,
		FinalAddFactor = 0,
		Clamp = math.huge,
		
		AllModifiers = {},
		
		InternalChanged = Signal.new(),
		Changed = Signal.new(),
		BaseChangedConnection = nil
	}
	setmetatable(self, ValueModifiers)
	
	self.InternalChanged:Connect(function(modifierType, modifierName, newValue)
		local entry = self.AllModifiers[modifierName]
		if not entry.Active then
			return
		end
		
		self:RecomputeFactor(modifierType)
	end)
	
	return self
end

function ValueModifiers:SetBaseChangedConnection(connection)
	if self.BaseChangedConnection then
		self.BaseChangedConnection:Disconnect()
	end
	
	self.BaseChangedConnection = connection
end

function ValueModifiers:ToDictionary()
	local results = { Adds = {}, Scales = {}, BaseScales = {}, FinalAdds = {}, Clamps = {}}
	for modifierName, entry in self.AllModifiers() do
		local entryType = entry.Type
		
		results[entryType][modifierName] = `{modifierName}: {entry:GetCurrentValue()}`
	end
end

function ValueModifiers:RecomputeFactor(entryType)
	if entryType == "Clamp" then
		self:ComputeClamp()
	else
		self[`Compute{entryType}Factor`](self)
	end
end

function ValueModifiers:ToggleModifier(modifierName, state)
	local entry = self.AllModifiers[modifierName]
	if not entry then
		return
	end
	
	entry.Active = state
	
	local entryType = entry.Type
	self:RecomputeFactor(entryType)
end

function ValueModifiers:Remove(modifierName)
	local entry = self.AllModifiers[modifierName]
	if not entry then
		return
	end
	
	local entryType = entry.Type
	
	entry:Destroy()
	self.AllModifiers[modifierName] = nil
	self[`{entryType}s`][modifierName] = nil
	
	self:RecomputeFactor(entryType)
end

function ValueModifiers:ComputeAddFactor()
	local newAddFactor = 0
	for modifierName, addEntry in self.Adds do
		if not addEntry.Active then
			continue
		end

		newAddFactor += addEntry:GetCurrentValue()
	end

	self.AddFactor = newAddFactor
	self.Changed:Fire()
end

function ValueModifiers:ComputeScaleFactor()
	local newScaleFactor = 1
	for modifierName, scaleEntry in self.Scales do
		if not scaleEntry.Active then
			continue
		end

		newScaleFactor *= scaleEntry:GetCurrentValue()
	end

	self.ScaleFactor = newScaleFactor
	self.Changed:Fire()
end

function ValueModifiers:ComputeBaseScaleFactor()
	local newBaseScaleFactor = 1
	for modifierName, baseScaleEntry in self.BaseScalars do
		if not baseScaleEntry.Active then
			continue
		end

		newBaseScaleFactor += baseScaleEntry:GetCurrentValue()
	end

	self.BaseScaleFactor = newBaseScaleFactor
	self.Changed:Fire()
end

function ValueModifiers:ComputeClamp()
	local newClampValue = math.huge
	for modifierName, clampEntry in self.Clamps do
		if not clampEntry.Active then
			continue
		end

		newClampValue = math.min(newClampValue, clampEntry:GetCurrentValue())
	end

	self.Clamp = newClampValue
	self.Changed:Fire()
end

function ValueModifiers:ComputeFinalAddFactor()
	local newFinalAddFactor = 0
	for modifierName, finalAddEntry in self.FinalAdds do
		if not finalAddEntry.Active then
			continue
		end

		newFinalAddFactor += finalAddEntry:GetCurrentValue()
	end

	self.FinalAddFactor = newFinalAddFactor
	self.Changed:Fire()
end

function ValueModifiers:CreateModifierEntry(modifierName, value, modifierType)
	local entry = ModifierEntry.new(modifierName, value, modifierType)
	entry:SetChangedSignal(self.InternalChanged)
	return entry
end

function ValueModifiers:SetAdd(modifierName, value)
	local existingEntry = self.Adds[modifierName]
	
	if not existingEntry then
		self.Adds[modifierName] = self:CreateModifierEntry(modifierName, value, "Add")
		self.AllModifiers[modifierName] = self.Adds[modifierName]
	else
		existingEntry:SetValue(value)
	end
	
	self:ComputeAddFactor()
end

function ValueModifiers:SetScale(modifierName, value)
	local existingEntry = self.Scales[modifierName]

	if not existingEntry then
		self.Scales[modifierName] = self:CreateModifierEntry(modifierName, value, "Scale")
		self.AllModifiers[modifierName] = self.Scales[modifierName]
	else
		existingEntry:SetValue(value)
	end
	
	self:ComputeScaleFactor()
end

function ValueModifiers:SetBaseScale(modifierName, value)
	local existingEntry = self.BaseScales[modifierName]

	if not existingEntry then
		self.BaseScales[modifierName] = self:CreateModifierEntry(modifierName, value, "BaseScale")
		self.AllModifiers[modifierName] = self.BaseScales[modifierName]
	else
		existingEntry:SetValue(value)
	end
	
	self:ComputeBaseScaleFactor()
end

function ValueModifiers:SetClamp(modifierName, value)
	local existingEntry = self.Clamps[modifierName]

	if not existingEntry then
		self.Clamps[modifierName] = self:CreateModifierEntry(modifierName, value, "Clamp")
		self.AllModifiers[modifierName] = self.Clamps[modifierName]
	else
		existingEntry:SetValue(value)
	end

	self:ComputeClamp()
end

function ValueModifiers:SetFinalAdd(modifierName, value)
	local existingEntry = self.FinalAdds[modifierName]

	if not existingEntry then
		self.FinalAdds[modifierName] = self:CreateModifierEntry(modifierName, value, "FinalAdd")
		self.AllModifiers[modifierName] = self.FinalAdds[modifierName]
	else
		existingEntry:SetValue(value)
	end

	self:ComputeFinalAddFactor()
end

function ValueModifiers:Calculate(baseValue)
	if not baseValue then
		baseValue = self.Base
	end
	
	baseValue += self.AddFactor
	baseValue += (self.BaseScaleFactor * baseValue)
	baseValue *= self.ScaleFactor
	baseValue += self.FinalAddFactor
	baseValue = math.min(baseValue, self.Clamp)
	
	return baseValue
end

function ValueModifiers:Destroy()
	for modifierName, entry in self.AllModifiers do
		entry:Destroy()
	end
	
	if self.BaseChangedConnection then
		self.BaseChangedConnection:Disconnect()
	end
	
	self.Changed:Destroy()
	self.InternalChanged:Destroy()
	
	setmetatable(self, nil)
	table.clear(self)
	table.freeze(self)
end

return ValueModifiers
