local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local ItemSchema = Framework.GetShared("ItemSchema")

local ClientItemsStorage = Framework.GetClient("ClientItemsStorage")
local Client = Framework.GetClient("Client")
local ClientInventory = Client.ItemInventory

local Players = game:GetService("Players")

local NETWORK = Framework.Network()
local ItemCreateEvent = NETWORK.Event("ItemCreate")
local ItemActionEvent = NETWORK.Event("ItemAction")

local itemsStorage = {}

local function GetSlotName(item)
	local class = Client.Class
	local schemaEntry = item.SchemaEntry

	local customClassSlots = schemaEntry.ClassSlot
	if customClassSlots and customClassSlots[class] then
		return customClassSlots[class]
	end

	return schemaEntry.DefaultSlot
end

local ClientItemsService = {}

function ClientItemsService.CreateItem(entityHandle, itemModule, params)
	local item = itemModule.new(params)
	ClientItemsStorage[entityHandle] = item
	
	local slotName = GetSlotName(item)
	ClientInventory:AddItems({[slotName] = item})
end

ItemCreateEvent:Connect(function(args)
	local entityHandle = args.Id
	local storageId = args.StorageId
	local schemaId = args.SchemaId
	local isDestroying = args.Destroy
	
	if isDestroying then
		local item = ClientItemsStorage[entityHandle]
		if item then
			item:Destroy()
			ClientItemsStorage[entityHandle] = nil
		end
	end
	
	if storageId then
		
	end
	
	if schemaId then
		-- The item does not exist in our storage, so create a blank copy of a template
		local itemId = ItemSchema.GetItemIdFromSchemaId(schemaId)
		
		local itemModule = ItemSchema.GetItemModule(itemId)
		if not itemModule then
			return
		end

		local creationParams = {
			EntityHandle = entityHandle,
			Id = itemId,
		}
		ClientItemsService.CreateItem(entityHandle, itemModule, creationParams)

	end
end)

ItemActionEvent:Connect(function(args)
	local entityHandle = args.EntityHandle
	local item = ClientItemsStorage[entityHandle]
	if not item then
		return
	end
	
	local actionManager = item:GetActionManager()

	local actionName = actionManager.ActionIdentifierMap:Deserialize(args.ActionName)
	local eventName = actionManager:GetAction(actionName).EventIdentifierMap:Deserialize(args.EventName)

	args.ActionName = actionName
	args.EventName = eventName

	actionManager:StartActionEventFromClientRequest(args)
end)

return ClientItemsService
