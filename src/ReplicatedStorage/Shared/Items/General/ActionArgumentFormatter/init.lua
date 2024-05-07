--[[
	When we fire an action event for a NETWORKED item, the arguments table is serialized via the network middleware and deserialized from the server,
	where the event handlers receive the properly formatted table
	
	This behavior only occurs with NETWORKED items...
	So what the hell to do with NPC or server-owned items? The handlers will receive invalid argument tables...
	
	Example:
	MultiCharacterRaycastResult's (stupid name, I know) raw arguments are an map of raycast IDs to their raw raycast results (converted to a dictionary, not the actual data type)
	
	But what the handlers are expecting is a map of raycast IDs to a table containing the hit character and the body part where that character got hit
	So an NPC tries to attack you, and everything goes to hell because the handlers got the raw raycast results instead of the formatted ones!
	
	The answer is to copy everything... But not everything because we don't need any of those buffer shenanigans!
	
	We COULD use the network middleware... but then we'd need to create a buffer, serialize into that buffer, 
	and then immediately deserialize out into a table.
]]

return function(argsTable)
	local signature = argsTable.Args.SIGNATURE
	if not signature then
		return argsTable
	end
	
	local module = script:FindFirstChild(signature)
	
	if module then
		local formatFunction = require(module)
		
		return formatFunction(argsTable)
	end
	
	-- It's... good, I guess?
	return argsTable
end
