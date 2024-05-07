local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Signal = Framework.GetShared("Signal")
local TableUtilities = Framework.GetShared("TableUtilities")

local ActionManagerListenerSignals = {}
ActionManagerListenerSignals.__index = ActionManagerListenerSignals
ActionManagerListenerSignals.ClassName = "ActionManagerSignalListeners"

function ActionManagerListenerSignals.new()
	local self = setmetatable({}, ActionManagerListenerSignals)
	
	return self
end

function ActionManagerListenerSignals:FireSignal(actionName, eventName, args)
	if not self[actionName] then
		return
	end
	
	if not self[actionName][eventName] then
		return
	end
	
	for sig in pairs(self[actionName][eventName]) do
		sig:Fire(args)
	end
end

function ActionManagerListenerSignals:AddSignal(actionName, eventName)
	local actionSignals = self[actionName]
	if not actionSignals then
		self[actionName] = {}
	end
	
	if not self[actionName][eventName] then
		self[actionName][eventName] = {}
	else
		local existingSignal = next(self[actionName][eventName])
		if existingSignal then
			return existingSignal
		end
	end
	
	local signal = Signal.new({}, function(sig)
		self:RemoveSignal(actionName, eventName, sig)
	end)
	
	self[actionName][eventName][signal] = 1

	return signal
end

function ActionManagerListenerSignals:RemoveSignal(actionName, eventName, signal)
	if #signal:GetConnections() > 0 then
		return
	end
	
	local actionTable = self[actionName]
	local eventTable = actionTable[eventName]
	
	if eventTable[signal] then
		signal:Destroy()
		eventTable[signal] = nil
		
		if not next(eventTable) then
			actionTable[eventName] = nil
		end
	end
	
	if not next(actionTable) then
		self[actionName] = nil
	end
end

function ActionManagerListenerSignals:GetActionStartedSignal(actionName, ignoreSuccess)
	local name = if ignoreSuccess then "Started" else "StartedSuccessfully"
	return self:AddSignal(actionName, name)
end

function ActionManagerListenerSignals:GetActionEndedSignal(actionName, ignoreSuccess)
	local name = if ignoreSuccess then "Ended" else "EndedSuccessfully"
	return self:AddSignal(actionName, name)
end

function ActionManagerListenerSignals:GetInputBeganSignal(actionName)
	return self:AddSignal(actionName, "InputBegan")
end

function ActionManagerListenerSignals:GetActionEventSignal(actionName, eventName)
	return self:AddSignal(actionName, eventName)
end

return ActionManagerListenerSignals
