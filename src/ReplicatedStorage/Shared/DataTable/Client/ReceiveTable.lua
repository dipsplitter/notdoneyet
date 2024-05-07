local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Identifiers = Framework.GetShared("DT_ClientIds")
local NetworkDataTable = Framework.GetShared("NetworkDataTable")

local ReceiveTable = {}
ReceiveTable.__index = ReceiveTable

function ReceiveTable.new(params)
	local self = {
		InitialDataReceived = Framework.DefaultFalse(params.InitialDataReceived)
	}
	setmetatable(self, ReceiveTable)
	
	NetworkDataTable.Create(self, params)
	
	Identifiers.Register(self)
	
	return self
end

function ReceiveTable:ReceiveInitialData(initialBuffer)
	local values = self.Packer:ReadBuffer(initialBuffer)
	self.InitialDataReceived = true
	
	self:OnReceive(values)
end

function ReceiveTable:OnReceive(newValues, reconcileAgainst)
	newValues = self.Packer:ReconcileChanges(newValues, reconcileAgainst)

	for strPath, newValue in newValues do
		NetworkDataTable.Set(self, strPath, newValue)
	end
	
	self.Packer:UpdateCurrent(self.Data)
end

function ReceiveTable:Predict(path, value)
	NetworkDataTable.Set(self, path, value)
end

function ReceiveTable:Local(callback)
	self.IsCollating = true

	task.spawn(function()
		callback()
		self.IsCollating = false
	end)
end

function ReceiveTable:Copy()
	return NetworkDataTable.Copy(self, ReceiveTable)
end

function ReceiveTable:Destroy()
	Identifiers.Remove(self)
	
	setmetatable(self, nil)
	table.clear(self)
	table.freeze(self)
end

-- Conform with send table methods (no need to check if we're the client or server)
ReceiveTable.Set = ReceiveTable.Predict
ReceiveTable.Collate = ReceiveTable.Local

ReceiveTable.CopyDataFlattened = NetworkDataTable.CopyDataFlattened
ReceiveTable.CopyData = NetworkDataTable.CopyData
ReceiveTable.Get = NetworkDataTable.Get
ReceiveTable.ChangedSignal = NetworkDataTable.ChangedSignal

return ReceiveTable
