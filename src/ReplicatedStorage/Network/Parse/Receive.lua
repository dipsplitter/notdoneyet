local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local RecycledSpawn = Framework.GetShared("RecycledSpawn")

local NetworkRequire = require(ReplicatedStorage.Network.NetworkRequire)
local EventTracker = NetworkRequire.Require("EventTracker")
local BitBuffer = NetworkRequire.Require("BitBuffer")

return function(receivedBuffer, player)
	local length = buffer.len(receivedBuffer)
	
	--local readBitBuffer = BitBuffer.FromBuffer(receivedBuffer)
	
	local cursor = 0
	while cursor < length do
		local eventId = buffer.readu8(receivedBuffer, cursor)
		cursor += 1
		
		local event = EventTracker.FromId(eventId)
		
		local receivedEventData = {}
		
		if not event then
			warn(`Invalid Network Event ID (kill me please): {eventId}`)
		end

		if not event:UsesMiddleware() then
			-- Read from buffer
			for i, keyDataTypePair in event.ArgumentOrder do
				local key = keyDataTypePair[1]
				local dataTypeFunctions = keyDataTypePair[2]

				local readLength
				receivedEventData[key], readLength = dataTypeFunctions.Read(receivedBuffer, cursor)
				cursor += readLength or 0
			end
			
		else
			-- Call inbound middleware to handle the buffer
			local advanceCursor
			receivedEventData, advanceCursor = event.Middleware:CallInbound(receivedBuffer, cursor)
			cursor += advanceCursor
			
		end
		
		event:FireListeners(receivedEventData, player)
	end
end