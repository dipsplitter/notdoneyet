local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local ReadBuffer = Framework.GetShared("ReadBuffer")

local CharacterUtilities = Framework.GetShared("CharacterUtilities")

return function(argsTable)
	local results = argsTable.Args
	
	local formatted = {}
	
	for raycastId, result in results do
		if not result or type(result) ~= "table" then
			continue
		end

		local hitInstance = result.Instance
		local hitCharacter = CharacterUtilities.GetCharacterFromPart(hitInstance)
		
		if not hitCharacter then
			continue
		end
		
		formatted[raycastId] = {
			Character = hitCharacter,
			HitInstance = hitInstance,
		}
	end
	
	argsTable.Args = formatted
	
	return argsTable
end