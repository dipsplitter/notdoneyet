local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local ItemSchema = Framework.GetShared("ItemSchema")
local ItemModel = Framework.GetShared("ItemModel")
local ItemSounds = Framework.GetShared("ItemSounds")
local ItemAnimator = Framework.GetShared("ItemAnimator")

local TableUtilities = Framework.GetShared("TableUtilities")

local AddSharedMethods = Framework.GetShared("BaseItemShared")

local ItemDataTable = Framework.GetShared("ItemDataTable")

local NETWORK = Framework.Network()
local ItemCreateEvent = NETWORK.Event("ItemCreate")

local ItemsStorage = Framework.GetServer("ItemsStorage")

local Players = game:GetService("Players")

local BaseItem = {}
BaseItem.__index = BaseItem
BaseItem.ClassName = "S_BaseItem"
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
	
	self.Schema = ItemSchema.GetItemStats(self.Id, true)

	self:AddSignals("CharacterChanged", "ActionManagerInitialized")
	
	self.Player = nil
	self.Character = nil
	local success = self:SetCharacter(params.Character)
	if not success then
		return
	end
	
	self.DataTable = ItemDataTable.new(self)
	
	AddSharedMethods(self)

	local itemModel = ItemSchema.GetItemModel(self.Id)
	if itemModel then
		self.ItemModel = ItemModel.new({
			CharacterModel = self.Character,
			Model = itemModel,
		})
	end
	
	self.Sounds = ItemSounds.new({
		Character = self.Character,
		ItemSoundData = self:GetSoundData(),
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
	return self.Player ~= nil
end

function BaseItem:GetCurrentOwner()
	return self.Character
end

function BaseItem:OnCharacterDeath()
	if self:ShouldDrop() then
		self:OnDrop()
	else
		self:Destroy()
	end
end

function BaseItem:IsValidCharacter(character)
	if not character then
		return false
	end
	local humanoid = character:FindFirstChild("Humanoid")
	return humanoid.Health > 0
end

function BaseItem:SetCharacter(character)
	self.Character = character
	self.Player = Players:GetPlayerFromCharacter(self.Character)
	
	self:FireSignal("CharacterChanged", character)
	
	if not self:IsValidCharacter(character) then
		self:OnCharacterDeath()
		return false
	end
	
	return true
end

function BaseItem:GetCharacterOwner()
	return self.Character
end

function BaseItem:UpdateItemStatesFromActionManager(actionManager)
	if not actionManager then
		return
	end
	
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

function BaseItem:DestroyItem()
	self.DataTable:Destroy()
	
	if self.Player then
		ItemCreateEvent:Fire({
			Id = self.EntityHandle,
			Destroy = true,
		}, self.Player)
		
		ItemsStorage[self.EntityHandle] = nil
	end

	local actionManager = self:GetActionManager()
	if actionManager then
		actionManager:Destroy()
	end

	BaseClass.Destroy(self)
end
BaseItem.Destroy = BaseItem.DestroyItem

return BaseItem
