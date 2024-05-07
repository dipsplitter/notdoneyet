local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)

local EntityService = Framework.GetShared("EntityService")
local ClientDataTables = Framework.GetShared("DT_ClientIds")

local EntityCreator = Framework.GetClient("EntityCreator")

local function ApplyChanges(dataTable, deserializedValues, snapshotTable, comparisonSnapshot)
	local entityHandle = tonumber(dataTable.Name)
	
	local comparisonData = if comparisonSnapshot then comparisonSnapshot[entityHandle] else nil

	-- Resolve deltas
	dataTable:OnReceive(deserializedValues, comparisonData)

	snapshotTable[entityHandle] = dataTable:CopyDataFlattened()
end

local function CreateEntity(reservedId, dataTableInitialData, snapshotTable)
	local entityHandleString = ClientDataTables.GetNameForReservedId(reservedId)
	if not entityHandleString then
		return
	end

	local entityHandle = tonumber(entityHandleString)
	
	local structureName = ClientDataTables.GetStructureNameForReservedId(reservedId) -- Contains class

	local newEntity = EntityCreator({FullName = structureName, EntityHandle = entityHandle})
	newEntity.DataTable:ReceiveInitialData(dataTableInitialData)

	-- The client will register this entity later down the step
	EntityService.NewEntities[entityHandle] = newEntity 
	
	-- Insert data into snapshot
	snapshotTable[entityHandle] = newEntity.DataTable:CopyDataFlattened()
end

return function(deserializedSnapshot)
	local isFullSnapshot = deserializedSnapshot.IsFullSnapshot
	local comparisonTick = deserializedSnapshot.ComparisonTick
	local serverTick = deserializedSnapshot.Tick
	local removedEntities = deserializedSnapshot.RemovedEntities
	local dataTableChanges = deserializedSnapshot.Snapshot
	
	local serverComparisonSnapshot = nil
	if not isFullSnapshot then
		serverComparisonSnapshot = EntityService.GetSnapshotAtTick(comparisonTick, EntityService.ServerHistoryBuffer.Array)
		if serverComparisonSnapshot then
			serverComparisonSnapshot = serverComparisonSnapshot.States
		end
	end
	
	local finalServerSnapshot = {}

	for dataTable, newData in dataTableChanges do
		
		if type(dataTable) == "table" then -- Existing entity
			ApplyChanges(dataTable, newData, finalServerSnapshot, serverComparisonSnapshot)
		elseif type(dataTable) == "number" then -- New entity
			CreateEntity(dataTable, newData, finalServerSnapshot)
		end
		
	end
	
	if not isFullSnapshot then
		for handle, entityData in serverComparisonSnapshot do
			-- Remove entities
			if removedEntities[handle] then
				finalServerSnapshot[handle] = nil
				continue
			end
			
			-- Copy over unchanged entities
			if not finalServerSnapshot[handle] then
				finalServerSnapshot[handle] = entityData
			end
		end
	end

	
	EntityService.ServerList = finalServerSnapshot
	EntityService.SaveSnapshot(finalServerSnapshot, serverTick, EntityService.ServerHistoryBuffer)
end
