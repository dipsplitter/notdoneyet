local Players = game:GetService("Players")

local DEFAULT_RATE_PERIOD = 120

local RateLimiterInterface = {
	Default = {},
}

local PlayerList = {}
local ActiveRateLimiters = {}

--[[
Class: Rate Limiter
]]
local RateLimiter = {}
RateLimiter.__index = RateLimiter

function RateLimiter.new(rate)
	local self = setmetatable({
		Sources = {},
		Rate = 1 / rate
	}, RateLimiter)

	return self
end

function RateLimiter:SetRate(newRate)
	self.Rate = 1 / newRate
end

function RateLimiter:CheckRate(source)
	local sources = self.Sources
	local currentTime = os.clock()

	local lastRecordedTime = sources[source]
	if lastRecordedTime ~= nil then
		lastRecordedTime = math.max(currentTime, lastRecordedTime + self.Rate)
		if lastRecordedTime - currentTime < 1 then
			sources[source] = lastRecordedTime
			return true
		else
			return false
		end
	else
		-- Preventing from remembering players that already left:
		if typeof(source) == "Instance" and source:IsA("Player")
			and PlayerList[source] == nil then
			
			return false
		end

		sources[source] = currentTime + self.Rate
		return true
	end
end

function RateLimiter:CleanSource(source)
	self.Sources[source] = nil
end

function RateLimiter:Cleanup()
	self.Sources = {}
end

function RateLimiter:Destroy()
	setmetatable(self, nil)
	table.clear(self)
	table.freeze(self)
	
	ActiveRateLimiters[self] = nil
end

--[[
	INTERFACE
]]
function RateLimiterInterface.Create(rate)
	local rateLimiter = RateLimiter.new(rate or DEFAULT_RATE_PERIOD)
	
	ActiveRateLimiters[rateLimiter] = true
	
	return rateLimiter
end

function RateLimiterInterface.Initialize()
	RateLimiterInterface.Default = RateLimiterInterface.Create(DEFAULT_RATE_PERIOD)
	
	Players.PlayerAdded:Connect(function(player)
		PlayerList[player] = true
	end)

	Players.PlayerRemoving:Connect(function(player)
		PlayerList[player] = nil
		-- Automatic player reference cleanup
		for rateLimiter in pairs(ActiveRateLimiters) do
			rateLimiter.Sources[player] = nil
		end
	end)
end

return RateLimiterInterface
