local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local Hotbar = Framework.GetShared("Hotbar")

local ItemInventory = {}
ItemInventory.__index = ItemInventory
ItemInventory.ClassName = "ItemInventory"
setmetatable(ItemInventory, BaseClass)

function ItemInventory.new(params)
	local self = BaseClass.new()
	setmetatable(self, ItemInventory)
	
	if params then
		self:InjectObject("InputHandler", params.InputHandler)
	end
	
	-- Items that can be accessed with keybinds
	self.Hotbars = {
		Main = Hotbar.new({
			Name = "Main",
			InputHandler = self.InputHandler,
		}),
	}

	-- Items that are not in the hotbar
	self.Storage = {}

	-- Contains every item
	self.ItemsList = {}
	
	self.AutoCleanup = true
	
	return self
end

function ItemInventory:SetInputHandler(inputHandler)
	self.InputHandler = inputHandler
	for name, hotbar in pairs(self.Hotbars) do
		hotbar:SetInputHandler(inputHandler)
	end
end

function ItemInventory:AddHotbar(name, hotbarParams)
	self[name] = Hotbar.new(hotbarParams)
end

function ItemInventory:ItemExists(item)
	return self.ItemsList[item]
end

function ItemInventory:AddItemsToHotbar(itemList, hotbarName)
	hotbarName = hotbarName or "Main"
	
	for slotName, item in pairs(itemList) do
		self.ItemsList[item] = true
		item:AddExternalReference(self.ItemsList)
	end
	
	self.Hotbars[hotbarName]:AddItems(itemList)
end

function ItemInventory:AddItems(itemList)
	for slotName, item in pairs(itemList) do
		self.ItemsList[item] = true
		item:AddExternalReference(self.ItemsList)
	end
	
	-- Auto-fill an empty hotbar
	for hotbarName, hotbar in pairs(self.Hotbars) do
		if #hotbar:GetVacantSlots() == 0 then
			continue
		end
		
		hotbar:AddItems(itemList)
	end
end

function ItemInventory:SetHotbarSlots(slotsTable, hotbarName)
	hotbarName = hotbarName or "Main"
	
	self.Hotbars[hotbarName]:SetSlots(slotsTable)
end

function ItemInventory:ForgetAll()
	for k, v in pairs(self) do
		if not Framework.IsObject(self[k]) then
			table.clear(self[k])
		end
	end
end

function ItemInventory:ForgetAllItems()
	table.clear(self.ItemsList)
	for name, hotbar in self.Hotbars do
		hotbar:ForgetAllItems()
	end
end

function ItemInventory:Destroy()
	self:ForgetAllItems()
	self:ForgetAll() 
	self:BaseDestroy()
end

return ItemInventory
 