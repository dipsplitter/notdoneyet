local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)

local Globals = Framework.GetShared("Globals")
local EntityService = Framework.GetShared("EntityService")
local RetrieveSnapshot = Framework.GetShared("DT_RetrieveSnapshot")
local SendQueue = Framework.GetShared("DT_SendQueue")

local PlayerNetworkRecord = Framework.GetServer("PlayerNetworkRecord")

local NETWORK = Framework.Network()
local EntitySnapshotEvent = NETWORK.Event("EntitySnapshot")
local CommandEvent = NETWORK.Event("Command")

local dataTableSendQueue = SendQueue.new()

local ServerEntitySimulation = {
	NextTickTime = 0,
	Tick = 1,
	
	PlayerRecords = {}
}

Players.PlayerAdded:Connect(function(player)
	ServerEntitySimulation.PlayerRecords[player] = PlayerNetworkRecord.new(player)
end)

Players.PlayerRemoving:Connect(function(player)
	ServerEntitySimulation.PlayerRecords[player] = nil
end)

CommandEvent:Connect(function(data, player)
	local playerRecord = ServerEntitySimulation.PlayerRecords[player]
	
	for i, command in data.Commands do
		table.insert(playerRecord.CommandBuffer, command)
	end
end)

RunService.Stepped:Connect(function(currentTime, deltaTime)
	
	local t = time()
	if t < ServerEntitySimulation.NextTickTime then
		return
	end
	
	-- Schedule next tick
	local ticksAhead = math.floor((t - ServerEntitySimulation.NextTickTime) / Globals.TickRate) + 1
	ServerEntitySimulation.NextTickTime += ticksAhead * Globals.TickRate
	ServerEntitySimulation.Tick += ticksAhead
	
	-- Handle commands
	for player, playerRecord in ServerEntitySimulation.PlayerRecords do
		local commandBuffer = playerRecord.CommandBuffer
		local commandQueue = playerRecord.CommandQueue
		
		table.clear(commandQueue)
		
		playerRecord:ClearInvalidCommands()
		playerRecord:ProcessCommands(ServerEntitySimulation.Tick)
	end
	
	EntityService.ThinkStep()
	EntityService.PhysicsStep(deltaTime)
	
	-- Save all changes in history buffer
	EntityService.SaveSnapshot(EntityService.CopyDataTableStates(), ServerEntitySimulation.Tick)
	
	-- Clear snapshots in history buffer that are too old
	EntityService.ClearOldSnapshots()
	
	-- Send snapshots to players
	for player, playerRecord in ServerEntitySimulation.PlayerRecords do
		-- Bots / fake clients 
		if not playerRecord.IsNetworked then
			continue
		end
		
		-- Rate limited
		if not playerRecord:Update() then
			continue
		end
		
		-- Find the most recent acknowledged snapshot for this client
		local mostRecentlyAcknowledgedSnapshot
		local mostRecentTick = playerRecord.LastAcknowledgedUpdateTick
		
		if mostRecentTick > 0 then
			mostRecentlyAcknowledgedSnapshot = EntityService.GetSnapshotAtTick(mostRecentTick)
		end
		
		local removedEntities = {}
		local isFullSnapshot = false
		
		-- Client has either just joined or is lagging really badly
		-- Their last received snapshot has already been deleted from the history buffer
		if not mostRecentlyAcknowledgedSnapshot then
			isFullSnapshot = true
			playerRecord:FullSnapshot(dataTableSendQueue)
		else
			removedEntities = playerRecord:DeltaSnapshot(dataTableSendQueue, mostRecentlyAcknowledgedSnapshot)
		end
		
		-- Send
		local stream = dataTableSendQueue:Flush(player)
		if not stream then
			continue
		end

		EntitySnapshotEvent:Fire({
			Tick = ServerEntitySimulation.Tick,
			ComparisonTick = if not isFullSnapshot then mostRecentTick else nil,
			IsFullSnapshot = isFullSnapshot,
			
			LatestAppliedCommandId = playerRecord.LatestAppliedCommandId,
			
			Snapshot = stream, 
			RemovedEntities = removedEntities
		}, player)
	end
	
end)

return ServerEntitySimulation
