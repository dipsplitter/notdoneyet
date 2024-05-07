local FloatUtilities = require(script.Parent.FloatUtilities)

local NAN = 0 / 0

local POSITION_EPSILON = 1e-4
local QUATERNION_EPSILON = 1e-4
local FP_EPSILON = 1e-6

local QUATERNION_PRECISION = 2^9 - 1 -- 9 bits, 1 sign bit
local QUATERNION_COMPONENT_BITS = 10

local POSITION_COMPONENTS = {"X", "Y", "Z"}

local DataType_CFrame = {
	Name = "CFrame",
}

local function ToNormalizedQuaternion(cframe)
	local axis, angle = cframe:ToAxisAngle()
	axis = axis.Magnitude > FP_EPSILON and axis.Unit or Vector3.xAxis

	local halfAngle = angle / 2
	local sin = math.sin(halfAngle)

	local qx, qy, qz = sin * axis.X, sin * axis.Y, sin * axis.Z
	local qw = math.cos(halfAngle)

	local length = math.sqrt(qx * qx + qy * qy + qz * qz + qw * qw)
	if length < FP_EPSILON then
		return {0, 0, 0, 1}
	end

	return {qx / length, qy / length, qz / length, qw / length}
end

local function EncodeQuaternionComponent(component)
	return math.floor(component * QUATERNION_PRECISION + 0.5)
end

function DataType_CFrame.DefaultValue()
	return CFrame.new()
end

function DataType_CFrame.GetComponentCount(dataTypeInfo)
	return 7
end

function DataType_CFrame.Changed(prev, current)
	local axisChanges = table.create(7) -- 3 position, 4 quaternion
	for i, positionComponent in POSITION_COMPONENTS do
		axisChanges[i] = math.abs(current[positionComponent] - prev[positionComponent]) >= POSITION_EPSILON
	end
	
	local prevQuaternion = ToNormalizedQuaternion(prev)
	local currentQuaternion = ToNormalizedQuaternion(current)
	
	for i, component in currentQuaternion do
		axisChanges[i + #POSITION_COMPONENTS] = math.abs(prevQuaternion[i] - component) >= QUATERNION_EPSILON
	end
	
	local didChange = false
	for i, changeStatus in axisChanges do
		if changeStatus == true then
			didChange = true
			break
		end
	end
	
	return didChange, axisChanges
end

function DataType_CFrame.Write(bitBuffer, value, dataTypeInfo)
	bitBuffer:WriteFloat32(value.X)
	bitBuffer:WriteFloat32(value.Y)
	bitBuffer:WriteFloat32(value.Z)

	-- Now write the quaternion
	local quaternionComponents = ToNormalizedQuaternion(value)
	
	for i, component in quaternionComponents do
		local encoded = EncodeQuaternionComponent(component)
		bitBuffer:WriteInt(QUATERNION_COMPONENT_BITS, encoded)
	end
end

function DataType_CFrame.WriteDelta(bitBuffer, value, dataTypeInfo, deltaBits)
	for i, vectorComponent in POSITION_COMPONENTS do
		local componentChanged = deltaBits[i]

		if componentChanged == true then
			bitBuffer:WriteFloat32(value[vectorComponent])
		end
	end
	
	local quaternionComponents = ToNormalizedQuaternion(value)
	
	for i, quaternionComponent in quaternionComponents do
		local componentChanged = deltaBits[i + 3]
		
		if componentChanged == true then
			local encoded = EncodeQuaternionComponent(quaternionComponent)
			bitBuffer:WriteInt(QUATERNION_COMPONENT_BITS, encoded)
		end
	end
end

function DataType_CFrame.Read(bitBuffer, dataTypeInfo)
	local components = {}

	for i = 1, 3 do
		table.insert(components, bitBuffer:ReadFloat32()) 
	end
	
	for i = 1, 4 do
		local quaternionComponent = bitBuffer:ReadInt(QUATERNION_COMPONENT_BITS) / QUATERNION_PRECISION

		table.insert(components, quaternionComponent)
	end

	return CFrame.new(table.unpack(components))
end

-- Writing NaN for a quaternion component will cause the entire rotation matrix of the constructed CFrame to be NaN
-- So we have to return a table instead
function DataType_CFrame.ReadDelta(bitBuffer, dataTypeInfo, deltaBits)
	local components = {}

	for i = 1, 3 do
		local changed = bit32.extract(deltaBits, i - 1, 1)	
		local component = NAN

		if changed == 1 then
			component = bitBuffer:ReadFloat32()
		end

		components[i] = component
	end
	
	for i = 4, 7 do
		local changed = bit32.extract(deltaBits, i - 1, 1)
		local quaternionComponent = NAN
		
		if changed == 1 then
			quaternionComponent = bitBuffer:ReadInt(QUATERNION_COMPONENT_BITS) / QUATERNION_PRECISION
		end
		
		components[i] = quaternionComponent 
	end

	return components
end

function DataType_CFrame.Reconcile(prev, new)
	local newComponents = new
	if typeof(newComponents) == "CFrame" then
		newComponents = {new.X, new.Y, new.Z, table.unpack(ToNormalizedQuaternion(new))}
	end
	
	local prevComponents = {prev.X, prev.Y, prev.Z, table.unpack(ToNormalizedQuaternion(prev))}
	
	local cfComponents = table.create(7)
	
	for i, newComponent in newComponents do	
		if newComponent ~= newComponent then
			cfComponents[i] = prevComponents[i]
		else
			cfComponents[i] = newComponent
		end
	end

	return CFrame.new(table.unpack(cfComponents))
end

return DataType_CFrame
