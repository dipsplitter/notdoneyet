local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local Value = Framework.GetShared("Value")
local TimerIncrement = Framework.GetShared("TimerIncrement")
local ValueRetriever = Framework.GetShared("ValueRetriever")
local DynamicNumberValue = Framework.GetShared("DynamicNumberValue")
local RecycledSpawn = Framework.GetShared("RecycledSpawn")

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local timerCache = {}

local Timer = {}
Timer.__index = Timer
Timer.ClassName = "Timer"
setmetatable(Timer, BaseClass)

function Timer.new(params)
	debug.setmemorycategory("Timers")
	
	local self = BaseClass.new()
	setmetatable(self, Timer)
	
	-- A nil duration indicates that the timer will run indefinitely
	self.Duration = params.Duration
	
	self.Name = params.Name or HttpService:GenerateGUID(false)
	if timerCache[self.Name] then
		self.Name = self.Name .. HttpService:GenerateGUID(false)
	end
	timerCache[self.Name] = self
	
	--[[
		Increment multipliers format:
		
		Name:
			Current -> current value of multiplier
			Getter -> function that returns multiplier value
		Values will be divided, so 0.5 means a x2 increment multiplier and the timer runs twice as fast
	]]
	 
	self.IncrementMultipliers = {}
	self.CurrentIncrementMultiplier = DynamicNumberValue.new(1, params.IncrementMultipliers)

	self.Increasing = Framework.DefaultTrue(params.Increasing)
	
	self.StartTime = 0
	self.Max = 1000
	self.Current = if self.Increasing then 0 else self.Max
	
	self.Active = false
	
	self:AddSignals("Started", "Paused", "Ended", "TimestampReached", "IncrementReached", "DurationChanged")
	
	--[[
		Timestamps
		Timestamp name: 0.2 to fire an event when 20% of duration
	]]
	
	self.Timestamps = {}
	self.PassedTimestamps = {}
	self:AddTimestamps(params.Timestamps or {})
	self:AddConnections({
		ResetTimestampsOnEnd = self.Signals.Ended:Connect(function()
			self:ResetTimestamps()
		end)
	})
	
	--[[
		Increment events
		Increment event name: 
			Duration: 0.5 to fire an event every 0.5 seconds OR
			"0.25" to fire an event every 0.25 * duration
	]]
	
	self.IncrementEvents = {}
	self:AddIncrementEvents(params.IncrementEvents or {})
	
	self.AutoCleanup = true
	
	return self
end

function Timer:CheckIncrementEvents()
	local currentTime = os.clock()
	for eventName, incrementEvent in pairs(self.IncrementEvents) do
		incrementEvent:CheckReached(currentTime)
	end
end

function Timer:ResetIncrementEvents()
	for eventName, incrementEvent in pairs(self.IncrementEvents) do
		incrementEvent:ResetLastTimestamp()
	end
end

function Timer:AddIncrementEvents(eventsDict)
	for eventName, incrementEventParams in pairs(eventsDict) do
		local duration = incrementEventParams.Duration
		if not duration then
			continue
		end
		
		if type(duration) == "string" then
			duration = function()
				return tonumber(duration) * ValueRetriever.GetValue(self.Duration)
			end
		end
		
		self.IncrementEvents[eventName] = TimerIncrement.new({
			Name = eventName,
			IncrementReachedSignal = self.Signals.IncrementReached,
			FireAtStart = incrementEventParams.FireAtStart,
			Duration = duration,
			MaxIncrementCount = incrementEventParams.MaxIncrementCount,
		})
	end
end

function Timer:ResetTimestamps()
	for timestampName, value in pairs(self.PassedTimestamps) do
		self.PassedTimestamps[timestampName] = false
	end
end

function Timer:AddTimestamps(timestampDict)
	for timestampName, t in pairs(timestampDict) do
		self.Timestamps[timestampName] = math.clamp(t, 0, 1)
		self.PassedTimestamps[timestampName] = false
	end
end

function Timer:FireTimestampEvents()
	for name, t in pairs(self.Timestamps) do
		if self.PassedTimestamps[name] then
			continue
		end
		
		if self.Current >= self.Max * t then
			self.Signals.TimestampReached:Fire(name)
			self.PassedTimestamps[name] = true
		end
	end
end

function Timer:SetInitialCount()
	if self.Increasing then
		self.Current = 0
	else
		self.Current = self.Max
	end
end

function Timer:GetRemainingTime()
	if self.Max == self.Current then
		return 0
	end
	
	return math.abs(self.Max - self.Current) / self.Max * ValueRetriever.GetValue(self.Duration) / self.CurrentIncrementMultiplier.Value
end

function Timer:GetIncrement(dt)
	return (self.Max / ValueRetriever.GetValue(self.Duration)) * dt * self.CurrentIncrementMultiplier.Value * (if self.Increasing then 1 else -1)
end

function Timer:AddToCount(amount, affectedByMultipliers)
	-- Negative amounts will extend the timer
	if not self.Increasing then
		amount *= -1
	end

	if affectedByMultipliers then
		amount *= self.CurrentIncrementMultiplier.Value
	end
	
	self.Current = math.clamp(self.Current + amount, 0, self.Max)
end

function Timer:Step(deltaTime)
	if ValueRetriever.GetValue(self.Duration) == nil then
		return
	end

	self.Current = math.clamp(self.Current + self:GetIncrement(deltaTime), 0, self.Max)
	self:FireTimestampEvents()

	self:CheckIncrementEvents()

	if self.Current == self.Max then
		self:Stop()
	end
end

function Timer:Start()
	self:FireSignal("Started")
	self.StartTime = os.clock()
	-- If our duration somehow evaluates to 0, just stop the timer!
	if ValueRetriever.GetValue(self.Duration) == 0 then
		self.Current = self.Max
		self:Stop()
		
		return
	end
	
	self:SetInitialCount()
	self.Active = true
end

function Timer:Pause()
	self.Active = false
	
	self:FireSignal("Paused")
end

function Timer:Resume()
	self.Active = true
end

function Timer:Reset()
	if not self.Active then
		return
	end
	self:Stop()
	self:SetInitialCount()
end

-- Does not fire Ended signal
function Timer:SilentReset()
	if not self.Active then
		return
	end
	self.Active = false
	
	self:SetInitialCount()
end

function Timer:Stop(wasDestroyed)
	self.Active = false
	
	self:FireSignal("Ended", self.Current == self.Max, os.clock() - self.StartTime, wasDestroyed)
end

function Timer:Destroy()
	timerCache[self.Name] = nil
	
	self:Stop(true)
	BaseClass.Destroy(self)
end

-- This will create A LOT of threads..
RunService.Heartbeat:Connect(function(deltaTime)
	for timerName, timer in timerCache do
		RecycledSpawn(function()
			-- It's been destroyed; clear it out
			if not timer.Name then
				timerCache[timerName] = nil
				return
			end

			if not timer.Active then
				return
			end
			
			timer:Step(deltaTime)
		end)
	end
end)

return Timer
