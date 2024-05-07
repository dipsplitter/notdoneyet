local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Signal = Framework.GetShared("Signal")

local characterList = {}
local removeConnections = {}

local CharacterRegistry = {
	CurrentId = 1,
	
	CharacterAdded = Signal.new(),
	CharacterRemoved = Signal.new(),
}

function CharacterRegistry.Insert(character)
	local id = character.Id
	characterList[id] = character
	
	CharacterRegistry.CharacterAdded:Fire(id, character)
	
	removeConnections[id] = character.Signals.Destroying:Connect(function()
		removeConnections[id]:Disconnect()
		removeConnections[id] = nil
		
		CharacterRegistry.RemoveById(id)
	end)
end

function CharacterRegistry.RemoveByModel(model)
	if not model then
		return
	end
	
	characterList[model:GetAttribute("CharacterID")] = nil
end

function CharacterRegistry.RemoveById(id)
	CharacterRegistry.CharacterRemoved:Fire(id)
	
	characterList[id] = nil
end

function CharacterRegistry.GetCharacterFromModel(model)
	if not model then
		return
	end
	
	local id = CharacterRegistry.GetId(model)
	
	return characterList[id]
end

function CharacterRegistry.GetClass(model)
	return CharacterRegistry.GetCharacterFromModel(model).Class
end

function CharacterRegistry.GetId(object)
	if typeof(object) == "Instance" and object:IsA("Model") then
		return object:GetAttribute("CharacterID")
	end
	
	if type(object) == "table" then
		return object.Id
	end
	
	return object :: number
end

function CharacterRegistry.GetModelFromId(id)
	return characterList[id].ActiveModel.Model
end

return CharacterRegistry
