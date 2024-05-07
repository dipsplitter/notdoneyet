local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local ValueRetriever = Framework.GetShared("ValueRetriever")

local ModifierEntry = {}
ModifierEntry.__index = ModifierEntry

function ModifierEntry.new(name, value, modifierType)
	local self = {
		Name = name,
		Value = value,
		Type = modifierType,
		CurrentValue = ValueRetriever.GetValue(value),
		Active = true,
		
		ChangedConnection = nil,
		ChangedSignal = nil,
	}
	setmetatable(self, ModifierEntry)
	
	-- Automatically update CurrentValue by listening to state changes, if applicable
	if (type(value) == "table" and (value:IsClass("Value") or value:IsClass("TableListener"))) then
		
		self.ChangedConnection = value:GetSignal("Changed"):Connect(function()
			self.CurrentValue = value.Value
			
			if self.ChangedSignal then
				self.ChangedSignal:Fire(self.Type, self.Name, self.CurrentValue)
			end
		end)
	
	elseif (typeof(value) == "Instance") and value:IsA("ValueBase") then
		
		self.ChangedConnection = value.Changed:Connect(function()
			self.CurrentValue = value.Value
			
			if self.ChangedSignal then
				self.ChangedSignal:Fire(self.Type, self.Name, self.CurrentValue)
			end
		end)

	end
	
	return self
end

function ModifierEntry:SetChangedSignal(signal)
	self.ChangedSignal = signal
end

function ModifierEntry:GetCurrentValue()
	self.CurrentValue = ValueRetriever.GetValue(self.Value)
	return self.CurrentValue
end

function ModifierEntry:SetValue(newValue)
	self.Value = newValue
	self:GetCurrentValue()
end

function ModifierEntry:Destroy()
	if self.ChangedConnection then
		self.ChangedConnection:Disconnect()
	end
	
	setmetatable(self, nil)
	table.clear(self)
	table.freeze(self)
end

return ModifierEntry
