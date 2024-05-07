local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local TableUtilities = Framework.GetShared("TableUtilities")
local ClampedValue = Framework.GetShared("ClampedValue")
local Value = Framework.GetShared("Value")
local Signal = Framework.GetShared("Signal")

local ItemValueManager = {}
ItemValueManager.__index = ItemValueManager
setmetatable(ItemValueManager, BaseClass)

function ItemValueManager.new(defaultValues)
	local self = BaseClass.new()
	setmetatable(self, ItemValueManager)
	
	self.ValueObjects = {}
	
	if defaultValues then
		self.DefaultValues = defaultValues
		self:AddValues(defaultValues)
	end
	
	return self
end

function ItemValueManager:AddValue(name, info)
	if self.ValueObjects[name] then
		self.ValueObjects[name]:Destroy()
	end

	local newValue
	if info.Max or info.Min then
		newValue = ClampedValue.new(info)
	else
		newValue = Value.new(info)
	end

	self.ValueObjects[name] = newValue
end

function ItemValueManager:AddValues(dict)
	for name, info in dict do
		self:AddValue(name, info)
	end
end

function ItemValueManager:Get(valueName, propertyName)
	local valueObject = self.ValueObjects[valueName]
	if not valueObject then
		return
	end

	return valueObject[propertyName or "Value"]
end

function ItemValueManager:Set(valueName, newValue, propertyName)
	local valueObject = self.ValueObjects[valueName]
	if not valueObject then
		return
	end

	propertyName = propertyName or "Value"
	valueObject[propertyName] = newValue
	--self:FireSignal("ValuesChanged")
end

function ItemValueManager:SetValueWithPropertiesTable(valueName, properties)
	local valueObject = self.ValueObjects[valueName]
	if not valueObject then
		return
	end

	if type(properties) == "number" then
		valueObject.Value = properties
	else
		for propertyName, newValue in properties do
			valueObject[propertyName] = newValue
		end
	end
end

function ItemValueManager:GetChangedSignal(valueName)
	local valueObject = self.ValueObjects[valueName]
	if not valueObject then
		return
	end

	return valueObject:GetSignal("Changed")
end

function ItemValueManager:Destroy()
	for name, object in self.ValueObjects do
		object:Destroy()
	end
	table.clear(self.ValueObjects)

	BaseClass.Destroy(self)
end


return ItemValueManager
