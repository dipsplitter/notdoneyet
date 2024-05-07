--[[
	Purpose is to require stuff from the Network folder because I decided it was so special it didn't deserve to go under Shared...
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NetworkFolder = ReplicatedStorage.Network
local NetworkModule = NetworkFolder.Network
local RemoteEventsFolder = NetworkFolder.Remotes

local modules = {}
for i, descendant in NetworkFolder:GetDescendants() do
	if not descendant:IsA("ModuleScript") then
		continue
	end
	
	-- Ignore middleware
	if descendant.Parent.Name == "Middleware" then
		continue
	end
	
	local name = descendant.Name
	
	if name == "Client" or name == "Server" then
		continue
	end
	
	modules[name] = descendant
end
	
	
local NetworkRequire = {}

function NetworkRequire.Require(name)
	return require(modules[name])
end

function NetworkRequire.GetRemoteEvent(name)
	return RemoteEventsFolder:FindFirstChild(name, true)
end

return NetworkRequire
