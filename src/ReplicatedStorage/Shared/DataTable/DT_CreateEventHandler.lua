local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Framework = require(ReplicatedStorage.Framework)
local StructureRetriever = Framework.GetShared("DT_StructureRetriever")
local CreateEventMessages = Framework.GetShared("DT_CreateEventMessages")

local NETWORK = Framework.Network()
local DataTableCreateEvent = NETWORK.Event("DataTableCreate")

local IsClient = RunService:IsClient()
local IsServer = RunService:IsServer()

local Identifiers = if IsServer then Framework.GetShared("DT_ServerIds") else Framework.GetShared("DT_ClientIds")

local DT_CreateEventHandler = {}

if IsClient then
	
	DataTableCreateEvent:Connect(function(data)
		local id = data.Id
		local isCreation = data.Action
		local name = data.Name
		local structureName = StructureRetriever.ToStructureName(data.Structure)

		-- Remove the data table at given ID
		if not isCreation then
			Identifiers.Destroy(id)
			return 
		end

		-- Send an ACK if we created this before the server
		if Identifiers.IsHandleRegistered(id) then
			CreateEventMessages.ClientAcknowledgement(id)
		else -- Mark the ID as reserved so it's occupied the next time we create a data table
			Identifiers.Reserve(id, name, structureName)
		end

		-- Remove from waiting queue
		Identifiers.RemoveFromWaitingQueue(name)
	end)
	
end

if IsServer then
	
	DataTableCreateEvent:Connect(function(data, player)
		Identifiers.MarkReceiveTableCreated(data.Id, player)
	end)

end

return DT_CreateEventHandler
