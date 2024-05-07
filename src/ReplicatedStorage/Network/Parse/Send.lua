return function(event, data, queue)
	local eventId = event.Id
	local structure = event.ArgumentOrder
	
	-- Write the event ID first
	queue:writeu8(event.Id)
	
	-- If present, call outbound middleware to write to the queue
	if event:UsesMiddleware() then
		event.Middleware:CallOutbound(data, queue)
		return
	end
	
	-- Write arguments normally
	for i, typeData in event.ArgumentOrder do
		local key = typeData[1]
		local writeFunctions = typeData[2]
		writeFunctions.Write(queue, data[key])
	end
end
