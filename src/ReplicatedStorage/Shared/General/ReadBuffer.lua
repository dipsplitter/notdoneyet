local functions = {
	u8 = {1, buffer.readu8},
	u16 = {2, buffer.readu16},
	u32 = {4, buffer.readu32},

	i8 = {1, buffer.readi8},
	i16 = {2, buffer.readi16},
	i32 = {4, buffer.readi32},

	f32 = {4, buffer.readf32},
	f64 = {8, buffer.readf64},
}


local ReadBuffer = {}
ReadBuffer.__index = ReadBuffer

for dataType, info in functions do
	local byteSize = info[1]
	local readFn = info[2]

	ReadBuffer[`read{dataType}`] = function(self)
		local value = readFn(self.Buffer, self.Cursor)
		self.Cursor += byteSize
		return value
	end
end

function ReadBuffer.new(b, cursor)
	local self = {
		Buffer = b,
		StartCursor = cursor,
		Cursor = cursor,
	}
	setmetatable(self, ReadBuffer)
	
	return self
end

function ReadBuffer:GetBytesRead()
	return self.Cursor - self.StartCursor
end

return ReadBuffer
