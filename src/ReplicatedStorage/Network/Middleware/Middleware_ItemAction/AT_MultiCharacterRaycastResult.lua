local RunService = game:GetService("RunService")
local IsClient = RunService:IsClient()
local IsServer = RunService:IsServer()

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local ReadBuffer = Framework.GetShared("ReadBuffer")

local CharacterRegistry = Framework.GetShared("CharacterRegistry")
local CharacterEnumeratedChildren = Framework.GetShared("CharacterEnumeratedChildren")
local CharacterUtilities = Framework.GetShared("CharacterUtilities")

--[[
	Structure:
	
	Number of characters hit
	
	Each character:
	
		Character ID
		Number of child instances hit

	Each instance hit:

		Instance ID
		Number of casts that hit it
	
		* Below is likely unnecessary
		Each cast:
			
			Raycast ID
]]

local AT_MultiCharacterRaycastResult = {}

function AT_MultiCharacterRaycastResult.PreSerialize(raycastResultArray)
	
	local results = {
		CharacterCount = 0
	}
	
	for raycastId, result in raycastResultArray.Args do
		if not result or type(result) ~= "table" then
			continue
		end
		
		local hitInstance = result.Instance
		local hitCharacter = CharacterUtilities.GetCharacterFromPart(hitInstance)
		
		if not hitCharacter then
			continue
		end
		
		local characterId = hitCharacter:GetAttribute("CharacterID")
		
		local instanceId = CharacterEnumeratedChildren.ToIndex(characterId, hitInstance.Name)
		
		if not results[characterId] then
			results[characterId] = {
				InstanceCount = 0
			}
			results.CharacterCount += 1
		end
		
		if not results[characterId][instanceId] then
			results[characterId][instanceId] = {}
			results[characterId].InstanceCount += 1
		end
		
		table.insert(results[characterId][instanceId], raycastId)
	end
	
	results.SIGNATURE = "MultiCharacterRaycastResult"
	
	raycastResultArray.Args = results
	return raycastResultArray
end

function AT_MultiCharacterRaycastResult.Serialize(raycastResults, queue, structure)
	
	queue:writeu8(raycastResults.CharacterCount)
	
	for characterId, instances in raycastResults do
		-- Skip "CharacterCount" key
		if type(characterId) ~= "number" then
			continue
		end
		
		queue:writeu16(characterId)
		queue:writeu8(instances.InstanceCount)
		
		for instanceId, raycastIdList in instances do
			-- Skip "InstanceCount" key
			if type(instanceId) ~= "number" then
				continue
			end
			
			queue:writeu8(instanceId)
			queue:writeu8(#raycastIdList)
			
			for i, raycastId in raycastIdList do
				queue:writeu8(raycastId)
			end
		end
	end
end

--[[
	Format:

	Raycast ID:
		
		Character: the model we hit
		HitInstance: the string name of the character descendant we hit
]]
function AT_MultiCharacterRaycastResult.Deserialize(stream, cursor, structure)
	local readBuffer = ReadBuffer.new(stream, cursor)
	local characterCount = readBuffer:readu8()
	
	local deserialized = {}
	
	for i = 1, characterCount do
		local charId = readBuffer:readu16()
		
		local character = CharacterRegistry.GetModelFromId(charId)
		
		local instanceCount = readBuffer:readu8()
		
		for j = 1, instanceCount do
			local instanceId = readBuffer:readu8()
			
			local instanceName = CharacterEnumeratedChildren.ToChildName(character, instanceId)
			
			local raycastHits = readBuffer:readu8()
			
			for k = 1, raycastHits do
				local raycastId = readBuffer:readu8()
				
				deserialized[raycastId] = {
					Character = character,
					HitInstance = instanceName
				}
			end
		end
	end
	
	return deserialized, readBuffer:GetBytesRead()
end

return AT_MultiCharacterRaycastResult
