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

local ReadBitstream = {}
ReadBitstream.__index = ReadBitstream

function ReadBitstream.new(stream, offset)
	local self = {
		Buffer = stream,
		
		ByteCursor = offset or 0,
		
		BitCursor = 0,
		
		Bits = {},
		Lengths = {},
	}
	setmetatable(self, ReadBitstream)
	
	return self
end

function ReadBitstream:__tostring()
	local binaryStrings = {}
	for i, n in self.Bits do
		local str = FormatBinary(n, "_", 32)
		table.insert(binaryStrings, str)
	end

	return `{self.BitCursor}, {self.ByteCursor}, {table.concat(binaryStrings, " ")}`
end

function ReadBitstream:GetByteSize()
	return math.ceil(self.BitCursor / 8)
end

function ReadBitstream:ReadNextBits()
	local remainingSize = buffer.len(self.Buffer) - self.ByteCursor
	local readNumber = 0
	local size = 0
	
	if remainingSize >= 4 then
		readNumber = buffer.readu32(self.Buffer, self.ByteCursor)
		size += 4
	elseif remainingSize >= 2 then
		readNumber = buffer.readu16(self.Buffer, self.ByteCursor)
		size += 2
	elseif remainingSize >= 1 then
		readNumber = buffer.readu8(self.Buffer, self.ByteCursor)
		size += 1
	else
		warn("Ran out of room")
	end
	
	self.ByteCursor += size
	table.insert(self.Bits, readNumber)
	table.insert(self.Lengths, size)
	return readNumber
end

-- Max: 32 bits
function ReadBitstream:Read(numberOfBits)
	local numberToRead = self.Bits[1]
	
	if not numberToRead then
		numberToRead = self:ReadNextBits()
	end
	
	local totalBitsLength = self.Lengths[1] * 8
	
	local startingBitPosition = self.BitCursor % totalBitsLength
	
	local bitsToRead = math.min(numberOfBits, totalBitsLength - (self.BitCursor % totalBitsLength))
	local bitOverflow = numberOfBits - bitsToRead
	
	local result = bit32.extract(numberToRead, startingBitPosition, bitsToRead)
	self.BitCursor += bitsToRead
	
	-- We've read all the bits for this chunk
	if startingBitPosition + bitsToRead >= totalBitsLength then
		table.remove(self.Bits, 1)
		table.remove(self.Lengths, 1)
	end

	if bitOverflow > 0 then
		local nextNumberToRead = self:ReadNextBits()
		
		local remaining = bit32.extract(nextNumberToRead, 0, bitOverflow)
		result += bit32.lshift(remaining, bitsToRead)
		
		self.BitCursor += bitOverflow
	end
	
	return result
end

function ReadBitstream:ReadSigned(numberOfBits)
	local unsignedNumber = self:Read(numberOfBits)
	
	local firstBit = bit32.rshift(unsignedNumber, numberOfBits - 1)
	
	if firstBit == 1 then
		return unsignedNumber - (2 ^ numberOfBits)
	end
	
	return unsignedNumber
end

return ReadBitstream
