local idToEvent = {}
local currentId = 0

local EventTracker = {}

function EventTracker.Register(event)
	local id = event.Id or currentId
	
	idToEvent[id] = event
	
	currentId += 1
end

function EventTracker.FromId(id)
	return idToEvent[id]
end

return EventTracker
