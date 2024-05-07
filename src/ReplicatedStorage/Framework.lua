local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local IsServer = RunService:IsServer()
local IsClient = RunService:IsClient()

local CLIENT
if IsClient then
	CLIENT = Players.LocalPlayer.PlayerScripts:WaitForChild("Client")
end

local SHARED = ReplicatedStorage.Shared
local SERVER = ServerStorage
local NETWORK = ReplicatedStorage.Network
local NetworkRequire = require(NETWORK.NetworkRequire)

local function WaitForDescendant(ancestor, descendantName, className)
	local instance = ancestor:FindFirstChild(descendantName, true) -- Recursive

	if not instance then
		local startTime = os.clock()

		local connection
		connection = ancestor.DescendantAdded:Connect(function(descendant)
			if descendant.Name == descendantName and descendant.ClassName == className then
				instance = descendant
			end
		end)

		while not instance do
			if startTime ~= nil and os.clock() - startTime > 5 and (IsServer or game:IsLoaded()) then
				startTime = nil
				warn(`Infinite yield: {descendantName} ({className}) under {ancestor}: {debug.traceback()}`)
			end
			task.wait()
		end

		connection:Disconnect()
		return instance
	else
		return instance
	end
end

local function AddModulesToTable(parent, tab)
	if next(tab) ~= nil then
		return
	end
	
	for i, descendant in pairs(parent:GetDescendants()) do
		if not descendant:IsA("ModuleScript") then
			continue
		end
		
		local folder = descendant:FindFirstAncestorWhichIsA("Folder")
		if folder and folder:GetAttribute("ExcludeFromCache") then
			continue
		end
		
		if not descendant:GetAttribute("ExcludeFromCache") then
			tab[descendant.Name] = descendant
		end
	end
end

local function GetModuleFromPath(pathToModule, location)
	-- If we didn't include a string path
	local existingModule = location[pathToModule]
	if existingModule then
		return existingModule
	end
	
	local path = string.split(pathToModule, ".")
	local moduleName = path[#path]

	for name, moduleScript in pairs(location) do
		if name ~= moduleName then
			continue
		end
		
		if moduleScript:GetFullName():match(pathToModule) then
			return moduleScript
		end
	end
end

local Framework = {
	["IsServer"] = IsServer,
	["IsClient"] = IsClient,
}

Framework.Shared = {}
AddModulesToTable(SHARED, Framework.Shared)

if IsClient then
	Framework.Client = {}
	AddModulesToTable(CLIENT, Framework.Client)
elseif IsServer then
	Framework.Server = {}
	AddModulesToTable(SERVER, Framework.Server)
end

function Framework.GetClient(name, shouldWait)
	if not IsClient then
		return
	end
	
	local result = GetModuleFromPath(name, Framework.Client)
	if result then
		return require(result)
	end
	
	local potentialName = `C_{name}`
	result = GetModuleFromPath(potentialName, Framework.Client)
	
	if result then
		return require(result)
	end
	
	shouldWait = (shouldWait == nil) or shouldWait
	if shouldWait then
		return require(WaitForDescendant(CLIENT, potentialName, "ModuleScript"))
	end
end

function Framework.GetShared(name, shouldWait)
	local result = GetModuleFromPath(name, Framework.Shared)
	if result then
		return require(result)
	end
	
	shouldWait = (shouldWait == nil) or shouldWait
	if shouldWait then
		return require(WaitForDescendant(SHARED, name, "ModuleScript"))
	end
end

function Framework.GetServer(name, shouldWait)
	if not IsServer then
		return
	end
	
	local result = GetModuleFromPath(name, Framework.Server)
	if result then
		return require(result)
	end
	

	local potentialName = `S_{name}`
	result = GetModuleFromPath(potentialName, Framework.Server)

	if result then
		return require(result)
	end
	
	shouldWait = (shouldWait == nil) or shouldWait
	if shouldWait then
		return require(WaitForDescendant(SERVER, potentialName, "ModuleScript"))
	end
end

function Framework.Network()
	return require(NETWORK.Network)
end

function Framework.RequireNetworkModule(networkModuleName)
	return NetworkRequire.Require(networkModuleName)
end

function Framework.DefaultTrue(val)
	return (val == nil) or val
end

function Framework.DefaultFalse(val)
	return val or (val == nil and false)
end

function Framework.IsObject(tab)
	return type(tab) == "table" and getmetatable(tab)
end

--[[
function Framework.AttachMethods(object, methodTable)
	for methodName, method in methodTable do
		-- Don't attach constructors! 
		if methodName == "new" then
			continue
		end
		
		object[methodName] = method
	end
end
]]

return Framework