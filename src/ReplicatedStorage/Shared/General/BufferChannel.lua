--!native
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BufferUtilities = Framework.GetShared("BufferUtilities")

local BufferChannel = {}
BufferChannel.__index = BufferChannel

function BufferChannel.new()
	local self = {
		Queue = {},
	}
	
	setmetatable(self, BufferChannel)
	
	return self
end

function BufferChannel:Add(stream)
	table.insert(self.Queue, stream)
end

function BufferChannel:Flush()
	if #self.Queue == 0 then
		return
	end
	
	local merged = BufferUtilities.MergeArray(self.Queue)
	table.clear(self.Queue)
	
	return merged
end

return BufferChannel
