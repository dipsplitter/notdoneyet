local EnumsFolder = script.Parent

-- Key: number
local enums = {}

-- Number: key
local valueToEnumKey = {}

local function ModuleContainsMultipleEnums(requiredModule)
	local key, value = next(requiredModule)
	if type(value) == "table" then
		return true
	end

	return false
end

local function RegisterEnum(name, enumTable)
	enums[name] = {
		FromValue = function(id)
			return valueToEnumKey[name][id]
		end,
	}
	valueToEnumKey[name] = {}

	local entry = enums[name]
	for enumKey, enumValue in enumTable do
		entry[enumKey] = enumValue
		valueToEnumKey[name][enumValue] = enumKey
	end
end

-- Initialize
for i, moduleScript in EnumsFolder:GetDescendants() do
	if not moduleScript:IsA("ModuleScript") or moduleScript == script then
		continue
	end
	
	local required = require(moduleScript)
	
	if ModuleContainsMultipleEnums(required) then
		for enumName, enumTable in required do
			RegisterEnum(enumName, enumTable)
		end
	else
		RegisterEnum(moduleScript.Name, required)
	end
end

local EnumService = {}

function EnumService.GetEnum(category)
	if not string.find(category, "Enum_") then
		category = "Enum_" .. category
	end
	
	return enums[category]
end

return EnumService
