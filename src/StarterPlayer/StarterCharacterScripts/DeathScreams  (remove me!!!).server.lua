local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local AssetService = Framework.GetShared("AssetService")
local RandomUtilities = Framework.GetShared("RandomUtilities")
local SoundUtilties = Framework.GetShared("SoundUtilities")

local deathSounds = AssetService.Sounds(`Death.Screams`)
local character = script.Parent
local humanoid = character.Humanoid

humanoid.Died:Once(function()
	local id = deathSounds[RandomUtilities.SelectRandomKeyFromDictionary(deathSounds)].Id
	
	local sound = SoundUtilties.CreateSound({
		Id = id,
		Parent = character.PrimaryPart
	})
	SoundUtilties.PlaySound(sound, {})
end)

