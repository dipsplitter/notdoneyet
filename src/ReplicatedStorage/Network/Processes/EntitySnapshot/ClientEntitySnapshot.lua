local RunService = game:GetService("RunService")
local NetworkRequire = require(game:GetService("ReplicatedStorage").Network.NetworkRequire)
local BufferOperationQueue = NetworkRequire.Require("BufferOperationQueue")
local Send = NetworkRequire.Require("Send")
local Receive = NetworkRequire.Require("Receive")
local RemoteEventRegistry = NetworkRequire.Require("RemoteEventRegistry")

local remotes = RemoteEventRegistry.EntitySnapshot

local ClientEntitySnapshot = {}

function ClientEntitySnapshot.Receive()
	remotes.Reliable.OnClientEvent:Connect(Receive)
	remotes.Unreliable.OnClientEvent:Connect(Receive)
end

return ClientEntitySnapshot
