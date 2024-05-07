local DataTableMiddleware = require(script.Parent.Middleware_DataTable)

--[[
	Similar to data table middleware... except:
	
	Removed entities are sent in an array
	We also need to read/write the snapshot tick
]]
local function MainInbound(stream, cursor)
	local bufferCursor = cursor
	
	local isFull = buffer.readu8(stream, bufferCursor) == 1
	bufferCursor += 1
	
	local comparisonTick = nil
	if not isFull then
		comparisonTick = buffer.readu32(stream, bufferCursor)
		bufferCursor += 4
	end
	
	local snapshotTick = buffer.readu32(stream, bufferCursor)
	bufferCursor += 4
	
	local commandId = buffer.readu32(stream, bufferCursor)
	bufferCursor += 4
	
	local removedEntityCount = buffer.readu16(stream, bufferCursor)
	bufferCursor += 2
	
	local removedEntities = {}
	
	for i = 1, removedEntityCount do
		local entityHandle = buffer.readu16(stream, bufferCursor)
		bufferCursor += 2
		
		removedEntities[entityHandle] = true
	end
	
	return {
		AdvanceCursor = bufferCursor - cursor,
		Status = true,
		Data = {
			IsFullSnapshot = isFull,
			ComparisonTick = comparisonTick,
			LatestAppliedCommandId = commandId,
			Tick = snapshotTick,
			RemovedEntities = removedEntities,
		},
	}
end

-- Moves the data table middleware results into a subtable within the main table
local function FinalizeInbound(stream, cursor, accumulatedData)
	local snapshot = {}
	
	for key, value in accumulatedData do
		if type(key) == "string" then
			continue
		end
		snapshot[key] = value
	end
	
	accumulatedData.Snapshot = snapshot
	
	return {
		Status = true,
	}
end

-- Writes all removed entities
local function MainOutbound(data, queue)
	local isFull = data.IsFullSnapshot
	queue:writeu8(if isFull then 1 else 0)
	
	-- Comparison tick
	if not isFull then
		local comparisonTick = data.ComparisonTick 
		queue:writeu32(comparisonTick)
	end
	
	local snapshotTick = data.Tick 
	queue:writeu32(snapshotTick)
	
	local commandId = data.LatestAppliedCommandId
	queue:writeu32(commandId)
	
	local removedEntities = data.RemovedEntities
	local count = #removedEntities
	
	queue:writeu16(count)
	
	for i, handle in removedEntities do
		queue:writeu16(handle)
	end
	
	queue:AddBuffer(data.Snapshot)
	
	return {
		Status = true,
	}
end

return {
	Inbound = {
		MainInbound,
		table.unpack(DataTableMiddleware.Inbound),
		FinalizeInbound,
	},
	
	Outbound = {
		MainOutbound,
	},
}