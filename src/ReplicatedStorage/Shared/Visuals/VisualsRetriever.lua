 local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)

local EnumService = Framework.GetShared("EnumService")
local VisualsEnum = EnumService.GetEnum("Enum_VisualEffects")

local VisualsFolder = script.Parent
local VisualsStorage = VisualsFolder.Storage

--[[
	Format for Storage:
	Visual name
	-> Instances
	-> ModuleScript (optional)
]]

local VisualsRetriever = {}

function VisualsRetriever.GetScript(visualName)
	return VisualsStorage:FindFirstChild(visualName, true)
end

function VisualsRetriever.GetModule(visualName)
	local module = VisualsStorage:FindFirstChild(visualName, true)
	if module then
		return require(module)
	end
end

function VisualsRetriever.GetInstances(visualName)
	return VisualsStorage:FindFirstChild(visualName):FindFirstChild("Instances")
end

return VisualsRetriever
