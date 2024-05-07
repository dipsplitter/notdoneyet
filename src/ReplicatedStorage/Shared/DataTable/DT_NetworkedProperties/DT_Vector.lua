local VECTOR_EPSILON = 1e-4
local NAN = 0 / 0
local XYZ_COMPONENT_ORDER = {"X", "Y", "Z"}
local XY_COMPONENT_ORDER = {"X", "Y"}

local DataType_Vector = {
	Name = "Vector",
	Bits = 32,
}

function DataType_Vector.GetBits(dataTypeInfo)
	return dataTypeInfo.Bits
end

function DataType_Vector.GetComponentCount(dataTypeInfo)
	if dataTypeInfo.Flags.VECTOR_XY then
		return 2
	end
	
	return 3
end

function DataType_Vector.GetTypeName(dataTypeInfo)
	if dataTypeInfo.Components == 2 then
		return "Vector2"
	end
	
	return "Vector3"
end

function DataType_Vector.DefaultValue(dataTypeInfo)
	return (if dataTypeInfo.Flags.VECTOR_XY then Vector2.zero else Vector3.zero)
end

function DataType_Vector.Changed(prev, current)
	local axisChanges = {
		math.abs(current.X - prev.X) >= VECTOR_EPSILON, 
		math.abs(current.Y - prev.Y) >= VECTOR_EPSILON, 
	}
	
	if typeof(current) == "Vector3" then
		table.insert(axisChanges, math.abs(current.Z - prev.Z) >= VECTOR_EPSILON)
	end

	return axisChanges[1] or axisChanges[2] or axisChanges[3], axisChanges
end

function DataType_Vector.Write(bitBuffer, value, dataTypeInfo)
	
	local componentsArray = if dataTypeInfo.Flags.VECTOR_XY then XY_COMPONENT_ORDER else XYZ_COMPONENT_ORDER
	
	for i, vectorComponent in componentsArray do
		bitBuffer:WriteFloat32(value[vectorComponent])
	end
end

function DataType_Vector.WriteDelta(bitBuffer, value, dataTypeInfo, deltaBits)
	local componentsArray = if dataTypeInfo.Flags.VECTOR_XY then XY_COMPONENT_ORDER else XYZ_COMPONENT_ORDER
	
	for i, vectorComponent in componentsArray do
		local componentChanged = deltaBits[i]
		
		if componentChanged == true then
			bitBuffer:WriteFloat32(value[vectorComponent])
		end
	end
end

function DataType_Vector.Read(bitBuffer, dataTypeInfo)
	local components = {}
	
	local componentsArray = if dataTypeInfo.Flags.VECTOR_XY then XY_COMPONENT_ORDER else XYZ_COMPONENT_ORDER
	
	for i, vectorComponent in componentsArray do
		components[i] = bitBuffer:ReadFloat32()
	end
	
	return if #components == 3 then Vector3.new(table.unpack(components)) else Vector2.new(table.unpack(components))
end

function DataType_Vector.ReadDelta(bitBuffer, dataTypeInfo, deltaBits)
	local components = {}
	
	local componentsArray = if dataTypeInfo.Flags.VECTOR_XY then XY_COMPONENT_ORDER else XYZ_COMPONENT_ORDER
	
	for i, vectorComponent in componentsArray do
		local changed = bit32.extract(deltaBits, i - 1, 1)	
		local component = NAN
		
		if changed == 1 then
			component = bitBuffer:ReadFloat32()
		end
		
		components[i] = component
	end
	
	return if #components == 3 then Vector3.new(table.unpack(components)) else Vector2.new(table.unpack(components))
end

-- Unchanged vector components are encoded with NAN, so fill those in with the previous component
function DataType_Vector.Reconcile(prev, new)
	local x = if new.X ~= new.X then prev.X else new.X
	local y = if new.Y ~= new.Y then prev.Y else new.Y
	
	if typeof(new) == "Vector3" then
		
		local z = if new.Z ~= new.Z then prev.Z else new.Z
		return Vector3.new(x, y, z)
		
	elseif typeof(new) == "Vector2" then
		
		return Vector2.new(x, y)
		
	end
end

return DataType_Vector
