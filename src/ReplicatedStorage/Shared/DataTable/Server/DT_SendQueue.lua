local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local queues = {}

--[[
	Manages all player queues for one network event
]]

local DT_SendQueue = {}
DT_SendQueue.__index = DT_SendQueue

function DT_SendQueue.new()
	local self = {
		QueueId = HttpService:GenerateGUID(false),
		PlayerQueues = {},
	}
	setmetatable(self, DT_SendQueue)
	
	queues[self.QueueId] = self
	
	return self
end

function DT_SendQueue:AddPlayer(player)
	self.PlayerQueues[player] = {
		BufferCount = 0,
		TotalLength = 1, -- Includes the 1 byte for number of data tables
		BuffersToCopy = {}
	}
end

function DT_SendQueue:RemovePlayer(player)
	self.PlayerQueues[player] = nil
end

function DT_SendQueue:Add(stream, player)
	local playerQueue = self.PlayerQueues[player]

	playerQueue.BufferCount += 1
	
	local buffersToCopy = playerQueue.BuffersToCopy
	
	table.insert(buffersToCopy, stream)
	table.insert(buffersToCopy, playerQueue.TotalLength)
	
	playerQueue.TotalLength += buffer.len(stream)
end

function DT_SendQueue:Flush(player)
	local playerQueue = self.PlayerQueues[player]
	local buffersToCopy = playerQueue.BuffersToCopy
	
	if #buffersToCopy == 0 then
		return
	end
	
	local flushBuffer = buffer.create(playerQueue.TotalLength)
	buffer.writeu8(flushBuffer, 0, playerQueue.BufferCount)
	
	for i = 1, #buffersToCopy, 2 do
		local currentBuffer = buffersToCopy[i]
		local cursor = buffersToCopy[i + 1]
		
		buffer.copy(flushBuffer, cursor, currentBuffer)
	end
	
	playerQueue.BufferCount = 0
	playerQueue.TotalLength = 1
	table.clear(playerQueue.BuffersToCopy)
	
	return flushBuffer
end

function DT_SendQueue:Destroy()
	queues[self.QueueId] = nil
	
	setmetatable(self, nil)
	table.clear(self)
	table.freeze(self)
end

Players.PlayerAdded:Connect(function(player)
	for queueId, queue in queues do
		queue:AddPlayer(player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	for queueId, queue in queues do
		queue:RemovePlayer(player)
	end
end)

return DT_SendQueue