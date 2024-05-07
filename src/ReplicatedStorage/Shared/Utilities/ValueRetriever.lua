
--[[
	Retrieves the intended value for an item if the item is not guaranteed
	to be a primitive
	
	Compatible with Value, functions
]]
local ValueRetriever = {}

function ValueRetriever.GetValue(value)
	
	if type(value) == "function" then
		return value()
	elseif type(value) == "table" then
		
		-- Value object
		if getmetatable(value) and value.IsClass then
			if value:IsClass("Value") or value:IsClass("TableListener") then
				return value.Value
			end
		else -- Array of a table and the corresponding key
			return value[1][value[2]]
		end
		
	end
	
	return value
end

return ValueRetriever
