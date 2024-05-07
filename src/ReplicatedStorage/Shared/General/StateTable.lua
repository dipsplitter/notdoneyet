local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local TableUtilities = Framework.GetShared("TableUtilities")

local StateTable = {}
StateTable.__index = StateTable
StateTable.ClassName = "StateTable"
setmetatable(StateTable, BaseClass)

function StateTable.new(data)
	local self = BaseClass.new()
	setmetatable(self, StateTable)
	
	self.Data = data
	self:AddSignals("Changed")
	
	return self
end

function StateTable:TraversePath(pathArray, start)
	if type(pathArray) == "string" then
		pathArray = TableUtilities.StringPathToArray(pathArray)
	end

	local pointer = start or self.Data

	for i = 1, #pathArray - 1 do
		pointer = pointer[pathArray[i]]
	end

	return pointer, pathArray[#pathArray]
end

function StateTable:GetValue(pathArray)
	local tab, key = self:TraversePath(pathArray)
	return tab[key]
end

function StateTable:SetValue(pathArray, values)
	local tab, key = self:TraversePath(pathArray)

	if typeof(values) == "table" then

		for keyName, val in pairs(values) do
			tab[keyName] = if val == "NULL" then nil else val
		end

	else
		tab[key] = if values == "NULL" then nil else values
	end
	
	self:FireSignal("Changed", pathArray, values)
end

return StateTable
