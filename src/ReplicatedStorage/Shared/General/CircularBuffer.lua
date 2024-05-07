local function RotateIndex(i, n)
	return ((i - 1) % n) + 1
end

local CircularBuffer = {}
CircularBuffer.__index = CircularBuffer

function CircularBuffer.new(size)
	local self = setmetatable({
		Items = {},
		Oldest = 1,
		Size = size or 60,
	}, CircularBuffer)
	
	return self
end

function CircularBuffer:__len()
	return #self.Items
end

function CircularBuffer:Filled()
	return #self.Items == self.Size
end

function CircularBuffer:Get(i)
	local itemsLength = #self.Items

	if i == 0 or math.abs(i) > itemsLength then
		return
	elseif i >= 1 then
		local rotatedIndex = RotateIndex(self.Oldest - i, itemsLength)
		return self.Items[rotatedIndex]
	elseif i <= -1 then
		local rotatedIndex = RotateIndex(i + 1 + self.Oldest, itemsLength)
		return self.Items[rotatedIndex]
	end
end

function CircularBuffer:Push(value)
	if self:Filled() then
		self.Items[self.Oldest] = value
		self.Oldest = self.Oldest == self.Size and 1 or self.Oldest + 1
	else
		self.Items[#self.Items + 1] = value
	end
end

return CircularBuffer
