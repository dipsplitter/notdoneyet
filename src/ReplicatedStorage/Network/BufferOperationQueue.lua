--!native
local SIZES = {
	[buffer.writeu8] = 1,
	[buffer.writeu16] = 2,
	[buffer.writeu32] = 4,
	
	[buffer.writei8] = 1,
	[buffer.writei16] = 2,
	[buffer.writei32] = 4,
	
	[buffer.writef32] = 4,
	[buffer.writef64] = 8,
}

local BufferOperationQueue = {}
BufferOperationQueue.__index = BufferOperationQueue

function BufferOperationQueue.new()
	local self = {
		Cursor = 0,
		Jobs = {}
	}
	
	setmetatable(self, BufferOperationQueue)
	
	return self
end

function BufferOperationQueue:AddOperation(writeFunction, writeValue, size)
	local jobIndex = #self.Jobs
	table.insert(self.Jobs, writeFunction)
	table.insert(self.Jobs, self.Cursor)
	table.insert(self.Jobs, writeValue)

	self.Cursor += size or SIZES[writeFunction]
	
	return jobIndex
end

function BufferOperationQueue:Flush()
	if #self.Jobs == 0 then
		return
	end
	
	local flushBuffer = buffer.create(self.Cursor)
	
	for i = 1, #self.Jobs, 3 do
		local writeFunction = self.Jobs[i]
		local writeAtCursor = self.Jobs[i + 1]
		local writeValue = self.Jobs[i + 2]

		writeFunction(flushBuffer, writeAtCursor, writeValue)
	end
	
	table.clear(self.Jobs)
	self.Cursor = 0
	
	return flushBuffer
end

function BufferOperationQueue:writeu8(value)
	return self:AddOperation(buffer.writeu8, value)
end

function BufferOperationQueue:writeu16(value)
	return self:AddOperation(buffer.writeu16, value)
end

function BufferOperationQueue:writeu32(value)
	return self:AddOperation(buffer.writeu32, value, 4)
end

function BufferOperationQueue:writei8(value)
	return self:AddOperation(buffer.writei8, value)
end

function BufferOperationQueue:writei16(value)
	return self:AddOperation(buffer.writei16, value)
end

function BufferOperationQueue:writei32(value)
	return self:AddOperation(buffer.writei32, value)
end

function BufferOperationQueue:writef32(value)
	return self:AddOperation(buffer.writef32, value)
end

function BufferOperationQueue:writef64(value)
	return self:AddOperation(buffer.writef64, value)
end

function BufferOperationQueue:writestring(value)
	return self:AddOperation(buffer.writestring, value)
end

function BufferOperationQueue:AddBuffer(targetBuffer)
	return self:AddOperation(buffer.copy, targetBuffer, buffer.len(targetBuffer))
end

return BufferOperationQueue
