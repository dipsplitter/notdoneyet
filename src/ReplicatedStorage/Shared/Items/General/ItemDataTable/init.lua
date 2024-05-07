local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local TableUtilities = Framework.GetShared("TableUtilities")
local ClampedValue = Framework.GetShared("ClampedValue")
local Value = Framework.GetShared("Value")
local Signal = Framework.GetShared("Signal")
local ItemValueManager = Framework.GetShared("ItemValueManager")

local Network = Framework.Network()
local DataTableService = Framework.GetShared("DataTableService")
local DTSItemsCache = DataTableService.StructureCache("Item")
local DECLARE = Framework.GetShared("DT_NetworkedProperties").DeclareProperty

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local IsClient = RunService:IsClient()
local IsServer = RunService:IsServer()

--[[
	Combines properties, states, and values tables into one class
	
	States are boolean properties; they are handled identically
	
	Values are handled differently as we need to update a set of local value objects
]]

local function InitializeProperties(item, defaultProperties)
	local propertiesTable = TableUtilities.DeepCopy(defaultProperties)

	return propertiesTable
end

local function InitializeStates(item)
	local initialData = {Active = false}

	local default = item.Schema
	local itemData = item.SchemaEntry

	-- Manually add equip and unequip; we shouldn't rely on action managers
	if itemData.ItemType == "Tool" then
		initialData.Equip = false
		initialData.Unequip = true
	end

	local customStates = default.States
	if customStates then
		for stateName, customType in customStates do
			initialData[stateName] = false
		end
	end

	for actionName in default.Base.Activations do
		initialData[actionName] = false
	end
	
	return initialData
end

local function InitializeValues(item)
	local defaultValues = item.Schema.Base.Values
	
	if not defaultValues then
		return
	end
	
	defaultValues = TableUtilities.DeepCopy(defaultValues)
	
	for valueName, valueInfo in defaultValues do
		
		valueInfo.Value = valueInfo.Value or valueInfo.Max
		valueInfo.Min = valueInfo.Min or 0
	end
	
	return defaultValues
end

local ItemDataTable = {}
ItemDataTable.__index = ItemDataTable
setmetatable(ItemDataTable, BaseClass)

function ItemDataTable.new(item, customProperties)
	local self = BaseClass.new()
	setmetatable(self, ItemDataTable)
	
	self:InjectObject("Item", item)
	self:AddSignals("ValuesChanged")
	
	-- Read only reference of properties
	self.DefaultProperties = customProperties or self.Item.Schema.Base

	local propertiesTable = InitializeProperties(item, self.DefaultProperties)
	local statesTable = InitializeStates(item)
	local valuesTable = InitializeValues(item)
	
	if valuesTable then
		self.ValueManager = ItemValueManager.new(valuesTable)
	end
	
	local overallData = {
		Properties = propertiesTable,
		States = statesTable,
		Values = valuesTable,
	}
	
	local params = {
		Name = `I{self.Item.EntityHandle}`,
		Data = overallData,
		Structure = `Item.{self.Item.Id}`,
		InitialDataReceived = true,
	}
	if IsServer and self.Item:IsCurrentOwnerPlayer() then
		params.PlayerContainer = Network.Single(self.Item.Player)
	end
	
	self.DataTable = DataTableService.Reference(params)

	if IsServer then
		self:AddConnections({
			ChangeOwnership = self.DataTable:SetOwnershipChangedSignal(self.Item:GetSignal("CharacterChanged"))
		})
	end

	self.Data = self.DataTable.Data
	
	return self
end

function ItemDataTable:GetChangedSignal(pathArray, signalParams)
	return self.DataTable:ChangedSignal(pathArray, signalParams)
end

function ItemDataTable:GetPropertyChangedSignal(pathArray, signalParams)
	table.insert(pathArray, 1, "Properties")
	return self.DataTable:ChangedSignal(pathArray, signalParams)
end

function ItemDataTable:GetStateChangedSignal(pathArray, signalParams)
	table.insert(pathArray, 1, "States")
	return self.DataTable:ChangedSignal(pathArray, signalParams)
end

function ItemDataTable:GetBaseProperty(path)
	return TableUtilities.GetValueFromPath(self.DefaultProperties, path)
end

function ItemDataTable:Get(keyArray)
	return self.DataTable:Get(keyArray)
end

function ItemDataTable:Set(keyArray, value)
	self.DataTable:Set(keyArray, value)
end

function ItemDataTable:Predict(keyArray, value)
	self.DataTable:Predict(keyArray, value)
end

function ItemDataTable:GetProperty(keyArray)
	if type(keyArray) ~= "table" then
		keyArray = {keyArray}
	end
	table.insert(keyArray, 1, "Properties")
	return self.DataTable:Get(keyArray)
end

function ItemDataTable:SetProperty(keyArray, value)
	if type(keyArray) ~= "table" then
		keyArray = {keyArray}
	end
	table.insert(keyArray, 1, "Properties")
	self.DataTable:Set(keyArray, value)
end

function ItemDataTable:PredictProperty(keyArray, value)
	if type(keyArray) ~= "table" then
		keyArray = {keyArray}
	end
	table.insert(keyArray, 1, "Properties")
	self.DataTable:Predict(keyArray, value)
end

function ItemDataTable:GetState(stateName)
	local keyArray = {"States", stateName}
	return self.DataTable:Get(keyArray)
end

function ItemDataTable:SetState(stateName, value)
	local keyArray = {"States", stateName}
	self.DataTable:Set(keyArray, value)
end

function ItemDataTable:PredictState(stateName, value)
	local keyArray = {"States", stateName}
	self.DataTable:Predict(keyArray, value)
end

--[[
	ITEM VALUE MANAGER WRAPPER METHODS
]]
function ItemDataTable:GetValueChangedSignal(valueName)
	return self.ValueManager:GetChangedSignal(valueName)
end

function ItemDataTable:GetValue(valueName, propertyName)
	return self.ValueManager:Get(valueName, propertyName)
end

function ItemDataTable:SetValue(valueName, newValue, propertyName)
	propertyName = propertyName or "Value"
	self.ValueManager:Set(valueName, newValue, propertyName)

	self.DataTable:Set({"Values", valueName, propertyName}, newValue)
end

function ItemDataTable:BatchSetValues(dict, order)
	if order then
		for i, valueName in order do
			self.ValueManager:SetValueWithPropertiesTable(valueName, dict[valueName])
		end
	else
		for valueName, props in dict do
			self.ValueManager:SetValueWithPropertiesTable(valueName, props)
		end
	end

	self:FireSignal("ValuesChanged")

	self.DataTable:Collate(function()
		for valueName, props in dict do
			-- Single value
			if type(props) == "number" then
				self.DataTable:Set({"Values", valueName, "Value"}, props)
			else -- Table
				self.DataTable:Set({"Values", valueName}, props)
			end
		end
	end)
end

function ItemDataTable:Destroy()
	if IsServer then
		self.DataTable:Destroy()
	end

	BaseClass.Destroy(self)
end

return ItemDataTable
