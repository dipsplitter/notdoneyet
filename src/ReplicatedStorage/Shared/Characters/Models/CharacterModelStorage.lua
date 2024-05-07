local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local TableUtilities = Framework.GetShared("TableUtilities")

local Models = script.Parent

local CharacterModelStorage = {}

function CharacterModelStorage.GetModel(path)
	local arrayPath = TableUtilities.StringPathToArray(path)
	
	local current = Models
	for i, destination in arrayPath do
		local nextLocation = current:FindFirstChild(destination)
		if not nextLocation then
			break
		end
		current = nextLocation
	end
	
	return current
end

return CharacterModelStorage
