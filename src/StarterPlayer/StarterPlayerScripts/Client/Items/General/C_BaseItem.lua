local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
-- SHARED
local BaseClass = Framework.GetShared("BaseClass")
local ItemSchema = Framework.GetShared("ItemSchema")
local ItemModel = Framework.GetShared("ItemModel")
local ItemSounds = Framework.GetShared("ItemSounds")
local ItemAnimator = Framework.GetShared("ItemAnimator")

local ItemDataTable = Framework.GetShared("ItemDataTable")
local AddSharedMethods = Framework.GetShared("BaseItemShared")

-- CLIENT
local Client = Framework.GetClient("Client")
local ClientItemActionManager = Framework.GetClient("ClientItemActionManager")

local BaseItem = {}
BaseItem.__index = BaseItem
BaseItem.ClassName = "C_BaseItem"
setmetatable(BaseItem, BaseClass)

function BaseItem.new(params)
	local self = BaseClass.new()
	setmetatable(self, BaseItem)
	
	self.Id = params.Id
	
	-- Unique identifier of item
	self.EntityHandle = params.EntityHandle
	
	self.SchemaEntry = ItemSchema.GetItemData(self.Id)

	if not self.SchemaEntry then
		return
	end
	
	-- TODO: Client's copy of item stats from inventory / storage data, which should be already loaded
	-- Initialize with client copy, copy of server-side data with state changes
	self.Schema = ItemSchema.GetItemStats(self.Id, true)
	
	self.DataTable = ItemDataTable.new(self)
	
	AddSharedMethods(self)
	self:AddSignals("ActionManagerInitialized")

	self.Player = Client.LocalPlayer
	self.Character = nil
	self.CharacterStats = nil
	self:SetCharacter(Client.Character)
	
	local itemModel = ItemSchema.GetItemModel(self.Id)
	if itemModel then
		self.ItemModel = ItemModel.new({
			CharacterModel = self.Character,
			Model = itemModel,
		})
	end
	
	self.Sounds = ItemSounds.new({
		ItemSoundData = self.Schema.Sounds,
		ItemModel = if self.ItemModel then self.ItemModel.Model else nil,
	})
	
	self.Animator = ItemAnimator.new(self)

	self.AutoCleanup = true
	
	return self
end

function BaseItem:ShouldSetActive(args)
	return true
end

function BaseItem:OnSetAsActive()
	return
end

function BaseItem:ShouldSetInactive(args)
	return true
end

function BaseItem:OnSetAsInactive()
	return
end

function BaseItem:ShouldDrop()
	return false
end

function BaseItem:OnDrop()
	return
end

function BaseItem:IsCurrentOwnerPlayer()
	return true
end

function BaseItem:LocallyUpdateItemStatesFromActionManager(actionManager)
	actionManager = actionManager or self:GetActionManager()
	
	self:AddConnections({
		ActionManagerListener = actionManager.Signals.ActionEvent:Connect(function(actionName, eventName, args)

			if eventName == "Started" then
				self.DataTable:SetState(actionName, true)
			elseif eventName == "Ended" then
				self.DataTable:SetState(actionName, false)
			end

		end)
	})
end

function BaseItem:SpawnItemModel()
	if not self.ItemModel then
		return
	end
	
	self.ItemModel:Equip()
end

function BaseItem:RemoveItemModel()
	if not self.ItemModel then
		return
	end
	
	self.ItemModel:Unequip()
end

function BaseItem:SetCharacter(character)
	if not character then
		character = Client.CharacterAddedSignal:Wait()
	end
	self.Character = character
end

function BaseItem:Destroy()
	local actionManager = self:GetActionManager()
	if actionManager then
		actionManager:Destroy()
	end

	self:BaseDestroy()
end

return BaseItem
