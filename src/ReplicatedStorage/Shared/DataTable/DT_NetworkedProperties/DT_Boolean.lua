local DataType_Boolean = {
	Name = "Boolean",
	Bits = 1,
	TypeName = "boolean",
}

function DataType_Boolean.DefaultValue()
	return false
end

function DataType_Boolean.Changed(prev, current)
	return prev ~= current	
end

function DataType_Boolean.Write(bitBuffer, value)
	bitBuffer:WriteBool(value)
end

function DataType_Boolean.Read(bitBuffer)
	return bitBuffer:ReadBool()
end

return DataType_Boolean
