local DataTypes_Struct = {
	Struct = function(keyToValueType)
		
		local indexToValueType = {}
		local indexToKey = {}
		
		-- Populate our arrays
		for key, valueType in keyToValueType do
			table.insert(indexToKey, key)
		end
		table.sort(indexToKey)
		
		for index, key in indexToKey do
			indexToValueType[index] = keyToValueType[key]
		end
		
		return {
			Write = function(bufferQueue, args)
				for index, valueType in indexToValueType do
					valueType.Write(bufferQueue, args[indexToKey[index]])
				end
			end,
			
			Read = function(targetBuffer, cursor)
				local newTable = table.clone(keyToValueType)
				local usedCursor = cursor
				
				for index, valueType in indexToValueType do
					local readValue, length = valueType.Read(targetBuffer, usedCursor)
					
					usedCursor += length
					
					newTable[indexToKey[index]] = readValue
				end
				
				return newTable, usedCursor - cursor
			end,
		}
	end,
}

return DataTypes_Struct