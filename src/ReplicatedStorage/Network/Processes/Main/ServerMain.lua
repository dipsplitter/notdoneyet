local RunService = game:GetService("RunService")
local NetworkRequire = require(game:GetService("ReplicatedStorage").Network.NetworkRequire)
local BufferOperationQueue = NetworkRequire.Require("BufferOperationQueue")
local Receive = NetworkRequire.Require("Receive")
local Send = NetworkRequire.Require("Send")
local ClientList = NetworkRequire.Require("ClientList")
local RemoteEventRegistry = NetworkRequire.Require("RemoteEventRegistry")
local FireRemote = NetworkRequire.Require("FireRemote")

local remotes = RemoteEventRegistry.Main

-- Structure: [player] = {reliable channel, unreliable channel}
local playerChannels = {}

local function CreatePlayerChannels(player)
	if playerChannels[player] then
		return
	end

	playerChannels[player] = {
		Reliable = BufferOperationQueue.new(),
		Unreliable = BufferOperationQueue.new(),
	}
end

local MainServer = {}

function MainServer.Send(event, argsTable, playerContainer)
	for i, player in playerContainer:Players() do
		if not playerChannels[player] then
			CreatePlayerChannels(player)
		end

		Send(event, argsTable, playerChannels[player][event.Reliability])
	end
end

function MainServer.SendImmediate(event, queue, playerContainer)
	for i, player in playerContainer:Players() do
		FireRemote("Main", queue, event.Reliability, player)
	end
end

function MainServer.Receive()
	remotes.Reliable.OnServerEvent:Connect(function(player, stream)
		Receive(stream, player)
	end)

	remotes.Unreliable.OnServerEvent:Connect(function(player, stream)
		Receive(stream, player)
	end)
end

ClientList.ClientAdded:Connect(CreatePlayerChannels)

ClientList.ClientRemoving:Connect(function(player)
	playerChannels[player] = nil
end)

RunService.PostSimulation:Connect(function()
	for player, channels in playerChannels do
		for queueType, queue in channels do
			FireRemote("Main", channels[queueType], queueType, player)
		end
	end
end)

return MainServer
