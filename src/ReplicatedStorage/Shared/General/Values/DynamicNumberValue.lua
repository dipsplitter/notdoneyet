local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local ValueRetriever = Framework.GetShared("ValueRetriever")
local ValueModifiers = Framework.GetShared("ValueModifiers")

local DynamicNumberValue = {}
DynamicNumberValue.ClassName = "DynamicNumberValue"
DynamicNumberValue.__index = DynamicNumberValue
setmetatable(DynamicNumberValue, BaseClass)

function DynamicNumberValue.new(baseValue, modifiers)
	local self = BaseClass.new()
	setmetatable(self, DynamicNumberValue)
	
	-- Multiplied on to the value (multiplier changes to 2 when value is 1 -> value is set to 2)
	self.BaseValue = baseValue
	self.Modifiers = ValueModifiers.new(self.BaseValue)
	self.Value = self.BaseValue
	
	self:AddSignals("BaseChanged", "ValueChanged")
	self:AddConnections({
		UpdateCurrentValueFromBase = self:GetSignal("BaseChanged"):Connect(function()
			local oldValue = self.Value
			self.Value = self.Modifiers:Calculate(self.BaseValue)
			self:FireSignal("ValueChanged", self.Value, oldValue)
		end),
		
		ModifiersChanged = self.Modifiers.Changed:Connect(function()
			local oldValue = self.Value
			self.Value = self.Modifiers:Calculate(self.BaseValue)
			self:FireSignal("ValueChanged", self.Value, oldValue)
		end),
	})

	self:AddModifiers(modifiers)

	return self
end

function DynamicNumberValue:AddModifiers(modifiersTable)
	if not modifiersTable then
		return
	end
	
	for name, info in modifiersTable do
		self.Modifiers:SetScale(name, info)
	end
end

function DynamicNumberValue:SetBaseValue(newValue)
	self.BaseValue = newValue
	self:FireSignal("BaseChanged", newValue)
end

function DynamicNumberValue:AddBaseValueSetter(modifier)
	if not modifier then
		return
	end
	
	if type(modifier) == "table" and not getmetatable(modifier) then
		local keyName, value = next(modifier)
		modifier = value
	end
	self.BaseValueModifier = modifier

	if (type(modifier) == "table" and (modifier:IsClass("Value") or modifier:IsClass("TableListener"))) then

		self:AddConnections({
			BaseValueChanged = modifier:GetSignal("Changed"):Connect(function()
				self:SetBaseValue(ValueRetriever.GetValue(modifier))
			end)
		})

	elseif (typeof(modifier) == "Instance") and modifier:IsA("ValueBase") then

		self:AddConnections({
			BaseValueChanged = modifier.Changed:Connect(function()
				self:SetBaseValue(ValueRetriever.GetValue(modifier))
			end)
		})

	end

	self:SetBaseValue(ValueRetriever.GetValue(modifier))
end

function DynamicNumberValue:Destroy()
	self.Value = nil
	self.Modifiers:Destroy()
	
	if self.BaseValueModifier then
		self.BaseValueModifier = nil
	end
	
	self:BaseDestroy()
end

return DynamicNumberValue
