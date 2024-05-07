local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Framework = require(ReplicatedStorage.Framework)

local NETWORK = Framework.Network()
local DataTableCreateEvent = NETWORK.Event("DataTableCreate")

local IsClient = RunService:IsClient()
local IsServer = RunService:IsServer()

local DT_CreateEventMessages = {}

function DT_CreateEventMessages.ClientAcknowledgement(serverId)
	DataTableCreateEvent:Fire({
		Id = serverId,
		Action = true,
		Name = "",
		Structure = 0,
	})
end

function DT_CreateEventMessages.ServerAssociate(localHandle, dataTable, player)
	DataTableCreateEvent:Fire({
		Id = localHandle, 
		Action = true, 
		Name = dataTable.Name, 
		Structure = dataTable.StructureId
	}, player)
end

function DT_CreateEventMessages.ServerDissociate(localHandle, player)
	DataTableCreateEvent:Fire({
		Id = localHandle,
		Action = false, 
		Name = "", 
		Structure = 0
	}, player)
end

return DT_CreateEventMessages
