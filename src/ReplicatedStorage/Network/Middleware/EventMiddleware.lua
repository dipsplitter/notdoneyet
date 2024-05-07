local EventMiddleware = {}
EventMiddleware.__index = EventMiddleware

function EventMiddleware.new()
	local self = {
		Inbound = {},
		Outbound = {},
	}
	setmetatable(self, EventMiddleware)
	
	return self
end

-- Writes data to the buffer queue (custom)
-- Outbound middleware functions should return true if the operation was successful
function EventMiddleware:CallOutbound(data, bufferQueue)
	for callbackName, callback in self.Outbound do
		local returnedTable = callback(data, bufferQueue)
		
		-- Abort, something failed somewhere
		if returnedTable.Status == false then
			return false
		end
		
		data = returnedTable.Data or data
	end
	
	return true
end

-- Takes a buffer and converts to a readable table of arguments
function EventMiddleware:CallInbound(stream, cursor)
	local content = stream
	local advanceCursor = 0
	
	local accumulatedData = {}

	for callbackName, callback in self.Inbound do
		local returnedTable = callback(content, cursor, accumulatedData)
		
		-- Maybe it was a debug function
		if not returnedTable then
			continue
		end
		
		-- Failed to parse the buffer somewhere
		if returnedTable.Status == false then
			return false
		end
		
		if returnedTable.Data and type(returnedTable.Data) == "table" then
			for key, value in returnedTable.Data do
				accumulatedData[key] = value
			end
		end
		
		content = returnedTable.NextData or content

		-- How much we read and processed
		if returnedTable.AdvanceCursor then
			advanceCursor += returnedTable.AdvanceCursor
			
			cursor += returnedTable.AdvanceCursor
		end
	end
	
	return accumulatedData, advanceCursor
end

function EventMiddleware:AddInbound(callbackName, callback)
	-- Don't override anything
	if self.Inbound[callbackName] then
		return
	end
	
	self.Inbound[callbackName] = callback
end

function EventMiddleware:AddOutbound(callbackName, callback)
	-- Don't override anything
	if self.Outbound[callbackName] then
		return
	end

	self.Outbound[callbackName] = callback
end

-- These should never really be necessary
function EventMiddleware:RemoveInbound(callbackName)
	self.Inbound[callbackName] = nil
end

function EventMiddleware:RemoveOutbound(callbackName)
	self.Outbound[callbackName] = nil
end

return EventMiddleware
