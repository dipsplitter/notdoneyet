local CharacterUtilities = {}

function CharacterUtilities.GetCharacterFromPart(part)
	local model = part:FindFirstAncestorWhichIsA("Model")
	
	if model:GetAttribute("CharacterID") then
		return model
	end
end

function CharacterUtilities.IsDescendantOf(instance, compareTo)
	if typeof(compareTo) ~= "Instance" then
		return false
	end

	if compareTo:IsA("Model") then
		return instance:FindFirstAncestorWhichIsA("Model") == compareTo 
			or instance:IsDescendantOf(compareTo) 
			or instance == compareTo
	end

	return true
end

return CharacterUtilities
