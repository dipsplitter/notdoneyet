local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Constants = Framework.GetShared("DT_Constants")
local ClientIdentifiers = Framework.GetShared("DT_ClientIds").DataTables

local BitBuffer = Framework.RequireNetworkModule("BitBuffer")

local function MainInbound(stream, cursor)
	local bufferCursor = cursor

	local count = buffer.readu8(stream, bufferCursor)
	bufferCursor += 1
	
	local readData = table.create(count)

	local reader = BitBuffer.FromBuffer(stream)
	reader:SetCursorToByte(bufferCursor)
	
	for i = 1, count do
		-- Read metadata
		local dataTableId = reader:ReadVarInt()	
		local length = reader:ReadVarInt()
		
		bufferCursor += reader:GetBytesRead(bufferCursor)

		local dataTable = ClientIdentifiers[dataTableId]
		
		local readBuffer = reader:ReadBytes(length) -- WTF
		
		-- The client has not created the corresponding receive table
		-- We save a copy of the spliced buffer into the waiting queue
		if not dataTable then
			readData[dataTableId] = readBuffer
		else
			local values = dataTable.Packer:ReadBuffer(readBuffer)
			readData[dataTable] = values
		end

		bufferCursor += length
	end

	return {
		AdvanceCursor = bufferCursor - cursor,
		Status = true,
		Data = readData,
	}
end

-- DT bitstreams are already packed into a buffer, so insert the copy command
local function MainOutbound(data, queue)
	queue:AddBuffer(data)
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

