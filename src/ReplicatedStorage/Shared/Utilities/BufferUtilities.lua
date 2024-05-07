--!native

local BufferUtilities = {}

function BufferUtilities.Merge(...)
	local buffers = {...}
	local size = 0
	for i, b in buffers do
		size += buffer.len(b)
	end
	
	local merged = buffer.create(size)
	
	local cursor = 0
	for i, b in buffers do
		local bSize = buffer.len(b)
		buffer.copy(merged, cursor, b)
		cursor += bSize
	end
	
	return merged
end

function BufferUtilities.MergeArray(bufferArray)
	local size = 0
	for i, b in bufferArray do
		size += buffer.len(b)
	end

	local merged = buffer.create(size)

	local cursor = 0
	for i, b in bufferArray do
		local bSize = buffer.len(b)
		buffer.copy(merged, cursor, b)
		cursor += bSize
	end

	return merged
end

function BufferUtilities.Splice(buff, start, stop)
	local size = buffer.len(buff)
	stop = stop or size
	
	local new = buffer.create(stop - start)
	
	buffer.copy(new, 0, buff, start, stop - start)
	
	return new
end

function BufferUtilities.GetBitsForUnsignedInteger(number)
	return math.floor(math.log(number, 2)) + 1
end

function BufferUtilities.GetBytesForUnsignedInteger(number)
	return math.ceil( BufferUtilities.GetBitsForUnsignedInteger(number) / 8 )
end

function BufferUtilities.WriteBitsToBuffer(buff, offset, bits, count)
	-- Fast path: only writing 1 byte
	if count == 1 then
		buffer.writeu8(buff, offset, bits)
		return
	end

	for byte = 0, (count - 1) do
		local value = bit32.extract(bits, byte * 8, 8)
		buffer.writeu8(buff, offset + byte, value)
	end
end

function BufferUtilities.ReadBitsFromBuffer(buff, offset, count)
	-- Fast path: only reading 1 byte
	if count == 1 then
		return buffer.readu8(buff, offset)
	end

	local bits = 0
	for cursor = 0, (count - 1) do
		local value = buffer.readu8(buff, offset + cursor)
		bits += bit32.lshift(value, cursor * 8) 
	end

	return bits
end

function BufferUtilities.GetVLQSize(length)
	return math.ceil(math.log(length + 1, 8))
end

return BufferUtilities