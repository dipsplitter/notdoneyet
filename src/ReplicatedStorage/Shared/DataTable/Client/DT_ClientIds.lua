local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Constants = Framework.GetShared("DT_Constants")
--local CreateEventMessages = Framework.GetShared("DT_CreateEventMessages")
local Signal = Framework.GetShared("Signal")

local dataTables = {}
local eventReceiveQueues = {}

for i, eventName in Constants.Events do
	eventReceiveQueues[eventName] = {
		WaitingForSendTableCreation = {},
		ServerInitialData = {},
		InitialDataAdded = Signal.new(),
	}
end

local reservedIds = {}
local reservedStructureNames = {}

local DT_ClientIds = {
	DataTables = dataTables,
	ReceiveQueues = eventReceiveQueues,
	Reserved = Signal.new(),
}

function DT_ClientIds.AddInitialData(dataTableId, data, eventName)
	local existingEntry = eventReceiveQueues[eventName].ServerInitialData[dataTableId]
	
	if existingEntry then
		table.insert(existingEntry, data)
	else
		eventReceiveQueues[eventName].ServerInitialData[dataTableId] = {data}
	end
	
	-- Send structure id through the event as well
	eventReceiveQueues[eventName].InitialDataAdded:Fire(dataTableId, data, reservedStructureNames[dataTableId])
end

function DT_ClientIds.Register(dataTable)
	local name = dataTable.Name
	local associatedQueue = eventReceiveQueues[dataTable.Event]
	local serverReservedId = reservedIds[name]
	
	-- The server reserved this one already, so remove it from queues
	if serverReservedId then
		DT_ClientIds.RemoveFromReservedQueue(name)
		-- Stupid recursive requires
		Framework.GetShared("DT_CreateEventMessages").ClientAcknowledgement(serverReservedId)
	else
		-- We have a copy of the data already, so we don't need to wait for the server
		if dataTable.InitialDataReceived then
			return
		end
		
		-- Server hasn't created send table, so add to waiting queue
		-- A timeout would be nice...
		associatedQueue.WaitingForSendTableCreation[name] = dataTable
		return
	end

	local initialBuffers = associatedQueue.ServerInitialData[serverReservedId]
	if initialBuffers then
		for i, receivedBuffer in initialBuffers do
			dataTable:ReceiveInitialData(receivedBuffer)
		end
		
		associatedQueue.ServerInitialData[serverReservedId] = nil
	end
	
	associatedQueue.WaitingForSendTableCreation[name] = nil
	dataTables[serverReservedId] = dataTable
	
	return serverReservedId
end

function DT_ClientIds.Reference(id)
	if type(id) == "table" then
		
		for i, dt in dataTables do
			if dt == id then
				return dt
			end
		end
		
	end
	
	return dataTables[id]
end

function DT_ClientIds.Remove(dataTable)
	local id = dataTable
	
	if type(id) == "table" then
		id = dataTable.Id
	end
	
	if not id then
		return
	end
	
	if not dataTables[id] then
		return
	end
	
	dataTables[id] = nil
end

function DT_ClientIds.Destroy(id)
	DT_ClientIds.RemoveFromInitialDataQueue(id)
	
	if dataTables[id] then
		dataTables[id]:Destroy()
		dataTables[id] = nil
	end
end

function DT_ClientIds.Reserve(id, name, structureName)
	reservedIds[name] = id
	reservedStructureNames[id] = structureName
end

function DT_ClientIds.GetNameForReservedId(reservedId)
	for name, id in reservedIds do
		if id == reservedId then
			return name
		end
	end
end

function DT_ClientIds.GetStructureNameForReservedId(reservedId)
	return reservedStructureNames[reservedId]
end

function DT_ClientIds.RemoveFromReservedQueue(name)
	local dataTableId = reservedIds[name]
	reservedIds[name] = nil
	reservedStructureNames[dataTableId] = nil
end

function DT_ClientIds.RemoveFromWaitingQueue(name)
	for eventName, queue in eventReceiveQueues do
		local waitingDataTable = queue.WaitingForSendTableCreation[name]
		
		if waitingDataTable then
			DT_ClientIds.Register(waitingDataTable)
			break
		end
	end
end

function DT_ClientIds.RemoveFromInitialDataQueue(id)
	for eventName, queue in eventReceiveQueues do
		local initialDataQueue = queue.ServerInitialData[id]

		if initialDataQueue then
			queue.ServerInitialData[id] = nil
			break
		end
	end
end

function DT_ClientIds.IsHandleRegistered(id)
	return dataTables[id] ~= nil
end

return DT_ClientIds
