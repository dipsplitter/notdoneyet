local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Identifiers = Framework.GetShared("DT_ClientIds")
local Constants = Framework.GetShared("DT_Constants")

local NETWORK = Framework.Network()

local Receive = {}

local function BaseReceive(data, eventName)
	for dataTable, newValues in data do

		if type(dataTable) == "table" then
			dataTable:OnReceive(newValues)
		elseif type(dataTable) == "number" then
			Identifiers.AddInitialData(dataTable, newValues, eventName)
		end

	end
end

for i, eventName in Constants.Events do
	
	if Constants.IgnoreMainReceiveProcess[eventName] then
		continue
	end
	
	NETWORK.Event(eventName):Connect(function(data)
		BaseReceive(data, eventName)
	end)
	
end

return Receive
