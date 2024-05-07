local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local ReadBuffer = Framework.GetShared("ReadBuffer")

local EnumService = Framework.GetShared("EnumService")
local VisualsEnum = EnumService.GetEnum("Enum_VisualEffects")
local VisualEventsEnum = EnumService.GetEnum("Enum_VisualEffectEvents")

local function MainInbound(stream, cursor)
	local readBuffer = ReadBuffer.new(stream, cursor)
	
	local id = readBuffer:readu8()
	local eventCount = readBuffer:readu8()
	
	local data = { 
		Id = id,
		Events = table.create(eventCount),
	}
	
	for i = 1, eventCount do
		local id = readBuffer:readu8()
		local eventName = VisualEventsEnum.FromValue(id)

		table.insert(data.Events, eventName)
	end
	
	return {
		AdvanceCursor = readBuffer:GetBytesRead(),
		Status = true,
		Data = data,
	}
end

local function MainOutbound(data, queue)
	queue:AddOperation(buffer.writeu8, data.Id)
	
	local eventStringArray = data.Events
	
	-- Array size
	queue:AddOperation(buffer.writeu8, #eventStringArray)
	for i, eventName in eventStringArray do
		local eventId = VisualEventsEnum[eventName]
		
		if not eventId then
			
		end
		
		queue:AddOperation(buffer.writeu8, eventId)
	end
	
	return {Status = true}
end

return {
	Inbound = {
		MainInbound,
	},
	 
	Outbound = {
		MainOutbound,
	}
}
