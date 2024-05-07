local EventSequencer = {}
EventSequencer.__index = EventSequencer

function EventSequencer.new(assetsFolder)
	local self = {}
	setmetatable(self, EventSequencer)
	
	return self
end

return EventSequencer
