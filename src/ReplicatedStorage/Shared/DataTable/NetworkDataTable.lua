local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local DeltaCompressor = Framework.GetShared("DeltaCompressor")
local TableUtilities = Framework.GetShared("TableUtilities")
local Signal = Framework.GetShared("Signal")
local SignalTable = Framework.GetShared("SignalTable")
local StructureRetriever = Framework.GetShared("DT_StructureRetriever")

local function InternalSet(tbl, key, value, path, signalTable)
	local oldValue = tbl[key]

	-- Don't fire changed signals if we're not even changing anything !
	if oldValue == value then
		return
	end

	tbl[key] = value
	
	local signalArgs = {
		PathArray = path,
		Type = "Changed",
		Args = {value, oldValue}
	}

	signalTable:Fire(signalArgs)
end

local NetworkDataTableShared = {}

function NetworkDataTableShared.Create(dataTable, dataTableParams)
	dataTable.Data = dataTableParams.Data or {}
	
	local structureName = dataTableParams.Structure
	local structureTable = StructureRetriever.ToStructureTable(structureName)
	
	dataTable.StructureName = structureName
	dataTable.Structure = structureTable
	dataTable.StructureId = StructureRetriever.ToEnum(structureName)
	
	dataTable.Packer = DeltaCompressor.new(dataTable.Structure, dataTable.Data)
	dataTable.Name = dataTableParams.Name
	
	-- Which network event to transmit the DT over. By default, this is "DataTable"
	dataTable.Event = dataTableParams.Event or "DataTable"
	
	dataTable.IsCollating = false
	dataTable.Changed = Signal.new()
	dataTable.SignalTable = SignalTable.new()
end

function NetworkDataTableShared.ChangedSignal(dataTable, pathArray, tags)
	if tags then
		tags.Type = "Changed"
	end
	
	return dataTable.SignalTable:Add(pathArray, tags)
end

function NetworkDataTableShared.Get(dataTable, path)
	local parentTable, key = TableUtilities.TraverseWithPath(dataTable.Data, path)
	return parentTable[key]
end

function NetworkDataTableShared.Set(dataTable, path, value)
	path = TableUtilities.StringPathToArray(path)
	local parentTable, key = TableUtilities.TraverseWithPath(dataTable.Data, path)

	-- We're setting values for multiple keys under this path
	if type(value) == "table" then

		for keyName, newValue in value do
			InternalSet(parentTable, keyName, newValue, path, dataTable.SignalTable)
		end

	else
		InternalSet(parentTable, key, value, path, dataTable.SignalTable)
	end
	
	dataTable.Changed:Fire(path, value)
end

function NetworkDataTableShared.CopyData(dataTable)
	return TableUtilities.DeepCopy(dataTable.Data)
end

function NetworkDataTableShared.Copy(dataTable, parentClass)
	local deepCopy = TableUtilities.DeepCopy(dataTable)
	setmetatable(deepCopy, parentClass)
	
	return deepCopy
end

function NetworkDataTableShared.CopyDataFlattened(dataTable)
	return TableUtilities.DeepCopy(dataTable.Packer.Current)
end

return NetworkDataTableShared
