local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Identifiers = Framework.GetShared("DT_ServerIds")
local NetworkDataTable = Framework.GetShared("NetworkDataTable")

local EMPTY_PLAYER_CONTAINER = {
	Players = function()
		return {}
	end,
	
	IsInContainer = function()
		return false
	end,
}

local SendTable = {}
SendTable.__index = SendTable

function SendTable.new(params)
	local self = {
		-- List of players
		PlayerContainer = params.PlayerContainer or EMPTY_PLAYER_CONTAINER,
		
		-- Stores player local data table IDs (how the client identifies this) and send full snapshot flags
		PlayerReplicationData = {},
		
		ShouldNetwork = true,
	}
	setmetatable(self, SendTable)
	
	NetworkDataTable.Create(self, params)
	
	self.Id = Identifiers.Register(self, params.InitialDataReceived)
	
	return self
end

-- TODO
function SendTable:ExcludeProperties(propertyNameArray)
	for name in propertyNameArray do
		
	end
end

function SendTable:SetOwnershipToCharacter(character)
	local player = if character:IsA("Model") then Players:GetPlayerFromCharacter(character) else character
	if player then
		self:ChangeOwnership(player)
	else
		self:DisableNetwork()
	end
end

function SendTable:DisableNetwork()
	self.ShouldNetwork = false
	self:ChangeOwnership(nil)
end

function SendTable:HasValidPlayerTargets()
	if not self.ShouldNetwork then
		return false
	end
	
	-- No players logged
	if not next(self.PlayerReplicationData) then
		return false
	end
	
	-- Alternative to above condition (unsure if necessary)
	if self.PlayerContainer == EMPTY_PLAYER_CONTAINER then
		return false
	end
	
	return true
end

function SendTable:IsPlayerValid(player)
	return self.PlayerReplicationData[player] ~= nil
end

-- New player
function SendTable:RegisterPlayer(player, localId, havePlayersReceivedInitialData)
	if self.PlayerReplicationData[player] then
		return
	end

	self.PlayerReplicationData[player] = {
		SendFullSnapshotOnNextUpdate = not havePlayersReceivedInitialData,

		-- If false, we have to encode the length of the buffer
		ReceiveTableCreated = havePlayersReceivedInitialData,

		LocalId = localId
	}
end

function SendTable:DisableInitialFullSnapshotSendForPlayers()
	for player, data in self.PlayerReplicationData do
		data.SendFullSnapshotOnNextUpdate = false
		data.ReceiveTableCreated = true
	end
end

function SendTable:RemovePlayer(player)
	self.PlayerReplicationData[player] = nil
	
	if self.PlayerContainer then
		self.PlayerContainer[player] = nil
	end
end

function SendTable:ChangeOwnership(newPlayerContainer, havePlayersReceivedInitialData)
	local oldPlayerContainer = self.PlayerContainer
	
	self.PlayerContainer = newPlayerContainer or EMPTY_PLAYER_CONTAINER
	
	-- We passed a player instance
	if newPlayerContainer and type(newPlayerContainer) ~= "table" then
		self.PlayerContainer = {
			Players = function()
				return {newPlayerContainer}
			end,

			IsInContainer = function(player)
				return (player == newPlayerContainer)
			end,
		}
	end

	Identifiers.ChangeOwnership(self, oldPlayerContainer, havePlayersReceivedInitialData)
end

function SendTable:SetOwnershipChangedSignal(signal)
	return signal:Connect(function(target)
		self:SetOwnershipToCharacter(target)
	end)
end

function SendTable:Send()
	return self.Packer:FlushChanges()
end

function SendTable:SendFromState(comparison)
	return self.Packer:PackDeltas(comparison)
end

function SendTable:SendFull()
	return self.Packer:PackFull()
end

function SendTable:Set(path, value)
	NetworkDataTable.Set(self, path, value)
	
	if not self.IsCollating then
		self.Packer:UpdateCurrent(self.Data)
		self.Packer:QueueChanges()
	end
end

function SendTable:Collate(callback)
	self.IsCollating = true
	
	task.spawn(function()
		callback()
		self.IsCollating = false

		self.Packer:UpdateCurrent(self.Data)
		self.Packer:QueueChanges()
	end)
end

function SendTable:Predict(path, value)
	NetworkDataTable.Set(self, path, value)
	
	if not self.IsCollating then
		self.Packer:UpdateCurrent(self.Data)
	end
end

function SendTable:Copy()
	return NetworkDataTable.Copy(self, SendTable)
end

function SendTable:Destroy()
	Identifiers.Remove(self)

	setmetatable(self, nil)
	table.clear(self)
	table.freeze(self)
end

SendTable.CopyDataFlattened = NetworkDataTable.CopyDataFlattened
SendTable.CopyData = NetworkDataTable.CopyData
SendTable.Get = NetworkDataTable.Get
SendTable.ChangedSignal = NetworkDataTable.ChangedSignal

return SendTable
