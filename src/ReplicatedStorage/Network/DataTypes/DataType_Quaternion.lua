--!native

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local WriteBitstream = Framework.GetShared("WriteBitstream")
local ReadBitsream = Framework.GetShared("ReadBitstream")

local BitBuffer = Framework.RequireNetworkModule("BitBuffer")

local FP_EPSILON = 1e-6
local QUATERNION_PRECISION = 2^9 - 1 -- 9 bits, 1 sign bit
local QUATERNION_COMPONENT_BITS = 10

local function NormalizeQuaternion(cframe)
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

local DataTypes_Quaternion = {
	["Quaternion"] = {
		--[[
			2 bits for the largest component
			10 bits for each component (signed)
			Total: 32 bits / 4 bytes
		]]
		Write = function(bufferQueue, cframe)
			local components = NormalizeQuaternion(cframe)

			local value = -math.huge
			local largestIndex = 1
			local sign

			-- Find the largest component in quaternion
			for i, component in components do
				local abs = math.abs(component)
				if abs > value then
					largestIndex = i
					value = abs
					sign = component
				end
			end

			sign = if sign >= 0 then 1 else -1
			
			-- 2 bits for largest index
			local writeBitBuffer = BitBuffer.new()
			
			-- Subtract by 1 to keep the index between 0 and 3 (the array indices are 1 to 4)
			writeBitBuffer:WriteUInt(2, largestIndex - 1)
			
			for i, value in components do
				if i == largestIndex then
					continue
				end

				local compressedToInt = math.floor(value * sign * QUATERNION_PRECISION + 0.5)
				
				writeBitBuffer:WriteInt(QUATERNION_COMPONENT_BITS, compressedToInt)
			end

			bufferQueue:AddOperation(buffer.copy, writeBitBuffer:ToBuffer(), 4)
		end,

		Read = function(targetBuffer, cursor)
			local readBitBuffer = BitBuffer.FromBuffer(targetBuffer)
			readBitBuffer:SetCursorToByte(cursor)
			
			local largestIndex = readBitBuffer:ReadUInt(2) + 1 -- Add one to correspond with array indices starting at 1

			local components = table.create(4)
			local sum = 0

			for i = 1, 3 do
				local component = readBitBuffer:ReadInt(QUATERNION_COMPONENT_BITS)
				component /= QUATERNION_PRECISION

				table.insert(components, component)

				sum += (component * component)
			end
			
			local largest = math.sqrt(1 - sum)
			table.insert(components, largestIndex, largest)
			
			local qx, qy, qz, qw = table.unpack(components)
			
			return CFrame.new(0, 0, 0, qx, qy, qz, qw), 4
		end,
	},
}

return DataTypes_Quaternion
