local RunService = game:GetService("RunService")
local NetworkRequire = require(game:GetService("ReplicatedStorage").Network.NetworkRequire)
local BufferOperationQueue = NetworkRequire.Require("BufferOperationQueue")
local Receive = NetworkRequire.Require("Receive")
local RemoteEventRegistry = NetworkRequire.Require("RemoteEventRegistry")

local remotes = RemoteEventRegistry.DataTable

local DataTableClient = {}

function DataTableClient.Receive()
	remotes.Reliable.OnClientEvent:Connect(Receive)
	remotes.Unreliable.OnClientEvent:Connect(Receive)
end

return DataTableClient
