local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")

local SoundGroup = Framework.GetShared("SoundGroup")
local SoundPlayer = Framework.GetShared("SoundPlayer")
local AssetService = Framework.GetShared("AssetService")
local SoundUtilities = Framework.GetShared("SoundUtilities")
local TableUtilities = Framework.GetShared("TableUtilities")

local Client = Framework.GetClient("Client")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local IsClient = RunService:IsClient()
local IsServer = RunService:IsServer()

local ItemSounds = {}
ItemSounds.__index = ItemSounds
ItemSounds.ClassName = "ItemSounds"
setmetatable(ItemSounds, BaseClass)

function ItemSounds.new(params)
	local self = BaseClass.new()
	setmetatable(self, ItemSounds)
	
	if IsServer then
		self.Character = params.Character
		self.Player = Players:GetPlayerFromCharacter(self.Character)
	end
	
	self.ItemModel = params.ItemModel
	self.Sounds = {}
	self.SoundGroups = {}
	
	if params.ItemSoundData then
		self:AddSounds(params.ItemSoundData)
	end
	
	return self
end

function ItemSounds:GetFallbackSoundParent()
	local current
	if self.ItemModel then
		current = self.ItemModel.PrimaryPart or self.ItemModel:FindFirstChild("Handle")
	end
	
	local result = current or (if IsClient then Client.Character.PrimaryPart else self.Character.PrimaryPart)
	
	return result
end

function ItemSounds:AddSounds(soundsList)
	
	for soundName, soundPath in soundsList do
		local soundData = AssetService.Sounds(soundPath)

		if not soundData.Id then
			-- Create a copy of the info table so we don't edit anything
			self:CreateSoundGroup(soundName, TableUtilities.DeepCopy(soundData))
		else
			self:CreateSoundPlayer(soundName, soundPath)
		end
		
	end
end

function ItemSounds:CreateSoundGroup(soundName, soundData)
	for i, individualSoundData in pairs(soundData) do
		
		if not individualSoundData.Parent then
			individualSoundData.Parent = self:GetFallbackSoundParent()
		end
		
		if IsServer then
			individualSoundData.Player = self.Player
		end
	end
	
	self.SoundGroups[soundName] = SoundGroup.new({
		SoundList = soundData
	})
end

function ItemSounds:CreateSoundPlayer(soundName, soundPath)
	local constructorArgs = {
		SoundData = {
			SoundId = soundPath,
			Parent = self:GetFallbackSoundParent(),
		}
	}

	if IsServer then
		constructorArgs.SoundData.Player = self.Player
	end
	
	self.Sounds[soundName] = SoundPlayer.new(constructorArgs)
end

function ItemSounds:PlaySound(name, config)
	config = config or {
		Parent = self:GetFallbackSoundParent()
	}
	
	if self.Sounds[name] then
		self.Sounds[name]:Play(config)
		
	-- TODO: This only plays a random sound
	elseif self.SoundGroups[name] then
		self.SoundGroups[name]:PlayRandomSound(config)
	end
end

function ItemSounds:StopSounds(...)
	local soundNames = {...}
	for i, soundName in ipairs(soundNames) do
		if self.Sounds[soundName] then
			self.Sounds[soundName]:Stop()
		elseif self.SoundGroups[soundName] then
			self.SoundGroups[soundName]:StopSounds(...)
		end
	end
end

function ItemSounds:StopAllSounds()
	for soundName, sound in pairs(self.Sounds) do
		sound:StopAllInstances()
	end
	
	for soundName, group in pairs(self.SoundGroups) do
		group:StopAllSounds()
	end
end

function ItemSounds:Destroy()
	for k, v in pairs(self.Sounds) do
		v:Destroy()
	end
	
	for k, v in pairs(self.SoundGroups) do
		v:Destroy()
	end
	
	self:BaseDestroy()
end

return ItemSounds
