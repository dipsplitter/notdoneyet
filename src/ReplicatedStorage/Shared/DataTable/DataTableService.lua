local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)

local RunService = game:GetService("RunService")
local IsClient = RunService:IsClient()
local IsServer = RunService:IsServer()

local NetworkedProperties = Framework.GetShared("DT_NetworkedProperties")

local DataTableClass = if IsServer then Framework.GetShared("SendTable") else Framework.GetShared("ReceiveTable")
local Process = if IsServer then Framework.GetShared("DT_Send") else Framework.GetShared("DT_Receive")
local Identifiers = if IsServer then Framework.GetShared("DT_ServerIds") else Framework.GetShared("DT_ClientIds")
local CreateHandler = Framework.GetShared("DT_CreateEventHandler")

local StructuresFolder = script.Parent.Structures

local DataTableService = {
	PropertyFlags = NetworkedProperties.Flags
}

-- Data tables indexed by string identifier here
local dataTableStorage = {}

-- Initialize DTS
local structureCache = {}

for i, structureCacheModule in StructuresFolder:GetDescendants() do
	if not structureCacheModule:IsA("ModuleScript") then
		continue
	end
	
	local returned = require(structureCacheModule)
	structureCache[returned.Name] = returned.Cache
end

-- Initialize DTS enums
local StructureRetriever = Framework.GetShared("DT_StructureRetriever")

local function CreateDataTable(params)
	local name = params.Name
	local newDataTable = DataTableClass.new(params)
	
	if params.InitialDataReceived and IsServer then
		newDataTable:DisableInitialFullSnapshotSendForPlayers()
	end
	
	dataTableStorage[name] = newDataTable

	return newDataTable
end

function DataTableService.Reference(params)
	local name = params
	if type(params) == "table" then
		name = params.Name
	end
	
	local dataTable
	
	if type(params) == "string" then
		dataTable = dataTableStorage[name]
	elseif type(params) == "number" then
		dataTable = Identifiers.DataTables[params]
	end
	
	if dataTable then
		return dataTable
	else
		return CreateDataTable(params)
	end	
end

function DataTableService.StructureCache(cacheName)
	return structureCache[cacheName]
end

function DataTableService.Structure(structureId)
	local cacheName, structureName = string.split(structureId, ".")
	return structureCache[cacheName][structureName]
end

function DataTableService.Destroy(name)
	local dataTable = dataTableStorage[name]
	if dataTable then
		dataTable:Destroy()
		dataTableStorage[name] = nil
	end
end

function DataTableService.DeclareProperty(...)
	return NetworkedProperties.DeclareProperty(...)
end

return DataTableService
