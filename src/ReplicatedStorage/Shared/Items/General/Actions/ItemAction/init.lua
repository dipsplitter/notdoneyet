local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local Timer = Framework.GetShared("Timer")
local ItemActionEvent = Framework.GetShared("ItemActionEvent")
local InputContext = Framework.GetShared("InputContext")
local IdentifierMap = Framework.GetShared("IdentifierMap") 

local Client = Framework.GetClient("Client")

local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local IsServer = RunService:IsServer()
local IsClient = RunService:IsClient()

local ActivationKeybinds = {
	Primary = Enum.UserInputType.MouseButton1,
	Secondary = Enum.UserInputType.MouseButton2,
	Teritary = Enum.UserInputType.MouseButton3,
}

local ItemAction = {}
ItemAction.__index = ItemAction
ItemAction.ClassName = "ItemAction"
setmetatable(ItemAction, BaseClass)

function ItemAction.new(params)
	local self = BaseClass.new()
	setmetatable(self, ItemAction)
	
	self.Id = params.Id
	self.CanStart = true
	self.Started = false
	
	self.ActionName = params.ActionName
	self.Config = params.Config or {}

	-- Timer name: timer params
	self.Timers = {}
	self:AddTimers(params.Timers or {})
	
	self:AddSignals("Event", "InputBegan", "Cancel", "ConfigChanged")
	
	if params.Keybinds then
		self:CreateInputContext(params)
	end
	
	-- [EventName] and [EventNameSuccessfully] stored here
	self.EventIdentifierMap = IdentifierMap.new()
	
	self.ActionEvents = {}
	self:AddBaseEvents()
	
	for eventName, evaluator in pairs(params.SuccessEvaluators or {}) do
		self.ActionEvents[eventName]:SetSuccessEvaluator(evaluator)
	end
	for eventName, evaluator in pairs(params.InitialEvaluators or {}) do
		self.ActionEvents[eventName]:SetInitialEvaluator(evaluator)
	end
	
	self:AddConnections({
		ToggleStartedOn = self.Signals.StartedSuccessfully:Connect(function()
			self.Started = true
		end),
		
		ToggleStartedOff = self.Signals.EndedSuccessfully:Connect(function()
			self.Started = false
		end),
	})
	
	self.CanListenToInput = true
	self.AutoCleanup = true
	
	return self
end

function ItemAction:GetConfigPath(path)
	local arr = {"Activations", self.ActionName, "Config"}
	
	if type(path) == "string" then
		table.insert(arr, path)
	elseif type(path) == "table" then
		table.move(path, 1, #path, #arr + 1, arr)
	end
	
	return arr
end

function ItemAction:CreateInputContext(params)
	local inputHandler = params.InputHandler or if IsClient then Client.GetInputHandler() else nil
	
	local inputContext = InputContext.new({
		InputHandler = inputHandler,
		ContextName = params.ContextId or self.ActionName,  -- Only necessary on the client to avoid CAS conflicts
		ValidInputStates = params.ValidInputStates,
		Keybinds = if ActivationKeybinds[params.Keybinds] then ActivationKeybinds[params.Keybinds] else params.Keybinds,
	})
	
	self:SetInputContext(inputContext, inputHandler)
end

function ItemAction:SetKeybinds(keybindInfo)
	if self.InputContext then
		self.InputContext:SetKeybinds(keybindInfo.Keybinds)
	else
		self:CreateInputContext(keybindInfo)
	end
end

function ItemAction:GetEvent(eventName)
	return self.ActionEvents[eventName]
end

function ItemAction:GetInputContext()
	return self.InputContext
end

function ItemAction:SetInputContext(inputContext, inputHandler)
	local currentInputContext = self:GetInputContext()
	if currentInputContext then
		currentInputContext:Destroy()
	end
	
	self.InputContext = inputContext
	
	-- Disconnect and reconnect
	if self:GetConnection("InputContextListener") then
		self:ListenToInput()
	end
	
	if inputHandler then
		self:LinkInputContextToInputHandler(inputHandler)
	end
end

function ItemAction:LinkInputContextToInputHandler(inputHandler)
	local context = self:GetInputContext()
	if not context or not inputHandler then
		return
	end
	
	context:SetInputHandler(inputHandler)
	inputHandler:AddContext(context)
end

function ItemAction:CanStartWithInput()
	local inputContext = self:GetInputContext()
	if not inputContext then
		return false
	end
	
	if not inputContext:UnpackKeybinds() then
		return false
	end
	
	return true
end

function ItemAction:AddBaseEvents()
	self:AddEvent({
		Name = "Started", 
		InitialEvaluator = function()
			return self.CanStart
		end
	})
	self:AddEvent({
		Name = "Ended"
	})
end

function ItemAction:GetConfig(keyName)
	return self.Config[keyName]
end

function ItemAction:SetConfig(keyName, value)
	local oldValue = self.Config[keyName]
	self.Config[keyName] = value
	self:FireSignal("ConfigChanged", keyName, value, oldValue)
end

function ItemAction:ListenToInput()
	if not self.CanListenToInput then
		return
	end
	
	self:AddConnections({
		InputContextListener = self:GetInputContext():GetSignal("Triggered"):Connect(function(inputObject, configs)
			self:FireSignal("InputBegan", inputObject, configs)
		end)
	})
end

function ItemAction:StopListeningToInput()
	self:CleanupConnection("InputContextListener")
end

function ItemAction:DisableInput()
	self:StopListeningToInput()
	self.CanListenToInput = false
end

function ItemAction:EnableInput(bindAfterEnable)
	self.CanListenToInput = true
	
	if bindAfterEnable then
		self:ListenToInput()
	end
end

function ItemAction:Bind(keybinds, customInputHandler)
	self.CanStart = true
	
	if not self:CanStartWithInput() and not keybinds then
		return
	end
	
	self:ListenToInput()
end

function ItemAction:Unbind()
	self.CanStart = false

	if not self:CanStartWithInput() then
		return
	end

	self:StopListeningToInput()
end

function ItemAction:AddEvent(params)
	local eventName = params.Name
	local eventSuccessName = `{eventName}Successfully`
	
	self:AddSignals(eventName, eventSuccessName)
	
	params.Signals = {
		Success = self.Signals[eventSuccessName],
		Normal = self.Signals[eventName],
		General = self.Signals.Event,
	}
	
	local eventObject = ItemActionEvent.new(params)
	
	self.EventIdentifierMap:Register(eventName)
	self.EventIdentifierMap:Register(eventSuccessName)
	
	self.ActionEvents[eventName] = eventObject
end

-- Use to start/end the action
function ItemAction:StartEvent(name, args, fn)
	-- TODO: Find the root cause of this issue; the event name is turning up as the correct name + Successfully
	-- on input-based event triggers
	name = name or "Started"
	
	if string.find(name, "Successfully") then
		name = string.gsub(name, "Successfully", "")
	end

	if not self.ActionEvents[name] then
		return
	end
	
	self.ActionEvents[name]:Start(args)
	
	if fn then
		fn()
	end
end

function ItemAction:AddTimers(timerDict)
	for name, timerParams in pairs(timerDict) do
		if timerParams.IsClass then
			
			if timerParams:IsClass("Timer") then
				self.Timers[name] = timerParams
			end
			
		else
			self.Timers[name] = Timer.new(timerParams)
		end
		
		self.Cleaner:Add(self.Timers[name])
	end
end

function ItemAction:GetTimer(timerName)
	return self.Timers[timerName]
end

function ItemAction:Cancel(...)
	self:FireSignal("Cancel", ...)
end

return ItemAction

