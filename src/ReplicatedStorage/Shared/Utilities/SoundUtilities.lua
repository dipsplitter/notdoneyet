local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local InstanceCreator = Framework.GetShared("InstanceCreator")
local RbxAssets = Framework.GetShared("RbxAssets")
local Promise = Framework.GetShared("Promise")
local AssetService = Framework.GetShared("AssetService")
local RandomUtilities = Framework.GetShared("RandomUtilities")
local TableUtilities = Framework.GetShared("TableUtilities")

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local IsServer = RunService:IsServer()

local SoundPosition = script.SoundPosition
local SoundTemplate = script.SoundTemplate

local function CleanupSound(sound)
	if sound.IsLoaded then
		return Promise.Resolve()
	end
	
	return Promise.FromEvent(sound.Loaded, function()
		return true
	end)
end

local function GetSoundId(id)
	local soundId = id
	local soundData
	
	if type(id) == "string" and string.find(id, ".", 1, true) then
		-- It's a path
		soundData = AssetService.Sounds(id)
		-- We got a sound group, so select a random one
		if not soundData.Id then
			local soundName = RandomUtilities.SelectRandomKeyFromWeightedTable(soundData)
			soundId = soundData[soundName].Id
		else
			soundId = soundData.Id
		end
		
	end
	
	soundId = RbxAssets.ToRbxAssetId(soundId)
	return soundId, soundData
end

local function ParentSoundAtPosition(sound, position)
	local positionPart = InstanceCreator.Clone(SoundPosition, {
		Position = position
	})
	sound.Parent = sound
end

local function TagSoundAsReplicated(sound, player)
	if IsServer then
		CollectionService:AddTag(sound, `ReplicatedFrom{player.Name}`)
	end
end

local SoundUtilities = {}

function SoundUtilities.ScheduleSoundForDeletion(sound, config)
	if config.Cached then
		return
	end

	CleanupSound(sound):AndThen(function()
		local connection
		connection = sound.Ended:Connect(function()
			connection:Disconnect()
			Debris:AddItem(sound, 0)
		end)
	end)
end

function SoundUtilities.CreateSound(properties)
	local soundId, defaultSoundData = GetSoundId(properties.SoundId or properties.Id)
	
	if defaultSoundData then
		properties = TableUtilities.Reconcile(properties, defaultSoundData)
	end
	properties.SoundId = soundId

	local soundClone = InstanceCreator.Clone(SoundTemplate, properties)
	
	if properties.Position then
		ParentSoundAtPosition(soundClone, properties.Position)
	end
	
	if properties.Player then
		TagSoundAsReplicated(soundClone, properties.Player)
	end
	
	return soundClone
end


--[[
	Config:
	
	Sound: the sound object to play
	SoundId: can be rbxassetid or path to sound; if this is a path to a sound group, it randomly selects and plays from the group
	Any valid sound property (e.g. Volume, PlaybackSpeed)
	Cached: if true, does not automatically destroy the sound when it ends playback
	PlayOption: name of function to play sound with; default is PlaySound
	Any arguments to the PlayOption function (e.g. PitchRange for PlayWithRandomPitch)
]]
function SoundUtilities.PlayFromConfig(config)
	if not config.Sound then
		
		if not config.SoundId then
			return
		end
		
	end
	config.PlayOption = config.PlayOption or "PlaySound"

	local sound = config.Sound or SoundUtilities.CreateSound(config)
	
	SoundUtilities[config.PlayOption](sound, config)
end

function SoundUtilities.PlaySound(sound, config)
	SoundUtilities.ScheduleSoundForDeletion(sound, config)
	sound:Play()
end

function SoundUtilities.PlayWithRandomPitch(sound, pitchRange)
	
end

return SoundUtilities
