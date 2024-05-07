--!native

local function FormatBinary(number, separator, length)
	local total = math.max(32 - bit32.countlz(number), math.min(length or 0, 32))
	local result = ""
	for i = 1, total do
		result = bit32.band(number, 1) .. result
		number = bit32.rshift(number, 1)
		if separator and i < total and i % 4 == 0 then
			result = "_" .. result
		end
	end
	return result
end

local WriteBitstream = {}
WriteBitstream.__index = WriteBitstream

function WriteBitstream.new()
	local self = {
		Bits = {0},
		Cursor = 0,
	}
	setmetatable(self, WriteBitstream)
	
	return self
end

function WriteBitstream:__tostring()
	local binaryStrings = {}
	for i, n in self.Bits do
		local str = FormatBinary(n, "_", 32)
		table.insert(binaryStrings, str)
	end
	
	return `{self.Cursor} {table.concat(binaryStrings, " ")}`
end

function WriteBitstream:SetCursor(position)
	self.Cursor = position or 0
end

-- Max number of bits: 32
function WriteBitstream:Write(number, numberOfBits)
	if numberOfBits > 32 then
		warn("Your number's not gonna be lookin' good on the other end, pal")
	end
	
	-- Our end position
	local nextCursorPosition = self.Cursor + numberOfBits
	
	-- How many bits we can store right now
	local capacity = #self.Bits * 32
	
	local writeIndex = #self.Bits
	
	-- Not enough bits currently, so add enough numbers to fill
	if nextCursorPosition > capacity then
		
		local overflowAmount = nextCursorPosition - capacity
		
		-- Add the minimum numbers necessary
		for i = 1, math.ceil(overflowAmount / 32) do
			table.insert(self.Bits, 0)
		end
		
		-- Edge case: We're completely full. Start on the next new number
		if self.Cursor ~= 0 and self.Cursor % 32 == 0 then
			writeIndex += 1
		end
	end
	
	local bitsRemaining = numberOfBits
	
	while bitsRemaining > 0 do
		local localCursorPosition = self.Cursor % 32
		
		local numberToWrite = self.Bits[writeIndex]
		local bitsToWrite = math.min(numberOfBits, (writeIndex * 32) - self.Cursor)
		local shifted = bit32.lshift(number, localCursorPosition)
		
		self.Bits[writeIndex] = bit32.bor(numberToWrite, shifted)
		
		self.Cursor += bitsToWrite
		
		-- Exceeded this 32 bit chunk, so move on to the next number
		if self.Cursor >= writeIndex * 32 then
			writeIndex += 1
			
			-- Clear the bits we've already written
			number = bit32.rshift(number, bitsToWrite)
			numberOfBits -= bitsToWrite
		end
		
		bitsRemaining -= bitsToWrite
		
	end
end

function WriteBitstream:WriteSigned(signedNumber, numberOfBits)
	local bitsForNumber = numberOfBits - 1
	
	if signedNumber >= 0 then
		self:Write(signedNumber, bitsForNumber)
		self:Write(0, 1)
	else
		self:Write(2 ^ (numberOfBits - 1) + signedNumber, bitsForNumber)
		self:Write(1, 1)
	end
end

function WriteBitstream:ToBuffer()
	local bytesNeeded = math.ceil(self.Cursor / 8)
	local stream = buffer.create(bytesNeeded)
	
	self:WriteToBuffer(stream, 0)
	
	return stream
end

function WriteBitstream:WriteToBuffer(buf, offset)
	local bytesNeeded = math.ceil(self.Cursor / 8)
	
	local currentIndex = 1
	for i = 0, bytesNeeded - 1 do
		
		-- Done writing all 32 bits from this number, so move on to the next
		if i > 0 and i % 4 == 0 then
			currentIndex += 1
		end
		
		local current = self.Bits[currentIndex]
		
		-- Get the next 8 bits of this number
		local numberToWrite = bit32.extract(current, 8 * (i % 4), 8)

		buffer.writeu8(buf, offset + i, numberToWrite)
		
	end
	
	return bytesNeeded
end

return WriteBitstream
