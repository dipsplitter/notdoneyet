local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local ReadBuffer = Framework.GetShared("ReadBuffer")

local ACTIONS = {
	CreateFromClientInventory = 0,
	CreatePlainCopy = 1,
	Destroy = 2,
}

local function MainInbound(stream, cursor)
	local readBuffer = ReadBuffer.new(stream, cursor)

	local gameId = readBuffer:readu16()
	local action = readBuffer:readu8()
	
	local data = {
		Id = gameId,
	}
	
	-- Pull from client inventory
	if action == ACTIONS.CreateFromClientInventory then
		
		data.InventoryId = readBuffer:readu16()
		
	elseif action == ACTIONS.CreatePlainCopy then -- Create fresh copy
		
		data.SchemaId = readBuffer:readu16()
		
	elseif action == ACTIONS.Destroy then -- Destroy
		
		data.Destroy = true
		
	end
	
	return {
		AdvanceCursor = readBuffer:GetBytesRead(),
		Status = true,
		Data = data,
	}
end

--[[
	Potential parameters:
	
	InventoryId: create the item corresponding to the inventory ID
	ItemId: create a fresh copy of an item, given its schema ID
	Destroy: delete the item under the game ID

]]
local function MainOutbound(data, queue)
	local handle = data.Id
	local clientInventoryId = data.InventoryId
	local schemaId = data.SchemaId
	local shouldDestroy = data.Destroy
	
	queue:writeu16(handle)
	
	if clientInventoryId then
		
		queue:writeu8(ACTIONS.CreateFromClientInventory)
		queue:writeu16(clientInventoryId)
		
	elseif schemaId then
		
		queue:writeu8(ACTIONS.CreatePlainCopy)
		queue:writeu16(schemaId)
		
	elseif shouldDestroy then
		
		queue:writeu8(ACTIONS.Destroy)
		
	end
	
	return {Status = true}
end

return {
	Inbound = {
		MainInbound,
	},

	Outbound = {
		MainOutbound,
	}
}
