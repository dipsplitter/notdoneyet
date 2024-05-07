local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local NetworkFolder = ReplicatedStorage.Network
local ProcessesFolder = NetworkFolder.Processes

local IsServer = RunService:IsServer()
local IsClient = RunService:IsClient()

local DEFAULT_PROCESS = if IsServer then ProcessesFolder.Main.ServerMain else ProcessesFolder.Main.ClientMain

local NetworkRequire = {}

function NetworkRequire.Require(moduleName)
	return require(NetworkFolder:FindFirstChild(moduleName, true))
end

function NetworkRequire.RequireProcess(processName)
	local moduleName = if IsServer then `Server{processName}` else `Client{processName}`
	
	local targetModule = ProcessesFolder:FindFirstChild(moduleName, true)
	if targetModule then
		return require(targetModule)
	end
	
	return require(DEFAULT_PROCESS)
end

function NetworkRequire.Event(name)
	return require(NetworkFolder.EventsStorage[name])
end

return NetworkRequire
