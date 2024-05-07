local DataType_Integer = {
	Name = "Integer",
	Bits = 32,
	DefaultValue = 0,
	TypeName = "number",
}

function DataType_Integer.DefaultValue()
	return 0
end

function DataType_Integer.Changed(prev, current)
	return prev ~= current
end

function DataType_Integer.Write(bitBuffer, value, dataTypeInfo)
	local bits = dataTypeInfo.Bits

	local flags = dataTypeInfo.Flags
	
	if flags.UNSIGNED then
		bitBuffer:WriteUInt(bits, value)
	else
		bitBuffer:WriteInt(bits, value)
	end
end

function DataType_Integer.Read(bitBuffer, dataTypeInfo)
	local bits = dataTypeInfo.Bits
	local flags = dataTypeInfo.Flags
	
	if flags.UNSIGNED then
		return bitBuffer:ReadUInt(bits)
	else
		return bitBuffer:ReadInt(bits)
	end
end

return DataType_Integer
