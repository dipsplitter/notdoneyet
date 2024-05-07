local InstanceUtilities = {}

function InstanceUtilities.GetModelAncestor(part)
	return part:FindFirstAncestorWhichIsA("Model")
end

function InstanceUtilities.GetCharacterAncestor(part)
	local model = part:FindFirstAncestorWhichIsA("Model")
	if not model then
		return
	end
	
	if model:GetAttribute("CharacterID") then
		return model
	end
end

function InstanceUtilities.FindFirstChildOfClassNameAndName(parent, className, name)
	for i, child in parent:GetChildren() do
		if child.ClassName == className and child.Name == name then
			return child
		end
	end
end

return InstanceUtilities
