local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)

local Client = Framework.GetClient("Client")
local localPlayer = Client.LocalPlayer

local Debris = game:GetService("Debris")

local CollectionService = game:GetService("CollectionService")
local tag = `ReplicatedFrom{localPlayer.Name}`

local ReplicatedSoundRemover = {}

CollectionService:GetInstanceAddedSignal(tag):Connect(function()
	local replicatedSounds = CollectionService:GetTagged(tag)

	for i, sound in pairs(replicatedSounds) do
		Debris:AddItem(sound, 0)
	end
end)

return ReplicatedSoundRemover
