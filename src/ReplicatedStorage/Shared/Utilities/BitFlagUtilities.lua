local BitFlagUtilities = {}

function BitFlagUtilities.Serialize(flags, lookup)
	local number = 0
	
	for flagName in flags do
		if lookup[flagName] then
			number = bit32.bor(number, lookup[flagName])
		end
	end
	
	return number
end

function BitFlagUtilities.Deserialize(number, lookup)
	local flags = {}
	
	for i = 0, 31 do
		local bit = bit32.extract(number, i, 1)
		if bit == 1 then
			flags[lookup[2^i] or lookup.FromValue(2^i)] = true
		end
	end
	
	return flags
end

return BitFlagUtilities
