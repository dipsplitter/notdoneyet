local RunService = game:GetService("RunService")
local NetworkRequire = require(game:GetService("ReplicatedStorage").Network.NetworkRequire)
local BufferOperationQueue = NetworkRequire.Require("BufferOperationQueue")
local Send = NetworkRequire.Require("Send")
local Receive = NetworkRequire.Require("Receive")
local RemoteEventRegistry = NetworkRequire.Require("RemoteEventRegistry")
local FireRemote = NetworkRequire.Require("FireRemote")

local queues = {
	Reliable = BufferOperationQueue.new(),
	Unreliable = BufferOperationQueue.new(),
}

local remotes = RemoteEventRegistry.Main

local MainClient = {}

function MainClient.Send(event, argsTable)
	Send(event, argsTable, queues[event.Reliability])
end

function MainClient.Receive()
	remotes.Reliable.OnClientEvent:Connect(Receive)
	remotes.Unreliable.OnClientEvent:Connect(Receive)
end

RunService.PostSimulation:Connect(function()
	for queueType, queue in queues do
		FireRemote("Main", queue, queueType)
	end
end)


return MainClient
