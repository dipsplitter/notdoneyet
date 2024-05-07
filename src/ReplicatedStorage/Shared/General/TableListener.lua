local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local TableUtilities = Framework.GetShared("TableUtilities")

--[[ 
	Listens to the changes made to a particular key in a state table
]]
local TableListener = {}
TableListener.__index = TableListener
TableListener.ClassName = "TableListener"
setmetatable(TableListener, BaseClass)

function TableListener.new(tab, key, signal)
	local self = BaseClass.new({
		Table = tab,
		Key = key,
		Signal = signal,
	})
	setmetatable(self, TableListener)
	
	self.Path = TableUtilities.StringPathToArray(key)
	self.Value = TableUtilities.GetValueFromPath(tab, key)
	
	self:AddConnections({
		Main = self.Signal:Connect(function()
			local newValue = TableUtilities.GetValueFromPath(tab, key)

			if newValue == nil then

			end

			if newValue ~= self.Value then
				local oldValue = self.Value
				self.Value = newValue
				self:FireSignal("Changed", newValue, oldValue)
			end
		end)
	})
	
	self:AddSignals("Changed")
	
	return self
end

return TableListener
