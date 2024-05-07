local RunService = game:GetService("RunService")
local IsClient = RunService:IsClient()
local IsServer = RunService:IsServer()

local NetworkFolder = script.Parent
local ProcessesFolder = NetworkFolder.Processes

local NetworkRequire = require(NetworkFolder.NetworkRequire)
--local RemoteEventRegistry = NetworkRequire.Require("RemoteEventRegistry")

local t = os.clock()

-- Initialize server player list and rate limiters
if IsServer then
	NetworkRequire.Require("ClientList")
	NetworkRequire.Require("RateLimiter")
end

local DataTypesList = NetworkRequire.Require("DataTypesList")

local NetworkEvent = NetworkRequire.Require("NetworkEvent")
local DeclaredEvents = NetworkRequire.Require("DeclaredEvents")

local eventsStorage = {}

-- Initialize and cache events
for eventId, eventInfo in DeclaredEvents do
	local event = NetworkEvent.new(eventInfo, eventId)
	eventsStorage[eventInfo.Name] = event
	
	event.Name = eventInfo.Name
end

-- Initialize client and server replication processes
for i, processSubfolder in ProcessesFolder:GetChildren() do
	local process = NetworkRequire.RequireProcess(processSubfolder.Name)
	
	-- We've initialized all event handlers, so we can begin receiving data
	if process.Receive then
		process.Receive()
	end
end

print(`[{if IsClient then "Client" else "Server"}Network]: Initialized in {os.clock() - t} seconds.`)

local Network = {}

function Network.Event(eventName)
	return eventsStorage[eventName]
end

-- Player container getters
if IsServer then
	local PlayerContainers = NetworkRequire.Require("PlayerContainers")
	
	function Network.All()
		return PlayerContainers.All()
	end

	function Network.Single(target)
		return PlayerContainers.Single(target)
	end

	function Network.Some(...)
		return PlayerContainers.Some(...)
	end

	function Network.Except(...)
		return PlayerContainers.Except(...)
	end
end

return Network
