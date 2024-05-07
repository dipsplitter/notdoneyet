local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local DefaultCharacterAttributes = Framework.GetShared("DefaultCharacterAttributes")
local StringUtilities = Framework.GetShared("StringUtilities")

local AttributeTypeModules = {
	ClampedValue = Framework.GetShared("ClampedValue"),
	Property = Framework.GetShared("Value"),
}

-- Plural to attribute type
local AttributeTypeAliases = {
	ClampedValues = "ClampedValue",
	Properties = "Property",
}

local PropertySuffixDefaultValues = {
	ArmorAbsorption = 1,
}


local CharacterAttributesUtilities = {}

local function FormatCharacterAttributesDictionary(dict)
	for attributeName, info in pairs(dict) do
		local defaultEntry = DefaultCharacterAttributes[attributeName]

		if type(info) ~= "table" then
			dict[attributeName] = {
				Value = info,
				Type = CharacterAttributesUtilities.GetAttributeType(attributeName),
				Parent = if defaultEntry then defaultEntry.Parent else nil,
			}
		end

	end
end

function CharacterAttributesUtilities.CreateCharacterAttributeValues(attributesDictionary, valueCreatedCallback)
	local createdObjects = {}
	-- Attribute name: parent name
	-- Random order in loop means that some objects' parents won't exist yet, so we have to parent them afterwards
	local unparentedObjects = {}
	
	FormatCharacterAttributesDictionary(attributesDictionary)
	
	for attributeName, info in pairs(attributesDictionary) do
		local attributeType = info.Type
		if not attributeType then
			continue
		end
		
		if info.Value == false then
			continue
		end
		
		local valueObject = AttributeTypeModules[attributeType].new(info)
		createdObjects[attributeName] = valueObject
		
		local parent = info.Parent
		if parent then
			if createdObjects[parent] then
				createdObjects[parent][attributeName] = valueObject
			else
				unparentedObjects[attributeName] = parent
			end
		end
	end
	
	for attributeName, parent in pairs(unparentedObjects) do
		local parentObject = createdObjects[parent]
		local objectToParent = createdObjects[attributeName]
		
		if parentObject then
			parentObject[attributeName] = objectToParent
		else
			-- An object cannot exist without its parent!
			objectToParent:Destroy()
			createdObjects[attributeName] = nil
		end
		
	end
	
	return createdObjects
end

function CharacterAttributesUtilities.GetAttributeType(name)
	if DefaultCharacterAttributes[name] then
		return DefaultCharacterAttributes[name].Type or "ClampedValue"
	end

	for attributeName, info in pairs(DefaultCharacterAttributes) do
		-- FireResistance would be considered a Property because it has the same suffix as DamageResistance (maybe don't hard code? not a top priority)
		if StringUtilities.TitlesHaveSameLastWords(name, attributeName, 2) then
			return info.Type
		end
	end
	
	return "ClampedValue"
end

function CharacterAttributesUtilities.GetAttributeDefaultValue(name)
	local defaultEntry = DefaultCharacterAttributes[name]
	if defaultEntry then
		if defaultEntry.DefaultValue ~= nil then
			return defaultEntry.DefaultValue
		end
		
		return defaultEntry.Value 
			or defaultEntry.Max 
			or defaultEntry.Min 
			or 1
	end
	

	-- TODO: This is pretty bad
	for suffixName, defaultValue in pairs(PropertySuffixDefaultValues) do
		if StringUtilities.TitlesHaveSameLastWords(name, suffixName, 2) then
			return defaultValue
		end
	end
	
	for attributeName, info in pairs(DefaultCharacterAttributes) do
		-- FireDamageResistance would be considered a Property because it has the same suffix as DamageResistance
		if StringUtilities.TitlesHaveSameLastWords(name, attributeName, 2) then
			return info.Value
		end
	end
	
	return 1
end


function CharacterAttributesUtilities.CreateAttributeValue(valueName, ...)
	local attributeType = CharacterAttributesUtilities.GetAttributeType(valueName)
	
	local valueObject
	local args = {...}
	
	if #args == 0 then
		valueObject = AttributeTypeModules[attributeType].new(CharacterAttributesUtilities.GetAttributeDefaultValue(valueName))
	else
		valueObject = AttributeTypeModules[attributeType].new(...)
	end
	
	return valueObject
end

return CharacterAttributesUtilities