local RunService = game:GetService("RunService")
local IsServer = RunService:IsServer()

local RemoteEventsFolder = script.Parent.RemoteEvents

local NetworkRequire = require(script.Parent.NetworkRequire)
local DeclaredEvents = NetworkRequire.Require("DeclaredEvents")

local RemoteEventRegistry = {
	Main = {
		Reliable = RemoteEventsFolder.Reliable,
		Unreliable = RemoteEventsFolder.Unreliable,
	},
}

for i, eventInfo in DeclaredEvents do
	local remoteEventChannelPairName = eventInfo.Process
	
	if not remoteEventChannelPairName then
		continue
	end
	
	local reliable = RemoteEventsFolder:FindFirstChild(remoteEventChannelPairName)
	if IsServer and not reliable then
		reliable = Instance.new("RemoteEvent")
		reliable.Name = remoteEventChannelPairName
		reliable.Parent = RemoteEventsFolder
	end

	local unreliable = RemoteEventsFolder:FindFirstChild(`{remoteEventChannelPairName}Unreliable`)
	if IsServer and not unreliable then
		unreliable = Instance.new("UnreliableRemoteEvent")
		unreliable.Name = `{remoteEventChannelPairName}Unreliable`
		unreliable.Parent = RemoteEventsFolder
	end
	
	RemoteEventRegistry[remoteEventChannelPairName] = {
		Reliable = reliable,
		Unreliable = unreliable
	}
end

return RemoteEventRegistry
