local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local ItemSchema = Framework.GetShared("ItemSchema")
local Signal = Framework.GetShared("Signal")

local ItemsStorage = Framework.GetServer("ItemsStorage")
local CharacterRegistry = Framework.GetServer("CharacterRegistry")
local BaseItem = Framework.GetServer("BaseItem")

local Players = game:GetService("Players")

local NETWORK = Framework.Network()
local ItemCreateEvent = NETWORK.Event("ItemCreate")
local ItemActionEvent = NETWORK.Event("ItemAction")

local itemsStorage = {}

local ItemsService = {
	ItemCreated = Signal.new(),
}

local function ShouldCreateItem(id, character)
	local class = character.Class
	
	-- For custom NPCs
	if class == "Custom" or class == "None" then
		return true
	end
	
	local itemData = ItemSchema.GetItemData(id)
	local usedByList = itemData.UsedBy
	if not usedByList[class] then
		return false
	end
	
	return true
end

local function GetSlotName(item, character)
	local class = character.Class
	local schemaEntry = item.SchemaEntry
	
	local customClassSlots = schemaEntry.ClassSlot
	if customClassSlots and customClassSlots[class] then
		return customClassSlots[class]
	end
	
	return schemaEntry.DefaultSlot
end

local function AddItemToCharacterInventory(item, character)
	
end

--[[
	Id: as seen in Item Schema
	Character: item's initial owner
]]
function ItemsService.Create(params)
	local characterObject = CharacterRegistry.GetCharacterFromModel(params.Character)
	
	if not params.IgnoreRestrictions and not ShouldCreateItem(params.Id, characterObject) then
		warn(`Unable to create item {params.Id} for {params.Character.Name}`)
		return
	end
	
	local itemModule = ItemSchema.GetItemModule(params.Id)
	if not itemModule then
		-- TODO: Add dynamic item creation (maybe never)
		return
	end
	
	debug.setmemorycategory("ServerItem")
	params.EntityHandle  = ItemsStorage.CurrentItemIndex
	local baseItem = BaseItem.new(params)
	if not baseItem or not getmetatable(baseItem) then
		return
	end
	
	local item = itemModule.new(baseItem)
	
	ItemsStorage[ItemsStorage.CurrentItemIndex] = item
	ItemsStorage.CurrentItemIndex += 1
	
	if item.Player then
		-- TODO: Pull from the client's inventory
		ItemCreateEvent:Fire({
			Id = item.EntityHandle,
			SchemaId = ItemSchema.GetSchemaId(item.Id)
		}, item.Player)
	end
	
	ItemsService.ItemCreated:Fire(item)
	
	local slotToAdd = GetSlotName(item, characterObject)
	characterObject:GetInventory():AddItems({[slotToAdd] = item})
	
	return item
end

ItemActionEvent:Connect(function(args, player)
	local itemId = args.EntityHandle
	local item = ItemsStorage[itemId]
	
	if not item then
		return
	end
	
	if item.Player ~= player then
		return
	end
	
	local actionManager = item:GetActionManager()
	
	local actionName = actionManager.ActionIdentifierMap:Deserialize(args.ActionName)
	local eventName = actionManager:GetAction(actionName).EventIdentifierMap:Deserialize(args.EventName)

	args.ActionName = actionName
	args.EventName = eventName
	
	actionManager:StartActionEventFromClientRequest(args)
end)

return ItemsService
