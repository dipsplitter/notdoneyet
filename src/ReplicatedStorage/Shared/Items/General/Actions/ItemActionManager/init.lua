local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local ActionCreator = Framework.GetShared("ActionCreator")
local ActionManagerListenerSignals = Framework.GetShared("ActionManagerListenerSignals")
local IdentifierMap = Framework.GetShared("IdentifierMap")
local BufferUtilities = Framework.GetShared("BufferUtilities")

local Client = Framework.GetClient("Client")

local CharacterRegistry = Framework.GetServer("CharacterRegistry")

local RunService = game:GetService("RunService")
local IsClient = RunService:IsClient()
local IsServer = RunService:IsServer()

local ItemActionManager = {}
ItemActionManager.__index = ItemActionManager
ItemActionManager.ClassName = "ItemActionManager"
setmetatable(ItemActionManager, BaseClass)

function ItemActionManager.new(params)
	local self = BaseClass.new()
	setmetatable(self, ItemActionManager)
	
	self.Actions = {}
	self.ListenerSignals = ActionManagerListenerSignals.new()
	self.CurrentActions = {}
	
	self.IsNetworked = false
	
	self.ActionIdentifierMap = IdentifierMap.new()
	
	self:InjectObject("Item", params.Item)
	
	self:SetupInputHandler(params.InputHandler) -- All action input contexts will listen to this handler

	self:AddSignals("ActionStarted", "ActionEnded", "ActionEvent")
	
	-- Action objects should be pre-created
	
	for actionName, actionObject in pairs(params.Actions or {}) do
		self:AddAction(actionObject, actionName)
	end
	
	self.AutoCleanup = true
	
	return self
end

-- Call when item ownership changes
function ItemActionManager:SetupInputHandler(inputHandler)
	if inputHandler then
		self:SetNewInputHandler(inputHandler)
		return
	end
	
	if IsClient then
		inputHandler = Client.GetInputHandler()
	elseif IsServer and not self.Item:IsCurrentOwnerPlayer() then -- Disable input if the item's owned by a player
		inputHandler = CharacterRegistry.GetCharacterFromModel(self.Item.Character):GetInputHandler()
	end
	
	self:SetNewInputHandler(inputHandler)
end

function ItemActionManager:SetNewInputHandler(inputHandler)
	self:InjectObject("InputHandler", inputHandler)
	
	for actionName, actionObject in pairs(self.Actions) do
		actionObject:LinkInputContextToInputHandler(inputHandler)
	end
end

-- Wrappers for the listener signal table
function ItemActionManager:GetActionStartedSignal(actionName)
	return self.ListenerSignals:GetActionStartedSignal(actionName)
end

function ItemActionManager:GetActionEndedSignal(actionName)
	return self.ListenerSignals:GetActionEndedSignal(actionName)
end

function ItemActionManager:GetActionEventSignal(actionName, eventName)
	return self.ListenerSignals:GetActionEventSignal(actionName, eventName)
end

function ItemActionManager:GetInputBeganSignal(actionName)
	return self.ListenerSignals:GetInputBeganSignal(actionName)
end

--[[
	Data should contain all constructor params for the requested action class
	
	ActionType: Specifies which action class to create; nil = Base
]]
function ItemActionManager:CreateActionFromData(name, data)
	data.InputHandler = self.InputHandler
	
	local newAction = ActionCreator.Create(name, data)
	self:AddAction(newAction)
	
	return newAction
end

function ItemActionManager:GetAction(name)
	return self.Actions[name]
end

function ItemActionManager:StartActionEvent(info)
	local action = self:GetAction(info.ActionName)
	if not action then
		return
	end

	action:StartEvent(info.EventName or "Started", info)
end

-- Replicates if the action manager is networked, otherwise starts normally
function ItemActionManager:ReplicateActionEvent(info)
	local action = self:GetAction(info.ActionName)
	if not action then
		return
	end
	
	if self.IsNetworked then
		self:StartActionEventWithReplication(info)
	else
		action:StartEvent(info.EventName or "Started", info)
	end
end

