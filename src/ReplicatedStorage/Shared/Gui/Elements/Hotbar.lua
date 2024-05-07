local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local UiFramework = Framework.GetShared("UiFramework")
local HotbarSlot = UiFramework.GetElement("HotbarSlot")

local Client = Framework.GetClient("Client")
local Hotbars = Client.ItemInventory.Hotbars

local baseHotbarSlotResource = UiFramework.GetResource("HotbarSlot")
local baseHotbarSlot = UiFramework.CreateComponent(baseHotbarSlotResource)

local UiHotbar = {}
UiHotbar.__index = UiHotbar

function UiHotbar.new(parentFrame, hotbarObject)
	local self = {
		ClientHotbar = hotbarObject,
		Parent = parentFrame,
		Slots = {},
	}
	setmetatable(self, UiHotbar)
	
	self.ClientHotbar:ConnectTo("SlotSetActive", function(slot)
		self:OnSlotSetActive(slot)
	end)
	
	self.ClientHotbar:ConnectTo("SlotSetInactive", function(slot)
		self:OnSlotSetInactive(slot)
	end)
	
	self.ClientHotbar:ConnectTo("SlotAdded", function(slot)
		local slotName = slot.Name
		
		if self.Slots[slotName] then
			return
		end
		
		self:CreateSlot(slotName)
	end)
	
	return self
end

function UiHotbar:GetResourceForSlot(slotName)
	return nil
end

function UiHotbar:CreateSlot(slotName)
	if self.Slots[slotName] then
		return
	end
	
	local slot = self.ClientHotbar.Slots[slotName]
	
	local item = slot.Item

	local layoutOrder = slot.Id
	
	-- TODO: Cache resources and components
	local resource = self:GetResourceForSlot(slotName)
	if not resource then
		resource = baseHotbarSlotResource
	end
	
	local uiObject = UiFramework.CreateComponent(resource):Clone()
	uiObject.Parent = self.Parent
	
	local hotbarSlot = HotbarSlot.new({
		Ui = uiObject,
		Resource = resource,
		Slot = slot,
	})
	
	self.Slots[slotName] = hotbarSlot
	return hotbarSlot
end

function UiHotbar:InitializeSlots()
	for slotName in self.ClientHotbar.Slots do
		self:CreateSlot(slotName)
	end
end

function UiHotbar:GetCorrespondingSlotUi(slot)
	local slotId = slot.Id
	
	for slotName, slotObject in self.Slots do
		if slotObject.Ui.LayoutOrder ~= slotId then
			continue
		end

		return slotObject, slotId
	end
end

function UiHotbar:OnSlotSetInactive(slot)
	local slotUi = self:GetCorrespondingSlotUi(slot)

	if not slotUi then
		return
	end

	slotUi:OnSetInactive()
end

function UiHotbar:OnSlotSetActive(slot)
	local slotUi = self:GetCorrespondingSlotUi(slot)
	
	if not slotUi then
		return
	end
	
	slotUi:OnSetActive()
end

function UiHotbar:OnHudInitialize()
	self:InitializeSlots()
end

function UiHotbar:CleanupAll()
	for slotName, object in self.Slots do
		object:Destroy()
	end
	table.clear(self.Slots)
end

function UiHotbar:OnClientDeath()
	self:CleanupAll()
end

return UiHotbar
