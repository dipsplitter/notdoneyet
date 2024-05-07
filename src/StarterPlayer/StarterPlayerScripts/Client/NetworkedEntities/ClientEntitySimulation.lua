local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)

local Globals = Framework.GetShared("Globals")
local EntityService = Framework.GetShared("EntityService")
local ClientDataTables = Framework.GetShared("DT_ClientIds")

local ClientNetworkRecord = Framework.GetClient("ClientNetworkRecord")
local EntityCreator = Framework.GetClient("EntityCreator")
local GenerateClientCommand = Framework.GetClient("GenerateClientCommand")
local BuildServerSnapshot = Framework.GetClient("BuildServerSnapshot")

local NETWORK = Framework.Network()
local EntitySnapshotEvent =  NETWORK.Event("EntitySnapshot")
local CommandEvent = NETWORK.Event("Command")

local ClientEntitySimulation = {
	PreviousTickTime = 0,
	NextTickTime = 0, 
	Tick = 0,
	
	UnsentCommands = {},
	LatestCommand = nil,
	NextCommandSendTime = time(),
}

local function HandleMispredictions()
	if #EntityService.HistoryBuffer:Size() == 0 then
		return 
	end
	
	local lastAppliedCommand = ClientNetworkRecord.ClientSettings:Get("LastAppliedCommandId")
	if lastAppliedCommand <= -1 then
		return
	end
	
	local mispredicted = false
	local stoppingPoint = -1
	
	for i, snapshotToCheck in EntityService.HistoryBuffer.Array do
		if snapshotToCheck.Command.Id ~= lastAppliedCommand then
			continue
		end
		
		stoppingPoint = i
		for handle, entityDataTable in snapshotToCheck.States do
			local correspondingServerEntity = EntityService.ServerList[handle].DataTable
			-- Check if mispredicted
		end
	end
	
	if stoppingPoint >= 0 then
		return
	end
	
	for i = 1, stoppingPoint do
		EntityService.HistoryBuffer:RemoveFirst()
	end
	
	if mispredicted then
		
	end
end

EntitySnapshotEvent:Connect(BuildServerSnapshot)

RunService.Stepped:Connect(function(currentTime, deltaTime)
	
	local t = time()
	if t < ClientEntitySimulation.NextTickTime then
		return
	end
	
	-- Schedule next tick
	ClientEntitySimulation.PreviousTickTime = ClientEntitySimulation.NextTickTime
	local ticksAhead = math.floor((t - ClientEntitySimulation.NextTickTime) / Globals.TickRate) + 1
	ClientEntitySimulation.NextTickTime += ticksAhead * Globals.TickRate
	
	local latestSnapshot = EntityService.ServerHistoryBuffer:GetLast()
	
	if not latestSnapshot then
		return
	end
	
	local newTick = latestSnapshot.Tick + math.floor((time() - latestSnapshot.CreationTime - ClientNetworkRecord.ClientSettings:Get("ViewInterpolationDelay")) / Globals.TickRate) - 1
	
	-- Tick counter is monotonic
	if ClientEntitySimulation.Tick < newTick then
		ClientEntitySimulation.Tick = newTick -- Catch up if we're behind
	elseif ClientEntitySimulation.Tick == newTick then
		ClientEntitySimulation.Tick += 1 -- Properly synced, so keep going
	end
	-- Don't increment if we're ahead somehow
	
	-- Generate command
	ClientEntitySimulation.LatestCommand = GenerateClientCommand(ClientEntitySimulation.Tick, EntityService.ServerHistoryBuffer:GetLast().Tick)
	table.insert(ClientEntitySimulation.UnsentCommands, ClientEntitySimulation.LatestCommand)
	
	-- Remove local entities if they don't exist on the server anymore
	for handle, entityData in EntityService.ServerList do
		-- Register newly created entity
		if not EntityService.List[handle] then
			EntityService.List[handle] = EntityService.NewEntities[handle]
			EntityService.NewEntities[handle] = nil
		end
		
		
	end
	for handle, entity in EntityService.List do
		local serverEntity = EntityService.ServerList[handle]
		  
		if not serverEntity then
			entity:Destroy()
			EntityService.List[handle] = nil
		end
	end
	
	EntityService.ThinkStep()
	EntityService.PhysicsStep(deltaTime)

	-- Save snapshot
	EntityService.SaveSnapshot(EntityService.CopyDataTableStates(), ClientEntitySimulation.Tick)
	
	-- Clear snapshots in history buffers that are too old
	EntityService.ClearOldSnapshots()
	EntityService.ClearOldSnapshots(EntityService.ServerHistoryBuffer)

	-- Send commands
	if t > ClientEntitySimulation.NextCommandSendTime then
		-- If there's more, we've queued up too many commands and need to clear the queue
		if #ClientEntitySimulation.UnsentCommands < 5 then
			CommandEvent:Fire({Commands = ClientEntitySimulation.UnsentCommands})
		end
		
		table.clear(ClientEntitySimulation.UnsentCommands)
		
		ClientEntitySimulation.NextCommandSendTime += 1 / ClientNetworkRecord.ClientSettings:Get("CommandRate")
	end
end)

return ClientEntitySimulation
