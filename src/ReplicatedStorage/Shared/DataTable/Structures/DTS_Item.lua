local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local ItemPropertyDefaultTypes = Framework.GetShared("ItemPropertyDefaultTypes")
local ItemValueDefaultTypes = Framework.GetShared("ItemValueDefaultTypes")
local TableUtilities = Framework.GetShared("TableUtilities")
local ItemSchema = Framework.GetShared("ItemSchema")
local DECLARE = Framework.GetShared("DT_NetworkedProperties").DeclareProperty

-- TODO: Finish this! Should be recursive
local function MergeWithParentNetworkTable(properties)
	local networkTable = properties.NETWORK_TABLE
	if not networkTable then
		return
	end
	
	local parent = networkTable.PARENT
	while parent do
		local itemStats = ItemSchema.GetItemStats(parent, true)  
	end
	
	local parentItemName = properties.NETWORK_TABLE.PARENT
	
	local itemStats = ItemSchema.GetItemStats(parentItemName, true)
	
	local parentNetworkTable = itemStats.NETWORK_TABLE
	
	return TableUtilities.DeepMerge(parentNetworkTable, properties.NETWORK_TABLE.PROPERTIES)
end

local function CreateItemValuesDTS(properties)
	local valueTypes = {}
	
	local values = properties.Base.Values
	if not values then
		return
	end
	local flattenedBaseValues = TableUtilities.FlattenWithArrayPaths(values)
	
	local networkTable = properties.NETWORK_TABLE or {}
	local networkedValues = networkTable.VALUES or {}
	local blacklist = networkTable.BLACKLISTED_VALUES
	
	for valueName, data in values do
		if blacklist and blacklist[valueName] then
			continue
		end
		
		local dataType
		
		-- Don't use the inferred type. We explicitly declared what type to use
		local explicitType = networkedValues[valueName]
		if explicitType then
			dataType = networkedValues[valueName]
		else 
			dataType = ItemValueDefaultTypes[valueName]
		end
		
		valueTypes[`{valueName}.Value`] = dataType
		
		-- For clamped values, we have to make entries for the Max and Min
		if data.Max or data.Min then
			valueTypes[`{valueName}.Max`] = dataType
			valueTypes[`{valueName}.Min`] = dataType
		end
	end
	
	return valueTypes
end

local function CreateItemPropertiesDTS(properties)
	local types = {}
	
	-- Array paths are more performant than concatenation followed by splitting
	local flattenedBaseProperties = TableUtilities.FlattenWithArrayPaths(properties.Base)

	for pathToStat, value in flattenedBaseProperties do
		-- Skip values!
		if pathToStat[1] == "Values" then
			continue
		end
		
		local finalKey = pathToStat[#pathToStat]

		local defaultType = ItemPropertyDefaultTypes[finalKey]
		
		if not defaultType then
			continue
		end
		
		-- Skip type mismatches (e.g. default key is number type but item declared it as string)
		local valueTypeName = typeof(value)
		if valueTypeName ~= defaultType.TypeName then
			continue
		end
		
		-- Convert to string 
		types[TableUtilities.ArrayToStringPath(pathToStat)] = defaultType
	end
	
	local networkTable = properties.NETWORK_TABLE or {}
	local networkedProperties = networkTable.PROPERTIES
	
	if networkedProperties then
		networkedProperties = TableUtilities.Flatten(networkedProperties)
		types = TableUtilities.Reconcile(types, networkedProperties)
	end
	
	-- Remove blacklisted property keys
	local propertyBlacklist = networkTable.BLACKLISTED_PROPERTIES
	if propertyBlacklist then
		
		local flattenedBlacklist = TableUtilities.Flatten(propertyBlacklist)
		for stringKey in flattenedBlacklist do
			if types[stringKey] then
				types[stringKey] = nil
			end
		end
		
	end
	
	return types
end

local function CreateItemStatesDTS(properties, itemData)
	local structureTable = {Active = DECLARE("Boolean")}

	-- Manually add equip and unequip; we shouldn't rely on action managers
	if itemData.ItemType == "Tool" then
		structureTable.Equip = DECLARE("Boolean")
		structureTable.Unequip = DECLARE("Boolean")
	end

	local customStates = properties.States
	if customStates then
		for stateName, customType in customStates do
			structureTable[stateName] = DECLARE("Boolean")
		end
	end

	for actionName in properties.Base.Activations do
		structureTable[actionName] = DECLARE("Boolean")
	end

	return structureTable
end

-- Item name: {properties DT, values DT}
local DTS_Item = {
	Name = "Item",
	Cache = {},
}

for itemName, data in ItemSchema.Items do
	local itemProperties = ItemSchema.GetItemStats(itemName, true)
	local itemData = ItemSchema.GetItemData(itemName)
	
	DTS_Item.Cache[itemName] = {
		Properties = CreateItemPropertiesDTS(itemProperties),
		Values = CreateItemValuesDTS(itemProperties),
		States = CreateItemStatesDTS(itemProperties, itemData)
	}
end

table.freeze(DTS_Item)
return DTS_Item
