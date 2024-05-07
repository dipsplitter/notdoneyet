local DataTypesFolder = script.Parent

local DataTypes = {}

for i, moduleScript in DataTypesFolder:GetChildren() do
	if moduleScript.Name == script.Name then
		continue
	end
	
	local dataTypes = require(moduleScript)
	
	for dataTypeName, dataTypeFunctions in dataTypes do
		
		if type(dataTypeFunctions) == "function" then
			
			DataTypes[dataTypeName] = dataTypeFunctions
			
		elseif type(dataTypeFunctions) == "table" then
			
			DataTypes[dataTypeName] = function()
				return dataTypeFunctions
			end
			
		end
		
	end
end

return DataTypes
