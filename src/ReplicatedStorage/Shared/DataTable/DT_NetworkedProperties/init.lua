--!native

local FLAG_LOOKUP = {
	"UNSIGNED",
	"HALF_PRECISION",
	"VECTOR_XY"
}

local NetworkedProperties = {
	DataTypes = {
		Integer = require(script.DT_Integer),
		Float = require(script.DT_Float),
		Boolean = require(script.DT_Boolean),
		Vector = require(script.DT_Vector),
		["CFrame"] = require(script.DT_CFrame),
	},
	
	Flags = {
		UNSIGNED = 1, -- Whether the first bit of the integer is a sign bit
		HALF_PRECISION = 2, -- Floats encoded in 16-bits (5 exponent, 10 mantissa)
		VECTOR_XY = 3, -- Vector2
	},
}

--[[
	Par
]]
function NetworkedProperties.DeclareProperty(baseType, params)
	params = params or {}
	local flagIds = params.Flags or {}
	
	local flags = table.create(#flagIds)
	
	for i, flagId in flagIds do
		flags[FLAG_LOOKUP[flagId]] = true
	end
	
	local dataTypeInfo = NetworkedProperties.DataTypes[baseType]
	
	local bits = params.Bits
	if not bits then
		bits = dataTypeInfo.Bits
	end
	
	local dataTypeTable = {
		DECLARED_PROPERTY = true, -- In case we for some reason want to include initial values in a structure
		Type = baseType,
		Bits = bits,
		Flags = flags,
		TypeName = dataTypeInfo.TypeName, -- String name of the data type
	}
	
	local components = dataTypeInfo.Components or 1
	if dataTypeInfo.GetComponentCount then
		components = dataTypeInfo.GetComponentCount(dataTypeTable)
	end
	dataTypeTable.Components = components
	
	if dataTypeInfo.GetBits then
		dataTypeTable.Bits = dataTypeInfo.GetBits(dataTypeTable)
	end
	
	if not dataTypeInfo.TypeName then
		dataTypeTable.TypeName = if dataTypeInfo.GetTypeName then dataTypeInfo.GetTypeName(dataTypeTable) else "number"
	end
	
	dataTypeTable.MaximumRate = params.MaximumRate
	
	return dataTypeTable
end

return NetworkedProperties