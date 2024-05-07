local Deque = {}
Deque.__index = Deque

function Deque.new()
	local self = {
		Array = {},
		FirstIndex = 0,
		LastIndex = -1,
	}
	setmetatable(self, Deque)
	
	return self
end

function Deque:Size()
	return #self.Array
end

function Deque:AddFirst(item)
	self.FirstIndex -= 1
	self.Array[self.FirstIndex] = item
end

function Deque:AddLast(item)
	self.LastIndex += 1
	self.Array[self.LastIndex] = item
end

function Deque:RemoveFirst()
	if self.FirstIndex > self.LastIndex then
		return
	end
	
	local result = self.Array[self.FirstIndex]
	self.Array[self.FirstIndex] = nil
	self.FirstIndex += 1
	return result
end

function Deque:RemoveLast()
	if self.FirstIndex > self.LastIndex then
		return
	end
	
	local result = self.Array[self.LastIndex]
	self.Array[self.LastIndex] = nil
	self.LastIndex -= 1
	return result
end

function Deque:GetFirst()
	return self.Array[self.FirstIndex]
end

function Deque:GetLast()
	return self.Array[self.LastIndex]
end

return Deque
