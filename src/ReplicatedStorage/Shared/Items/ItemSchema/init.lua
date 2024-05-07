local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local TableUtilities = Framework.GetShared("TableUtilities")
local EnumService = Framework.GetShared("EnumService")
local AssetService = Framework.GetShared("AssetService")

local ItemTypes = EnumService.GetEnum("Enum_ItemTypes")

local RunService = game:GetService("RunService")
local IsClient = RunService:IsClient()
local IsServer = RunService:IsServer()

local Items = script.Parent
local MasterList = require(script.ItemMasterList)

--[[
	Client and server modules for items are stored in ReplicatedStorage.Client and ServerStorage
	Item stats, models, and other related effects are stored in ReplicatedStorage.Shared
]]

local schemaIdLookupTable = {}
local ItemSchema = {}
ItemSchema.Items = MasterList

for itemId, itemInfo in MasterList do
	schemaIdLookupTable[itemInfo.SchemaId] = itemId
end

function ItemSchema.GetItemIcon(itemName)
	local imageData = AssetService.Images(`Items.{itemName}`)
	return imageData.Id
end

function ItemSchema.GetItemData(itemName)
	return MasterList[itemName]
end

function ItemSchema.GetItemModule(itemName)
	if not MasterList[itemName] then
		return
	end
	
	local module
	if IsClient then
		module = Framework.GetClient(itemName, false)
	elseif IsServer then
		module = Framework.GetServer(itemName, false)
	end
	
	if not module then
		module = Framework.GetShared(itemName)
	end
	
	return module
end

function ItemSchema.GetItemStats(itemName, readOnly)
	if not MasterList[itemName] then
		return
	end

	if readOnly then
		local properties = Framework.GetShared(`P_{itemName}`)
		return properties
	end
	return TableUtilities.DeepCopy(Framework.GetShared(itemName))
end

function ItemSchema.GetItemModel(itemName)
	if not MasterList[itemName] then
		return
	end
	
	local moduleScript = Items:FindFirstChild(`P_{itemName}`, true)
	
	if moduleScript then
		return moduleScript:FindFirstChildWhichIsA("Model")
	end
end

function ItemSchema.GetDisplayName(itemInternal)
	if not MasterList[itemInternal] then
		return
	end
	
	return MasterList[itemInternal].DisplayName
end

function ItemSchema.GetItemIdFromSchemaId(schemaId)
	return schemaIdLookupTable[schemaId]
end

function ItemSchema.GetSchemaId(itemName)
	return MasterList[itemName].SchemaId
end

table.freeze(ItemSchema)
return ItemSchema
