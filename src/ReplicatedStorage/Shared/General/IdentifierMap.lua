local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)

local IdentifierMap = {}
IdentifierMap.__index = IdentifierMap
IdentifierMap.ClassName = "IdentifierMap"

function IdentifierMap.new(capacity)
	local self = {
		Capacity = capacity or 256,
		Current = 0,
		
		NameArray = {},
		NameToIndex = {},

		NameToItem = {},
		
		AvailableSlots = {},
	}
	
	setmetatable(self, IdentifierMap)
	
	return self
end

function IdentifierMap:Register(fullName, item, id)
	local numericId
	
	if not id then
		numericId = self.Current

		local openSlot = self.AvailableSlots[1]
		if openSlot then
			numericId = openSlot
			table.remove(self.AvailableSlots, 1)
		end
	else
		numericId = id
	end
	
	self.NameArray[numericId] = fullName
	self.NameToIndex[fullName] = numericId
	
	if item then
		self.NameToItem[fullName] = item
	end
	
	self.Current += 1
end

function IdentifierMap:GetItem(id)
	if type(id) == "number" then
		return self.NameArray[id]
	elseif type(id) == "string" then
		
		local item = self.NameToItem[id]
		if item then
			return item
		end
		
		local decompressed = self:Deserialize(id)
		if not decompressed then
			return
		end
		
		return self.NameToItem[decompressed]
	end
	
end

function IdentifierMap:Serialize(fullName)
	return self.NameToIndex[fullName]
end

function IdentifierMap:Deserialize(id)
	return self.NameArray[id]
end

function IdentifierMap:Remove(fullName)
	local nameArrayIndex = self.NameToIndex[fullName]
	
	self.NameArray[nameArrayIndex] = nil
	table.insert(self.AvailableSlots, nameArrayIndex)
	
	self.NameToIndex[fullName] = nil
	self.NameToItem[fullName] = nil
	
	self.Current -= 1
end

return IdentifierMap