function ItemActionManager:AddInputListenerForAction(actionName)
	local action = self:GetAction(actionName)
	self:AddConnections({
		-- Starts the action event when the action detects an input
		[actionName .. "InputBegan"] = action:GetSignal("InputBegan"):Connect(function(inputs, info)
			self.ListenerSignals:FireSignal(action.ActionName, "InputBegan", info)
			-- If there's no flags, don't do anything; let other scripts handle the input
			if not info then
				return
			end
			info.Inputs = inputs

			if not info.Event or not info.AutoTrigger then
				return
			end
			local eventStartArgs = {Inputs = inputs}

			if info.Replicate then
				eventStartArgs.Replicate = true
			end
			
			action:StartEvent(info.Event, eventStartArgs)
		end),
	})
end

function ItemActionManager:DisableInputListenerForAction(actionName)
	local action = self:GetAction(actionName)
	action:DisableInput()
end

function ItemActionManager:DisableAllInputListeners()
	for actionName, actionObject in pairs(self.Actions) do
		self:DisableInputListenerForAction(actionName)
	end
end

function ItemActionManager:EnableAllInputListeners()
	for actionName, actionObject in pairs(self.Actions) do
		self:AddInputListenerForAction(actionName)
	end
end

function ItemActionManager:AddConnectionsForAction(actionName, actionObject)
	self:AddConnections({
		[actionName .. "Event"] = actionObject:ConnectTo("Event", function(eventName, args)
			if eventName == "StartedSuccessfully" then
				
				self.CurrentActions[actionName] = 1
				self:FireSignal("ActionStarted", actionObject.ActionName, args)
				
			elseif eventName == "EndedSuccessfully" then
				
				self.CurrentActions[actionName] = nil
				self:FireSignal("ActionEnded", actionObject.ActionName, args)
				
			end

			-- Fire generic event
			self:FireSignal("ActionEvent", actionObject.ActionName, eventName, args)
			
			self.ListenerSignals:FireSignal(actionObject.ActionName, eventName, args)
		end),
		
		[actionName .. "Destroying"] = actionObject:GetSignal("Destroying"):Connect(function()
			self.Actions[actionName] = nil
			self:CleanupConnection(actionName .. "Event", actionName .. "InputBegan", actionName .. "Destroying")
		end),
	})
end

function ItemActionManager:AddAction(actionObject, actionName)
	actionName = actionName or actionObject.ActionName
	
 	self.ActionIdentifierMap:Register(actionName, actionObject, actionObject.Id)
	self.Actions[actionName] = actionObject
	
	self:AddConnectionsForAction(actionName, actionObject)
	actionObject:LinkInputContextToInputHandler(self.InputHandler)
	self:AddInputListenerForAction(actionName)
end

function ItemActionManager:AddActions(actionsDict)
	for actionName, actionObject in pairs(actionsDict) do
		self:AddAction(actionObject, actionName)
	end
end

function ItemActionManager:GetStartedActions()
	local t = {}
	for actionName, actionObject in pairs(self.Actions) do
		if actionObject.Started then
			t[actionName] = actionObject
		end
	end
	return t
end

function ItemActionManager:Bind(...)
	local args = {...}
	for i, actionName in pairs(args) do
		self:GetAction(actionName):Bind()
	end
end

function ItemActionManager:Unbind(...)
	local args = {...}
	for i, actionName in pairs(args) do
		self:GetAction(actionName):Unbind()
	end
end

function ItemActionManager:Cancel(...)
	local args = {...}
	for i, actionName in pairs(args) do
		self:GetAction(actionName):Cancel()
	end
end

function ItemActionManager:BindAll()
	for k, action in pairs(self.Actions) do
		action:Bind()
	end
end

function ItemActionManager:UnbindAll()
	for k, action in pairs(self.Actions) do
		action:Unbind()
	end
end

function ItemActionManager:Destroy()
	table.clear(self.ActionIdentifierMap)
	self.ActionIdentifierMap = nil
	
	for k, action in pairs(self.Actions) do
		action:Destroy()
	end
	
	self:BaseDestroy()
end

return ItemActionManager

