local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local Value = Framework.GetShared("Value")
local ValueRetriever = Framework.GetShared("ValueRetriever")

local RunService = game:GetService("RunService")

local TimerIncrement = {}
TimerIncrement.__index = TimerIncrement
TimerIncrement.ClassName = "TimerIncrement"
setmetatable(TimerIncrement, BaseClass)

function TimerIncrement.new(params)
	local self = BaseClass.new()
	setmetatable(self, TimerIncrement)
	
	self.Duration = params.Duration
	
	self.Name = params.Name
	self.IncrementReachedSignal = params.IncrementReachedSignal
	
	-- Sets LastTimestamp to 0; when the timer starts the increment signal will fire with this event
	self.FireAtStart = Framework.DefaultTrue(params.FireAtStart)
	
	self.MaxIncrementCount = params.MaxIncrementCount or -1
	self.CurrentIncrementCount = 0
	
	self.LastTimestamp = 0
	self:ResetLastTimestamp()
	
	return self
end

function TimerIncrement:ReachedMaxIncrements()
	if self.MaxIncrementCount == -1 then
		return false
	else
		return self.CurrentIncrementCount >= self.MaxIncrementCount
	end
end

function TimerIncrement:ResetLastTimestamp()
	self.LastTimestamp = if self.FireAtStart then 0 else os.clock()
	self.CurrentIncrementCount = 0
end

function TimerIncrement:CheckReached(timestamp)
	if self:ReachedMaxIncrements() then
		return
	end
	
	if timestamp - self.LastTimestamp >= ValueRetriever.GetValue(self.Duration) then
		self.IncrementReachedSignal:Fire(self.Name)
		self.CurrentIncrementCount += 1
		self.LastTimestamp = timestamp
	end
end

return TimerIncrement
