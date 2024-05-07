local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local RandomUtilities = Framework.GetShared("RandomUtilities")
local SoundPlayer = Framework.GetShared("SoundPlayer")
local SoundUtilities = Framework.GetShared("SoundUtilities")

local RunService = game:GetService("RunService")
local IsClient = RunService:IsClient()

local SoundGroup = {}
SoundGroup.__index = SoundGroup
SoundGroup.ClassName = "SoundGroup"
setmetatable(SoundGroup, BaseClass)

--[[
	Params
	
	[Sound name] = {
		All relevant sound creation data
		
		MaxInstances: how many sounds can be playing at once
		Cooldown: if number, the minimum time before another sound can be played;
		if "TimeLength", cooldown ends when sound ends
	}
]]
function SoundGroup.new(params)
	local self = BaseClass.new()
	setmetatable(self, SoundGroup)
	
	self.SoundsList = {}
	
	--[[
		[Sound name] = {
			Count: how many sound clones are currently playing
			LastStartedTime: last time a sound played
		}
	]]
	self.MaxPlayingSounds = params.MaxPlayingSounds

	self:AddSounds(params.SoundList)
	
	return self
end

function SoundGroup:AddSounds(soundList)
	for soundName, soundInfo in pairs(soundList) do
		self.SoundsList[soundName] = SoundPlayer.new({
			SoundData = soundInfo,
		})
	end
end

function SoundGroup:IsPlaying(soundName)
	return self.SoundsList[soundName]:IsPlaying()
end

function SoundGroup:PlaySound(soundName, config)
	self.SoundsList[soundName]:Play(config)
end

function SoundGroup:PlayRandomSound(config)
	local randomSoundName = RandomUtilities.SelectRandomKeyFromWeightedTable(self.SoundsList)
	self:PlaySound(randomSoundName, config)
end

function SoundGroup:RemoveSound(soundName)
	if self.SoundsList[soundName] then
		self.SoundsList[soundName]:Destroy()
		self.SoundsList[soundName] = nil
	end
end

function SoundGroup:StopSounds(...)
	local soundNames = {...}
	for i, soundName in ipairs(soundNames) do
		if self.SoundsList[soundName] then
			self.SoundsList[soundName]:Destroy()
		end
	end
end

function SoundGroup:StopAllSounds()
	for k, v in pairs(self.SoundsList) do
		v:StopAllInstances()
	end
end

function SoundGroup:Destroy()
	for soundName, soundPlayer in pairs(self.SoundsList) do
		soundPlayer:Destroy()
	end
	
	self:BaseDestroy()
end

return SoundGroup