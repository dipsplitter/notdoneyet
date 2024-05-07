local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local TableUtilities = Framework.GetShared("TableUtilities")
local ItemProperties = Framework.GetShared("ItemProperties")

local Client = Framework.GetClient("Client")
local BaseItem = Framework.GetClient("BaseItem")
local ClientItemActionManager = Framework.GetClient("ClientItemActionManager")

--[[
	A tool is an item that has equip and unequip functionality and activation behaviors
]]
local BaseTool = {}
BaseTool.__index = BaseTool
BaseTool.ClassName = "C_BaseTool"
setmetatable(BaseTool, BaseItem)

function BaseTool.new(params)
	local self = BaseItem.new(params)
	setmetatable(self, BaseTool)
	
	self.ActionManager = ClientItemActionManager.new({
		EntityHandle = self.EntityHandle
	})
	
	self:CreateActivationsFromProperties()
	self:CreateBaseActions()
	self:FireSignal("ActionManagerInitialized")

	self:LocallyUpdateItemStatesFromActionManager()
		
	return self
end

function BaseTool:CreateActivationsFromProperties(statsTable)
	statsTable = statsTable or self.Schema.Base
	local actionManager = self:GetActionManager()

	for activationName, activationInfo in statsTable.Activations do
		if actionManager:GetAction(activationName) then
			continue
		end
		
		local activationInfoCopy = TableUtilities.DeepCopy(activationInfo)
		
		if activationInfoCopy.CooldownTime then
			activationInfoCopy.GetCooldownTime = function()
				return statsTable.Activations[activationName].CooldownTime
			end
		end
		
		activationInfoCopy.ContextId = self.Id .. activationName
		
		actionManager:CreateActionFromData(activationName, activationInfoCopy)
	end
end

function BaseTool:CreateBaseActions()
	self:CreateEquipAction()
	self:CreateUnequipAction()
end

function BaseTool:ShouldSetActive(params)
	return not self:GetState("Active")
end

function BaseTool:OnSetAsActive(params)
	self:GetActionManager():GetAction("Equip"):StartEvent("Started", { Replicate = true })
end

function BaseTool:ShouldSetInactive(params)
	return self:GetState("Active")
end

function BaseTool:OnSetAsInactive(params)
	local actionManager = self:GetActionManager()
	local unequipAction = actionManager:GetAction("Unequip")
	
	actionManager:GetActionEndedSignal("Unequip"):Once(function()
		-- This callback should equip the next item
		if params.Callback then
			params.Callback()
		end
	end)
	unequipAction:StartEvent("Started", { Replicate = true })
end

function BaseTool:CreateEquipAction()
	local actionData = {
		SuccessEvaluators = {
			Started = function()
				return not self:GetState("Active")
			end,
		},

		GetCooldownTime = function()
			return self:GetProperty("EquipSpeed") or 0
		end,

		CooldownModifiers = {
			EquipSpeed = function()
				-- TODO: Make character class and also actually implement CharacterStats
				return 1
				-- return self.CharacterStats:GetAttribute("EquipSpeedMultiplier")
			end,
		},

		StartManually = true
	}
	
	local actionManager = self:GetActionManager()
	actionManager:CreateActionFromData("Equip", actionData)
	-- Initialize
	actionManager:Bind("Equip")
	self:ConnectEquip()
end

function BaseTool:CreateUnequipAction()
	local actionData = {

		SuccessEvaluators = {
			Started = function()
				return self:GetState("Active")
			end,
		},
		
		GetCooldownTime = function()
			return self:GetProperty("UnequipSpeed") or 0
		end,
		
		CooldownModifiers = {
			UnequipSpeed = function()
				-- TODO: Make character class and also actually implement CharacterStats
				return 1
				-- return self.CharacterStats:GetAttribute("UnequipSpeedMultiplier")
			end,
		},
		
		StartManually = true
	}
	
	local actionManager = self:GetActionManager()
	actionManager:CreateActionFromData("Unequip", actionData)
end

function BaseTool:ConnectEquip()
	self:AddConnections({
		Equip = self:GetActionManager():GetActionStartedSignal("Equip"):Connect(function()
			self:Equip()
		end)
	})
end

function BaseTool:ConnectUnequip()
	self:AddConnections({
		Unequip = self:GetActionManager():GetActionStartedSignal("Unequip"):Connect(function()
			self:Unequip()
		end)
	})
end

function BaseTool:Equip()
	local actionManager = self:GetActionManager()
	
	actionManager:Unbind("Equip")
	self:CleanupConnection("Equip")
	
	self:SetState("Active", true)

	self:SpawnItemModel()
	
	if not ItemProperties.EquipsInstantly(self) then
		self:AddConnections({
			EquipFinished = actionManager:GetActionEndedSignal("Equip"):Connect(function()
				self:OnEquip()
			end)
		})
	else
		self:OnEquip()
	end
	
	actionManager:Bind("Unequip")
	self:ConnectUnequip()
end

function BaseTool:OnEquip()
	
end

function BaseTool:Unequip()
	local actionManager = self:GetActionManager()
	
	actionManager:Cancel("Equip")
	actionManager:Unbind("Unequip")
	self:CleanupConnection("Unequip")
	
	self:SetState("Active", false)

	self:RemoveItemModel()
	
	if not ItemProperties.UnequipsInstantly(self) then
		self:AddConnections({
			UnequipFinished = actionManager:GetActionEndedSignal("Unequip"):Connect(function()
				self:OnUnequip()
			end)
		})
	else
		self:OnUnequip()
	end
	
	actionManager:Bind("Equip")
	self:ConnectEquip()
end

function BaseTool:OnUnequip()
	
end

return BaseTool