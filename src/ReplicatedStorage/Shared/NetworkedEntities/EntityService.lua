local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)

local Deque = Framework.GetShared("Deque")

local IsClient = RunService:IsClient()
local IsServer = RunService:IsServer()

local SNAPSHOT_HISTORY_MAXIMUM_TIME = 1

--[[
	An entity is a networked thing. That's how I'm defining it.
	
	NPCs (and later on, players), projectiles, items, all of that, need to be synchronized across all clients.
	
	Owners of projectiles and items receive data tables that include more information to facilitate accurate and seamless prediction,
	while the other players get small state tables they can use to predict animations or visual effects
	
	NPCs and projectiles will place fat loads on the network because they need constant position, velocity and view angle (not necessary for projectiles) updates
	
	NPCs especially, because they can do a more than simply move around
	
	** EntityHandle uniquely identifies an object knowing its broader class; only the server requires it
	** NetworkHandle is unique across all networked objects regardless of class
	
	The client will set an entity's EntityHandle to its NetworkHandle (maybe change this?)
	The NetworkHandle can be accessed through the data table's name
]] 

local EntityService = {
	List = {}, -- On the client, this is the list of locally simulated / predicted entities; on the server, this is every entity
	
	HistoryBuffer = Deque.new(), -- The history buffer only stores the raw data of each entity's data table, not complete copies of each entity
}

if IsClient then
	EntityService.ServerList = {}
	EntityService.ServerHistoryBuffer = Deque.new()
	
	EntityService.NewEntities = {}
end

local globalHandleId = 0
local freeIds = {}

--[[
	Called before data table creation on the server
]]
function EntityService.Register(entity)
	if freeIds[1] then
		entity.NetworkHandle = freeIds[1]
		table.remove(freeIds, 1)
	else
		entity.NetworkHandle = globalHandleId
		globalHandleId += 1
	end
	
	EntityService.List[entity.NetworkHandle] = entity
	
	return entity.NetworkHandle
end

function EntityService.GetDataTables()
	local dataTablesList = {}
	for handle, entity in EntityService.List do
		local entityDataTable = entity.DataTable
		
		if not entityDataTable then
			dataTablesList[handle] = entity -- Only the data table
			return
		end
		
		if not entityDataTable:HasValidPlayerTargets() then
			return
		end
		
		dataTablesList[handle] = entityDataTable
	end
	
	return dataTablesList
end

function EntityService.CopyDataTableStates(target)
	local dataTablesList = {}
	for handle, entity in target or EntityService.List do
		local entityDataTable = entity.DataTable
		
		if not entityDataTable then
			continue
		end
		
		if not next(entityDataTable) then
			continue
		end

		if entityDataTable then
			dataTablesList[handle] = entityDataTable:CopyDataFlattened()
		else
			dataTablesList[handle] = entity:CopyDataFlattened() -- Only the data table
		end

	end
	
	return dataTablesList
end

function EntityService.ClearOldSnapshots(target)
	local snapshotHistoryBuffer = target or EntityService.HistoryBuffer
	local currentTime = time()

	while true do
		-- Weird naming: the first one in the deque is the oldest
		local oldestSnapshot = snapshotHistoryBuffer:GetFirst()
		
		if oldestSnapshot and currentTime - oldestSnapshot.CreationTime > SNAPSHOT_HISTORY_MAXIMUM_TIME then
			snapshotHistoryBuffer:RemoveFirst()
		else
			break
		end
	end
end

function EntityService.SaveSnapshot(snapshot, currentTick, target)
	target = target or EntityService.HistoryBuffer
	target:AddLast({
		CreationTime = time(),
		Tick = currentTick,
		States = snapshot,
	})
end

function EntityService.GetSnapshotAtTick(targetTick, targetDeque)
	for i, snapshot in targetDeque or EntityService.HistoryBuffer.Array do
		if snapshot.Tick == targetTick then
			return snapshot
		end
	end	
end

function EntityService.GetLatestSnapshot(targetDeque)
	targetDeque = targetDeque or EntityService.HistoryBuffer
	
	return targetDeque:GetLast()
end

function EntityService.GetOldestSnapshot(targetDeque)
	targetDeque = targetDeque or EntityService.HistoryBuffer

	return targetDeque:GetFirst()
end

-- Assuming it's already destroyed
function EntityService.Remove(handle)
	-- Don't add anything to the table if we're the client
	-- The client doesn't use the free IDs table, so it'll only leak memory
	if IsServer then
		table.insert(freeIds, handle)
	end

	EntityService.List[handle] = nil
end

function EntityService.Destroy(entity)
	EntityService.Remove(entity.NetworkHandle)
end

function EntityService.ThinkStep()
	for handle, entity in EntityService.List do
		if entity.Think then
			entity:Think()
		end
	end
end

function EntityService.PhysicsStep(deltaTime)
	for handle, entity in EntityService.List do
		if entity.PhysicsStep then
			entity:PhysicsStep(deltaTime)
		end
	end
end

return EntityService
