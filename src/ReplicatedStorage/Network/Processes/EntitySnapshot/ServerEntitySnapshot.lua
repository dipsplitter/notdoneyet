local RunService = game:GetService("RunService")
local NetworkRequire = require(game:GetService("ReplicatedStorage").Network.NetworkRequire)
local FireRemote = NetworkRequire.Require("FireRemote")
local BufferOperationQueue = NetworkRequire.Require("BufferOperationQueue")
local Send = NetworkRequire.Require("Send")
local Receive = NetworkRequire.Require("Receive")
local RemoteEventRegistry = NetworkRequire.Require("RemoteEventRegistry")

local ServerEntitySnapshot = {}

function ServerEntitySnapshot.SendImmediate(event, queue, playerContainer)
	for i, player in playerContainer:Players() do
		FireRemote("EntitySnapshot", queue, event.Reliability, player)
	end
end

return ServerEntitySnapshot
