local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local UiFramework = Framework.GetShared("UiFramework")
local GetSchemeGlobal = Framework.GetShared("GetSchemeGlobal")

local HotbarUi = UiFramework.GetElement("Hotbar")

local Client = Framework.GetClient("Client")
local Hotbars = Client.ItemInventory.Hotbars

local HotbarsFrame = UiFramework.GetScreenGui("Hud"):FindFirstChild("Hotbars")

local specialSlots = {
	Primary = UiFramework.GetResource("PrimarySlot")
}

local ItemsHotbar = {}
ItemsHotbar.__index = ItemsHotbar

function ItemsHotbar.new(params)
	local self = {
		Hotbar = nil,
	}
	
	setmetatable(self, ItemsHotbar)

	return self
end

function ItemsHotbar:OnHudInitialize()
	if Hotbars.Main and not self.Hotbar then
		self.Hotbar = HotbarUi.new(HotbarsFrame.ItemsHotbar, Hotbars.Main)
		
		self.Hotbar.GetResourceForSlot = function(self, slotName)
			return specialSlots[slotName]
		end
	end
	
	if self.Hotbar then
		self.Hotbar:OnHudInitialize()
	end
end

function ItemsHotbar:OnClientDeath()
	if self.Hotbar then
		self.Hotbar:OnClientDeath()
	end
end

local UiComponent_ItemsHotbar = {}

function UiComponent_ItemsHotbar.Create()
	local component = ItemsHotbar.new()
	UiComponent_ItemsHotbar.Object = component
	return component
end

function UiComponent_ItemsHotbar.OnSchemeReload()

end

return UiComponent_ItemsHotbar
