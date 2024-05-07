--!native

local DataType_Misc = {
	Buffer = {
		
		Write = function(bufferQueue, value)
			local length = buffer.len(value)
			
			-- Length of buffer takes 2 bytes
			bufferQueue:AddOperation(buffer.writeu16, length)
			bufferQueue:AddOperation(buffer.copy, value, length)
		end,
		
		Read = function(targetBuffer, cursor)
			local length = buffer.readu16(targetBuffer, cursor)
			local freshBuffer = buffer.create(length)

			-- copy the data from the main buffer to the new buffer with an offset of 2 because of length
			buffer.copy(freshBuffer, 0, targetBuffer, cursor + 2, length)

			return freshBuffer, length + 2
		end,
	},
	
	String = {
		
		Write = function(bufferQueue, value)
			local length = string.len(value)
			
			-- Length of string takes 2 bytes
			bufferQueue:AddOperation(buffer.writeu16, length)
			bufferQueue:AddOperation(buffer.writestring, value, length)
		end,
		
		Read = function(targetBuffer, cursor)
			local length = buffer.readu16(targetBuffer, cursor)
			return buffer.readstring(targetBuffer, cursor + 2, length), length + 2
		end,
		
	},
	
	Array = function(dataType)
		
		local write = dataType.Write
		local read = dataType.Read
		
		return {
			Write = function(bufferQueue, array)
				local length = #array

				bufferQueue:AddOperation(buffer.writeu8, length)

				for i, value in array do
					write(bufferQueue, value)
				end
			end,

			Read = function(targetBuffer, cursor)
				local length = buffer.readu8(targetBuffer, cursor)
				local arrayCursor = cursor + 1

				local array = table.create(length)

				for i = 1, length do
					local readValue, readLength = read(targetBuffer, arrayCursor)
					table.insert(array, readValue)
					
					arrayCursor += readLength
				end
			
				-- Size of array 
				return array, (arrayCursor - cursor)
			end,
		}
		
	end,
	
	Map = function(keyDataType, valueDataType)
		
		local keyWrite, keyRead = keyDataType.Write, keyDataType.Read
		local valueWrite, valueRead = valueDataType.Write, valueDataType.Read
		
		return {
			Write = function(bufferQueue, map)
				local count = 0
				
				for k, v in map do
					count += 1
				end
				
				bufferQueue:AddOperation(buffer.writeu8, count)
				
				for k, v in map do
					keyWrite(bufferQueue, k)
					valueWrite(bufferQueue, v)
				end
			end,

			Read = function(targetBuffer, cursor)
				local count = buffer.readu8(targetBuffer, cursor)
				local map = {}
				local mapCursor = cursor + 1
				
				for i = 1, count do
					local key, keyLength = keyRead(targetBuffer, mapCursor)
					mapCursor += keyLength
					
					local value, valueLength = valueRead(targetBuffer, mapCursor)
					mapCursor += valueLength
					
					map[key] = value
				end
				
				return map, (mapCursor - cursor)
			end,
		}
		
	end,
	
}

return DataType_Misc
