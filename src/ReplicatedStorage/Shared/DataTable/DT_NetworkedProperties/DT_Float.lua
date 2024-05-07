local FLOAT_EPSILON = 1e-4

local DataType_Float = {
	Name = "Float",
	Bits = 32,
	TypeName = "number",
}

function DataType_Float.DefaultValue()
	return 0
end

function DataType_Float.Changed(prev, current)
	return math.abs(current - prev) > FLOAT_EPSILON
end

function DataType_Float.Write(bitBuffer, value, dataTypeInfo)
	local flags = dataTypeInfo.Flags
	
	-- Special case: 16 bit float
	if flags.HALF_PRECISION then
		bitBuffer:WriteFloat16(value)
		return
	end
	
	bitBuffer:WriteFloat32(value)
end

function DataType_Float.Read(bitBuffer, dataTypeInfo)
	local flags = dataTypeInfo.Flags
	
	-- Special case: 16 bit float
	if flags.HALF_PRECISION then
		return bitBuffer:ReadFloat16()
	end
	
	return bitBuffer:ReadFloat32()
end

return DataType_Float
