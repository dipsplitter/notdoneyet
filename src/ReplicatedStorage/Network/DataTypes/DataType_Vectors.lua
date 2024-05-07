--!native
local Quaternion = require(script.Parent.DataType_Quaternion).Quaternion

local SPECIAL_CFRAME_ROTATIONS = {
	CFrame.Angles(0, 0, 0),
	CFrame.Angles(math.rad(90), 0, 0),
	CFrame.Angles(0, math.rad(180), math.rad(180)),
	CFrame.Angles(math.rad(-90), 0, 0),
	CFrame.Angles(0, math.rad(180), math.rad(90)),
	CFrame.Angles(0, math.rad(90), math.rad(90)),
	CFrame.Angles(0, 0, math.rad(90)),
	CFrame.Angles(0, math.rad(-90), math.rad(90)),
	CFrame.Angles(math.rad(-90), math.rad(-90), 0),
	CFrame.Angles(0, math.rad(-90), 0),
	CFrame.Angles(math.rad(90), math.rad(-90), 0),
	CFrame.Angles(0, math.rad(90), math.rad(180)),
	CFrame.Angles(0, math.rad(-90), math.rad(180)),
	CFrame.Angles(0, math.rad(180), math.rad(0)),
	CFrame.Angles(math.rad(-90), math.rad(-180), math.rad(0)),
	CFrame.Angles(0, math.rad(0), math.rad(180)),
	CFrame.Angles(math.rad(90), math.rad(180), math.rad(0)),
	CFrame.Angles(0, math.rad(0), math.rad(-90)),
	CFrame.Angles(0, math.rad(-90), math.rad(-90)),
	CFrame.Angles(0, math.rad(-180), math.rad(-90)),
	CFrame.Angles(0, math.rad(90), math.rad(-90)),
	CFrame.Angles(math.rad(90), math.rad(90), 0),
	CFrame.Angles(0, math.rad(90), 0),
	CFrame.Angles(math.rad(-90), math.rad(90), 0),
}

local DataType_Vectors = {
	["Vector3"] = {
		Write = function(bufferQueue, value)
			bufferQueue:AddOperation(buffer.writef32, value.X)
			bufferQueue:AddOperation(buffer.writef32, value.Y)
			bufferQueue:AddOperation(buffer.writef32, value.Z)
		end,
		
		Read = function(targetBuffer, cursor)
			return Vector3.new(
				buffer.readf32(targetBuffer, cursor),
				buffer.readf32(targetBuffer, cursor + 4),
				buffer.readf32(targetBuffer, cursor + 8)), 12
		end,
	},
	
	["Vector2"] = {
		Write = function(bufferQueue, value)
			bufferQueue:AddOperation(buffer.writef32, value.X)
			bufferQueue:AddOperation(buffer.writef32, value.Y)
		end,
		
		Read = function(targetBuffer, cursor)
			return Vector2.new(
				buffer.readf32(targetBuffer, cursor),
				buffer.readf32(targetBuffer, cursor + 4)), 8
		end,
	},
	
	["CFrame"] = {
		-- 13 bytes best case, 17 bytes worst
		Write = function(bufferQueue, value)
			local rotationVector = value.Rotation
			local index = table.find(SPECIAL_CFRAME_ROTATIONS, rotationVector)
			
			-- First bit determines whether this CFrame has a special rotation
			local isSpecialCaseByte = 0
			if index then
				isSpecialCaseByte = (bit32.lshift(1, 7) + index)
			end
			
			bufferQueue:AddOperation(buffer.writeu8, isSpecialCaseByte)
			
			bufferQueue:AddOperation(buffer.writef32, value.X)
			bufferQueue:AddOperation(buffer.writef32, value.Y)
			bufferQueue:AddOperation(buffer.writef32, value.Z)
			
			-- Write rotation as quaternion if this isn't a special case
			if isSpecialCaseByte == 0 then
				Quaternion.Write(bufferQueue, value)
			end
		end,

		Read = function(targetBuffer, cursor)
			local usedCursor = cursor
			
			local isSpecialCaseByte = buffer.readu8(targetBuffer, usedCursor)
			usedCursor += 1
			
			-- Read first bit
			local isSpecialCase = (bit32.rshift(isSpecialCaseByte, 7) == 1)
			
			local x, y, z = buffer.readf32(targetBuffer, usedCursor), buffer.readf32(targetBuffer, usedCursor + 4), buffer.readf32(targetBuffer, usedCursor + 8)
			local positionVector = Vector3.new(x, y, z)
			usedCursor += 12
			
			-- Retrieve special case
			if isSpecialCase then
				local rotationIndex = isSpecialCaseByte - 2^7
				local rotationVector = SPECIAL_CFRAME_ROTATIONS[rotationIndex]
				
				return CFrame.new(positionVector) * rotationVector, (usedCursor - cursor)
			end
			
			-- Read angular data as quaternion
			local rotationCframe, addCursor = Quaternion.Read(targetBuffer, usedCursor)
			usedCursor += addCursor
			
			local result = CFrame.new(positionVector) * rotationCframe

			return result, (usedCursor - cursor)
		end,
	},
}

return DataType_Vectors
