local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetworkRequire = require(ReplicatedStorage.Network.NetworkRequire)
local FireRemote = NetworkRequire.Require("FireRemote")
--[[
local ServerIds = Framework.GetShared("DT_ServerIds")
local BufferUtilities = Framework.GetShared("BufferUtilities")
local BufferChannel = Framework.GetShared("BufferChannel")
local WriteBitstream = Framework.GetShared("WriteBitstream")
local Constants = Framework.GetShared("DT_Constants")
local SendQueue = Framework.GetShared("DT_SendQueue")

--[[
	An external loop in DT_Send will gather all DT snapshots and transfer them here
]] 

local DataTableServer = {}

function DataTableServer.SendImmediate(event, queue, playerContainer)
	for i, player in playerContainer:Players() do
		FireRemote("DataTable", queue, event.Reliability, player)
	end
end

return DataTableServer
