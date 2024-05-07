local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local IsClient = RunService:IsClient()
local IsServer = RunService:IsServer()

local function GetCallbackFunction(item, callback)
	return function(...)
		callback(item, ...)
	end
end

local ActionManagerConnector = {}

function ActionManagerConnector.Declare(item, connections)
	if connections.Shared then
		ActionManagerConnector.DeclareActionConnections(item, connections.Shared)
	end

	if IsClient and connections.Client then
		ActionManagerConnector.DeclareActionConnections(item, connections.Client)
	end
	
	if IsServer and connections.Server then
		ActionManagerConnector.DeclareActionConnections(item, connections.Server)
	end
end

-- Events for a particular action
function ActionManagerConnector.DeclareActionEventConnections(item, actionName, callbackMap)
	local actionManager = item:GetActionManager()

	local connectionsTable = {}

	for eventName, callback in callbackMap do
		connectionsTable[`{actionName}{eventName}Connection`] = actionManager:GetActionEventSignal(actionName, eventName):Connect(
			GetCallbackFunction(item, callback)
		)
	end

	item:AddConnections(connectionsTable)
end

-- The general started and ended events for any action
function ActionManagerConnector.DeclareActionConnections(item, callbackMap)
	local actionManager = item:GetActionManager()

	local connectionsTable = {}

	for actionName, callback in callbackMap do
		-- This contains several events
		if type(callback) == "table" then
			ActionManagerConnector.DeclareActionEventConnections(item, actionName, callback)
			continue
		end
		
		-- Otherwise, it's the started signal
		connectionsTable[`{actionName}StartedConnection`] = actionManager:GetActionStartedSignal(actionName):Connect(
			GetCallbackFunction(item, callback)
		)
	end

	item:AddConnections(connectionsTable)
end

return ActionManagerConnector
