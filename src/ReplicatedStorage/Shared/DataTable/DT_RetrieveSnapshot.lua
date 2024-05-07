local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Constants = Framework.GetShared("DT_Constants")
local StructureRetriever = Framework.GetShared("DT_StructureRetriever")

local BitBuffer = Framework.RequireNetworkModule("BitBuffer")

local function ToBuffer(playerReplicationData, dataStreamBuffer)
	local bitBuffer = BitBuffer.new()
	
	bitBuffer:WriteVarInt(playerReplicationData.LocalId)
	
	local toString = dataStreamBuffer:ToString()

	bitBuffer:WriteVarInt(#toString)
	bitBuffer:WriteBytes(toString)

	return bitBuffer:ToBuffer()
end

local DT_RetrieveSnapshot = {}

function DT_RetrieveSnapshot.FullSnapshot(dataTable, player)
	local playerReplicationData = dataTable.PlayerReplicationData[player]

	if not playerReplicationData then
		return
	end
	
	local dataStream = dataTable:SendFull()
	
	if not dataStream then
		return
	end

	return ToBuffer(playerReplicationData, dataStream)
end

function DT_RetrieveSnapshot.DeltaSnapshot(dataTable, player, previousState)
	local playerReplicationData = dataTable.PlayerReplicationData[player]

	if not playerReplicationData then
		return
	end
	
	local dataStream
	if previousState then
		dataStream = dataTable:SendFromState(previousState)
	else
		dataStream = dataTable:Send()
	end

	if not dataStream then
		return
	end

	return ToBuffer(playerReplicationData, dataStream)
end

function DT_RetrieveSnapshot.Snapshot(dataTable, player, previousState)
	local playerReplicationData = dataTable.PlayerReplicationData[player]

	if not playerReplicationData then
		return
	end
	
	if playerReplicationData.SendFullSnapshotOnNextUpdate then
		playerReplicationData.SendFullSnapshotOnNextUpdate = false
		return DT_RetrieveSnapshot.FullSnapshot(dataTable, player)
	else
		return DT_RetrieveSnapshot.DeltaSnapshot(dataTable, player, previousState)
	end
end

return DT_RetrieveSnapshot