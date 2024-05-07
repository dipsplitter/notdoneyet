local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local CharacterRegistry = Framework.GetShared("CharacterRegistry")

local CharactersFolder = workspace.Characters

local indexToChildName = {}
local childNameToIndex = {}

local function RegisterChildren(character)
	local charId = character:GetAttribute("CharacterID")

	indexToChildName[charId] = {}
	childNameToIndex[charId] = {}

	local lookup, reverse = indexToChildName[charId], childNameToIndex[charId]

	local index = 0
	for i, child in character:GetChildren() do
		if not child:IsA("BasePart") then
			continue
		end

		lookup[index] = child.Name
		reverse[child.Name] = index
		index += 1

		local hitbox = child:FindFirstChild(`{child.Name}Hitbox`)
		if not hitbox then
			continue
		end

		lookup[index] = hitbox.Name
		reverse[hitbox.Name] = index
		index += 1
	end
	
	-- Bounding box is final index
	lookup[index] = "BoundingBox"
	reverse.BoundingBox = index
	index += 1
	
	character.DescendantAdded:Connect(function(descendant)
		if not descendant:IsA("BasePart") then
			return
		end
		
		lookup[index] = descendant.Name
		reverse[descendant.Name] = index
		index += 1
	end)
end

local CharacterEnumeratedChildren = {}

function CharacterEnumeratedChildren.ToChildName(char, id)
	if type(char) == "number" then
		char = CharacterRegistry.GetModelFromId(char)
	end
	
	return indexToChildName[char:GetAttribute("CharacterID")][id]
end

function CharacterEnumeratedChildren.ToIndex(char, childName)
	if type(char) == "number" then
		char = CharacterRegistry.GetModelFromId(char)
	end
	
	return childNameToIndex[char:GetAttribute("CharacterID")][childName]
end

for i, character in CharactersFolder:GetChildren() do
	RegisterChildren(character)
end

CharactersFolder.ChildAdded:Connect(RegisterChildren)

CharactersFolder.ChildRemoved:Connect(function(character)
	CharacterEnumeratedChildren[character:GetAttribute("CharacterID")] = nil
end)

return CharacterEnumeratedChildren