local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local NetworkRequire = require(ReplicatedStorage.Network.NetworkRequire)
local RemoteEventRegistry = NetworkRequire.Require("RemoteEventRegistry")

local IsClient = RunService:IsClient()
local IsServer = RunService:IsServer()

return function(remoteName, queue, reliability, player)
	local remoteEvent = RemoteEventRegistry[remoteName][reliability or "Reliable"]
	
	local flushedBuffer = queue:Flush()
	
	if not flushedBuffer then
		return
	end
	
	if IsServer then
		remoteEvent:FireClient(player, flushedBuffer)
	elseif IsClient then
		remoteEvent:FireServer(flushedBuffer)
	end
end