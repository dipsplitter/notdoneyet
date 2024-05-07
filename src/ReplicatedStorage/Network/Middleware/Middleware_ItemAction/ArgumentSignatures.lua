local ArgumentSignatures = {}

function ArgumentSignatures.GenerateSignature(argsTable)
	if not argsTable then
		return ""
	end
	
	local signature = {}
	for argName in argsTable do
		table.insert(signature, argName)
	end

	table.sort(signature, function(a, b)
		return #a < #b
	end)

	return table.concat(signature, ".")
end

function ArgumentSignatures.GenerateSignatureFromStructure(structureArrays)
	if not structureArrays then
		return
	end
	
	local signature = {}

	for j, structureArray in structureArrays do
		local argName = structureArray[1]
		table.insert(signature, argName)
	end

	table.sort(signature, function(a, b)
		return #a < #b
	end)

	return table.concat(signature, ".")
end

return ArgumentSignatures
