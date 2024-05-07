local GenericParse = {}

function GenericParse.Serialize(argsTable, queue, structure)
	for i, arg in structure do
		local argName, dataType = arg[1], arg[2]

		dataType.Write(queue, argsTable[argName])
	end
end

function GenericParse.Deserialize(stream, cursor, structure)
	local argsTable = {}
	local usedCursor = cursor

	for i, arg in structure do
		local argName, dataType = arg[1], arg[2]

		local addCursor
		argsTable[argName], addCursor = dataType.Read(stream, usedCursor)

		usedCursor += addCursor
	end

	return argsTable, usedCursor - cursor
end

return GenericParse
