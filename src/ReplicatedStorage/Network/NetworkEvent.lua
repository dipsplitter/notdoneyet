local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local RecycledSpawn = Framework.GetShared("RecycledSpawn")

local RunService = game:GetService("RunService")
local IsClient = RunService:IsClient()
local IsServer = RunService:IsServer()

local NetworkRequire = require(ReplicatedStorage.Network.NetworkRequire)
local EventTracker = NetworkRequire.Require("EventTracker")
local EventMiddleware = NetworkRequire.Require("EventMiddleware")
local HookMiddleware = NetworkRequire.Require("HookMiddleware")

local BufferOperationQueue = NetworkRequire.Require("BufferOperationQueue")
local Send = NetworkRequire.Require("Send")

local PlayerContainers = NetworkRequire.Require("PlayerContainers")
-- local RateLimiter = NetworkRequire.Require("RateLimiter")

local function CheckTargets(targets)
	if typeof(targets) == "Instance" then
		return PlayerContainers.Single(targets)
	end

	return targets
end

local NetworkEvent = {}
NetworkEvent.__index = NetworkEvent

function NetworkEvent.new(eventInfo, id)
	local self = {
		Reliability = eventInfo.Reliability or "Reliable",
		Listeners = {},
		ArgumentOrder = {},
		ReplicationProcess = NetworkRequire.RequireProcess(eventInfo.Process or "Main"),
		
		WaitingListenerArguments = {},
	}
	setmetatable(self, NetworkEvent)
	
	self.Id = id
	self.DefaultSendFunction = if self.ReplicationProcess.Send then "Deferred" else "Immediate"
	
	EventTracker.Register(self)
	
	local structure = eventInfo.Structure
	
	if type(structure) == "table" then
		-- Ensure consistent structure
		for key, dataType in structure do
			table.insert(self.ArgumentOrder, {key, dataType})
		end
		table.sort(self.ArgumentOrder, function(a, b)
			return a[1] < b[1]
		end)
	else
		HookMiddleware(self, structure)
	end
	
	return self
end

function NetworkEvent:UsesMiddleware()
	return #self.ArgumentOrder == 0
end

function NetworkEvent:VerifyArguments(argsTable)
	if #self.ArgumentOrder == 0 then
		return true
	end

	for i, keyValuePair in self.ArgumentOrder do
		local keyName = keyValuePair[1]
		local dataType = keyValuePair[2]

		local data = argsTable[keyName]
		if data == nil then
			warn(`Missing key "{keyName}"`)
			return false
		end
	end

	return true
end

function NetworkEvent:Fire(argsTable, targets)
	local sendType = self.DefaultSendFunction
	if sendType == "Deferred" then
		self:FireDeferred(argsTable, targets)
	else
		self:FireImmediate(argsTable, targets)
	end
end
 
-- Does not add to queue
function NetworkEvent:FireImmediate(argsTable, targets)
	if IsServer and targets then
		targets = CheckTargets(targets)
	end
	
	if not self:VerifyArguments(argsTable) then
		return
	end
	
	local temporaryQueue = BufferOperationQueue.new()
	Send(self, argsTable, temporaryQueue)
	self.ReplicationProcess.SendImmediate(self, temporaryQueue, targets)
end

function NetworkEvent:FireDeferred(argsTable, targets)
	if IsServer and targets then
		targets = CheckTargets(targets)
	end

	if not self:VerifyArguments(argsTable) then 
		return
	end

	self.ReplicationProcess.Send(self, argsTable, targets)
end

function NetworkEvent:CollectListenerArguments(...)
	if not self.WaitingListenerArguments then
		return
	end
	
	table.insert(self.WaitingListenerArguments, {...})
end

function NetworkEvent:Connect(fn)
	local isFirstConnection = (next(self.Listeners) == nil)
	self.Listeners[fn] = true
	
	local waiting = self.WaitingListenerArguments
	if isFirstConnection and waiting and next(waiting) then
		for i, args in waiting do
			RecycledSpawn(fn, table.unpack(args))
		end
		
		self.WaitingListenerArguments = nil
	end
	
	-- Disconnect callback
	return function()
		self.Listeners[fn] = nil
	end
end

function NetworkEvent:FireListeners(...)
	if next(self.Listeners) then
		
		for callback in self.Listeners do
			RecycledSpawn(callback, ...)
		end
		
	else
		
		self:CollectListenerArguments(...)
		
	end
end

return NetworkEvent


