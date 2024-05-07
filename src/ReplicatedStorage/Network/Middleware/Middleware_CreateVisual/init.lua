local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local ReadBuffer = Framework.GetShared("ReadBuffer")

local EnumService = Framework.GetShared("EnumService")
local VisualsEnum = EnumService.GetEnum("Enum_VisualEffects")

local Properties = require(script.VisualEffectProperties)

local function MainInbound(stream, cursor)
	local readBuffer = ReadBuffer.new(stream, cursor)
	
	local id = readBuffer:readu8()
	local visualType = VisualsEnum.FromValue(readBuffer:readu16())
	local propertyCount = readBuffer:readu8()
	
	local data = { 
		Id = id,
		VisualId = visualType,
		Args = {},
	}
	
	for i = 1, propertyCount do
		local propertyIndex = readBuffer:readu8()
		
		local propertyInfo = Properties.Properties[propertyIndex]
		local propertyName, readFunction = propertyInfo[1], propertyInfo[2].Read
		
		local value, addCursor = readFunction(stream, readBuffer.Cursor)
		readBuffer.Cursor += addCursor
		
		data.Args[propertyName] = value
	end
	
	return {
		AdvanceCursor = readBuffer:GetBytesRead(),
		Status = true,
		Data = data,
	}
end

local function MainOutbound(data, queue)
	queue:writeu8(data.Id)
	
	local visualId = data.VisualId
	if type(visualId) == "string" then
		visualId = VisualsEnum[visualId]
	end
	queue:writeu16(visualId)
	
	local args = data.Args
	
	local count = 0
	for propertyName, value in args do
		count += 1
	end
	queue:writeu8(count)
	
	for propertyName, value in args do
		
		local indexToWrite = Properties.PropertyIndices[propertyName]
		queue:writeu8(indexToWrite)
		
		local writeFunctions = Properties.Properties[indexToWrite][2]
		writeFunctions.Write(queue, value)
		
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
