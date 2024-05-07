local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local TableUtilities = Framework.GetShared("TableUtilities")
local Signal = Framework.GetShared("Signal")
local SignalTable = Framework.GetShared("SignalTable")

local DataTable = {}
DataTable.__index = DataTable

function DataTable.new(data)
	local self = {
		Data = data or {},
		Changed = Signal.new(),
		ListenerSignals = SignalTable.new()
	}
	setmetatable(self, DataTable)
	
	return self
end

function DataTable:GetValueChangedSignal(pathArray, signalParams)
	return self.ListenerSignals:AddListenerSignal(pathArray, "ValueChanged", signalParams)
end

function DataTable:Get(path)
	local parentTable, key = TableUtilities.TraverseWithPath(self.Data, path)
	return parentTable[key]
end

--[[
function DataTable:GetValueChangedSignal(pathArray, signalParams)
	return self.ListenerSignals:AddListenerSignal(pathArray, "ValueChanged", signalParams)
end
]]

function DataTable:GetData()
	return self.Data
end

function DataTable:InternalSet(params)
	local parentTable = params.Table
	local key = params.Key

	local oldValue = parentTable[key]
	parentTable[key] = params.Value

	params.Key = key
	params.Table = parentTable

	local signalArgs = {
		PathArray = TableUtilities.StringPathToArray(params.Path),
	}

	signalArgs.ListenerType = "ValueChanged"
	signalArgs.Args = {params.Value, oldValue}
	
	self.ListenerSignals:FireListenerSignals(signalArgs)
end

function DataTable:Set(path, value)
	local parentTable, key = TableUtilities.TraverseWithPath(self.Data, path)

	local setArgs = {
		Path = path,
		Value = value,
		Key = key,
		Table = parentTable,
	}

	local oldValue

	-- We are setting multiple keys under the table to different values
	if type(value) == "table" then
		for key, newValue in value do
			setArgs.Key = key
			setArgs.Value = newValue

			self:InternalSet(setArgs)
		end
	else
		self:InternalSet(setArgs)
	end
	
	self.Changed:Fire(path, value)
end
DataTable.Predict = DataTable.Set

function DataTable:Destroy()
	self.Changed:Destroy()
	
	setmetatable(self, nil)
	table.clear(self)
	table.freeze(self)
end

return DataTable
