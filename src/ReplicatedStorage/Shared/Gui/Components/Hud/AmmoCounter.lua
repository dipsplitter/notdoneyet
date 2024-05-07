local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local UiFramework = Framework.GetShared("UiFramework")
local HudUtilities = Framework.GetShared("HudUtilities")
local GetSchemeGlobal = Framework.GetShared("GetSchemeGlobal")
local ItemSchema = Framework.GetShared("ItemSchema")

local Client = Framework.GetClient("Client")

local RESOURCE = UiFramework.GetResource("AmmoCounter")
local ValueBar = UiFramework.GetElement("ValueBar")

local ammoCounterUi = UiFramework.CreateComponent(RESOURCE)

local function SetValueLabels(object, item)
	local itemValues = item:GetValueManager()
	
	object:SetVisible({
		ReloadedValueLabel = false,
		ReserveValueLabel = false
	})
	if not itemValues then
		return
	end
	
	local reloadedSignal = itemValues:GetChangedSignal("Clip")
	local reserveSignal = itemValues:GetChangedSignal("ReserveAmmo")
	
	if reloadedSignal then
		UiFramework.SetText("%Loaded%", itemValues:Get("Clip"))
		object:SetVisible("ReloadedValueLabel", true)
		
		reloadedSignal:Connect(function(t, old, new)
			UiFramework.SetText("%Loaded%", new)
		end)
	end
	
	if reserveSignal then
		UiFramework.SetText("%Reserve%", itemValues:Get("ReserveAmmo"))
		object:SetVisible("ReserveValueLabel", true)
		
		reserveSignal:Connect(function(t, old, new)
			UiFramework.SetText("%Reserve%", new)
		end)
	end
end

local AmmoCounter = {}
AmmoCounter.__index = AmmoCounter

function AmmoCounter.new(params)
	local self = {
		Object = ValueBar.new(params)
	}
	setmetatable(self, AmmoCounter)

	return self
end

function AmmoCounter:OnHudInitialize()
	UiFramework.SetText("%EquippedItemName%", "Unarmed")
	self.Object:SetVisible({
		ReloadedValueLabel = false,
		ReserveValueLabel = false
	})
	
	self.Object.Ui.Visible = true
	
	self.EquipConnection = Client.ItemEquipped:Connect(function(item)
		UiFramework.SetText("%EquippedItemName%", ItemSchema.GetDisplayName(item.Id))
		
		SetValueLabels(self.Object, item)
	end)
	
	self.UnequipConnection = Client.ItemUnequipped:Connect(function(unequipped, new)
		if not new then
			UiFramework.SetText("%EquippedItemName%", "Unarmed")
			
			self.Object:SetVisible({
				ReloadedValueLabel = false,
				ReserveValueLabel = false
			})
		end
	end)
end

function AmmoCounter:OnClientDeath()
	self.Object.Ui.Visible = false
	
	self.EquipConnection:Disconnect()
	self.EquipConnection = nil
	
	self.UnequipConnection:Disconnect()
	self.UnequipConnection = nil
end

local UiComponent_AmmoCounter = {}

function UiComponent_AmmoCounter.Create()
	HudUtilities.SetParent(ammoCounterUi, RESOURCE)

	local component = AmmoCounter.new({
		Resource = RESOURCE,
		Ui = ammoCounterUi,
	})
	UiComponent_AmmoCounter.Object = component
	return component
end

function UiComponent_AmmoCounter.OnSchemeReload()

end

return UiComponent_AmmoCounter
