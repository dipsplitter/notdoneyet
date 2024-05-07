--!native

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BufferUtilities = Framework.GetShared("BufferUtilities")

--[[
	Buffer wrapper that implements a cursor
]]

local functions = {
	u8 = {1, buffer.readu8, buffer.writeu8},
	u16 = {2, buffer.readu16, buffer.writeu16},
	u32 = {4, buffer.readu32, buffer.writeu32},
	
	i8 = {1, buffer.readi8, buffer.writei8},
	i16 = {2, buffer.readi16, buffer.writei16},
	i32 = {4, buffer.readi32, buffer.writei32},
	
	f32 = {4, buffer.readf32, buffer.writef32},
	f64 = {8, buffer.readf64, buffer.writef64},
}

local Buffer = {}
Buffer.__index = Buffer

for dataType, info in functions do
	local byteSize = info[1]
	local readFn = info[2]
	local writeFn = info[3]
	
	Buffer[`read{dataType}`] = function(self)
		local value = readFn(self.Buffer, self.Cursor)
		self.Cursor += byteSize
		return value
	end
	
	Buffer[`write{dataType}`] = function(self, value, shouldResize)
		if shouldResize then
			if self.Cursor + byteSize > self.Capacity then
				self:Resize()
			end
		end
		
		writeFn(self.Buffer, self.Cursor, value)
		self.Cursor += byteSize
		self.FilledSize += byteSize
	end
end

function Buffer.new(object)
	local self = {
		Buffer = if type(object) == "number" then buffer.create(object or 10) else object,
		Cursor = 0,
		FilledSize = 0,
	}
	setmetatable(self, Buffer)
	
	return self
end

function Buffer:Resize()
	local newBuffer = buffer.create(2 * self.Capacity)
	
	buffer.copy(newBuffer, 0, self.Buffer, 0, self.Capacity)
	
	self.Buffer = newBuffer
	self.Capacity *= 2
end

function Buffer:readf16()
	local b0 = buffer.readu8(self.Buffer, self.Cursor)
	self.Cursor += 1
	local b1 = buffer.readu8(self.Buffer, self.Cursor)
	self.Cursor += 1

	local sign = bit32.btest(b0, 128)
	local exponent = bit32.rshift(bit32.band(b0, 127), 2)
	local mantissa = bit32.lshift(bit32.band(b0, 3), 8) + b1

	if exponent == 31 then --2^5-1
		if mantissa ~= 0 then
			return (0 / 0)
		else
			return (sign and -math.huge or math.huge)
		end
	elseif exponent == 0 then
		if mantissa == 0 then
			return 0
		else
			return (sign and -math.ldexp(mantissa / 1024, -14) or math.ldexp(mantissa / 1024, -14))
		end
	end

	mantissa = (mantissa / 1024) + 1

	return (sign and -math.ldexp(mantissa, exponent - 15) or math.ldexp(mantissa, exponent - 15))
end

function Buffer:writef16(value, shouldResize)
	if shouldResize then
		if self.Cursor + 2 > self.Capacity then
			self:Resize()
		end
	end
	
	self.FilledSize += 2
	
	local sign = value < 0
	value = math.abs(value)

	local mantissa, exponent = math.frexp(value)

	if value == math.huge then
		if sign then
			buffer.writeu8(self.Buffer, self.Cursor, 252)-- 11111100
			self.Cursor += 1
		else
			buffer.writeu8(self.Buffer, self.Cursor, 124) -- 01111100
			self.Cursor += 1
		end
		
		buffer.writeu8(self.Buffer, self.Cursor, 0) -- 00000000
		self.Cursor += 1
		
		return
	elseif value ~= value or value == 0 then
		buffer.writeu8(self.Buffer, self.Cursor, 0)
		self.Cursor += 1
		buffer.writeu8(self.Buffer, self.Cursor ,0)
		self.Cursor += 1
		return
	elseif exponent + 15 <= 1 then -- Bias for halfs is 15
		mantissa = math.floor(mantissa * 1024 + 0.5)
		if sign then
			buffer.writeu8(self.Buffer, self.Cursor, (128 + bit32.rshift(mantissa, 8))) -- Sign bit, 5 empty bits, 2 from mantissa
			self.Cursor += 1
		else
			buffer.writeu8(self.Buffer, self.Cursor, (bit32.rshift(mantissa, 8)))
			self.Cursor += 1
		end
		buffer.writeu8(self.Buffer, self.Cursor, bit32.band(mantissa, 255)) -- Get last 8 bits from mantissa
		self.Cursor += 1
		return
	end

	mantissa = math.floor((mantissa - 0.5) * 2048 + 0.5)

	-- The bias for halfs is 15, 15-1 is 14
	if sign then
		buffer.writeu8(self.Buffer, self.Cursor, (128 + bit32.lshift(exponent + 14, 2) + bit32.rshift(mantissa, 8)))
		self.Cursor += 1
	else
		buffer.writeu8(self.Buffer, self.Cursor, (bit32.lshift(exponent + 14, 2) + bit32.rshift(mantissa, 8)))
		self.Cursor += 1
	end
	buffer.writeu8(self.Buffer, self.Cursor, bit32.band(mantissa, 255))
	self.Cursor += 1
end

function Buffer:GetMinimalSizeCopy()
	local currentLen = self.FilledSize
	local newBuffer = buffer.create(currentLen)
	buffer.copy(newBuffer, 0, self.Buffer, 0, currentLen)
	
	return newBuffer
end

function Buffer:Splice(start, stop)
	return BufferUtilities.Splice(self.Buffer, start, stop)
end

function Buffer:Merge(other)
	local current = self:GetMinimalSizeCopy()
	
	local newBuffer
	if type(other) == "buffer" then
		newBuffer = BufferUtilities.Merge(current, other)
		self.FilledSize += buffer.len(other)
	elseif type(other) == "table" then
		newBuffer = BufferUtilities.Merge(current, other.Buffer)
		self.FilledSize += other.FilledSize
	end
	
	self.Buffer = newBuffer
end

return Buffer
