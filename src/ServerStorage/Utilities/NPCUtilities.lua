local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local TableUtilities = Framework.GetShared("TableUtilities")

local NPCUtilities = {}

function NPCUtilities.GetStats(name)
	local module = Framework.GetShared(name)
	return TableUtilities.DeepCopy(module.Stats)
end

return NPCUtilities
