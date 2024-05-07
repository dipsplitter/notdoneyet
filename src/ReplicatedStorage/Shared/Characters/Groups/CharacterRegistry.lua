local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Signal = Framework.GetShared("Signal")

local CharactersFolder = workspace.Characters

local characters = {}

local CharacterRegistry = {
	CharacterAdded = Signal.new(),
	CharacterRemoved = Signal.new(),
}

function CharacterRegistry.GetModelFromId(id)
	return characters[id]
end

for i, character in CharactersFolder:GetChildren() do
	characters[character:GetAttribute("CharacterID")] = character
end

CharactersFolder.ChildAdded:Connect(function(character)
	local id = character:GetAttribute("CharacterID")
	characters[id] = character
	CharacterRegistry.CharacterAdded:Fire(character)
end)

CharactersFolder.ChildRemoved:Connect(function(character)
	local id = character:GetAttribute("CharacterID")
	characters[id] = nil
	CharacterRegistry.CharacterRemoved:Fire(character)
end)

return CharacterRegistry
