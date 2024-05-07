local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local ServerIds = Framework.GetShared("DT_ServerIds")
local BufferUtilities = Framework.GetShared("BufferUtilities")
local BufferChannel = Framework.GetShared("BufferChannel")
local WriteBitstream = Framework.GetShared("WriteBitstream")

local Constants = Framework.GetShared("DT_Constants")
local SendQueue = Framework.GetShared("DT_SendQueue")
local RetrieveSnapshot = Framework.GetShared("DT_RetrieveSnapshot")

local Network = Framework.Network()
local DataTableEvent = Network.Event("DataTable")

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
 
local outboundQueues = {}

for i, eventName in Constants.Events do
	outboundQueues[eventName] = SendQueue.new()
end

-- Format per player: [1B : number of DTs changed] [1B : DT ID] [2B? : length of bitstream, in bytes (only present if client hasn't sent ACK)] [nB : bitstream] ...
local DT_Send = {}

RunService.Stepped:Connect(function()
	for globalId, dataTable in ServerIds.DataTables do
		if not dataTable.ShouldNetwork or Constants.IgnoreMainSendProcess[dataTable.Event] then
			continue
		end
		
		local players = dataTable.PlayerContainer:Players()
		
		for i, player in players do
			local snapshot = RetrieveSnapshot.Snapshot(dataTable, player)
			if not snapshot then
				continue
			end
			
			outboundQueues[dataTable.Event]:Add(snapshot, player)
		end
	end
	
	for eventName, queue in outboundQueues do
		if Constants.IgnoreMainSendProcess[eventName] then
			continue
		end
		
		for player, playerQueue in queue.PlayerQueues do
			local stream = queue:Flush(player)
			if not stream then
				continue
			end

			Network.Event(eventName):Fire(stream, player)
		end
		
	end
end)

return DT_Send