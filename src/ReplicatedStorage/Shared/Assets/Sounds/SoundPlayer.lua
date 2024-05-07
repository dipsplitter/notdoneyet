local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local SoundUtilities = Framework.GetShared("SoundUtilities")
local RandomUtilities = Framework.GetShared("RandomUtilities")
local InstanceCreator = Framework.GetShared("InstanceCreator")
local TableUtilities = Framework.GetShared("TableUtilities")

local RunService = game:GetService("RunService")
local IsClient = RunService:IsClient()

local SoundPlayer = {}
SoundPlayer.__index = SoundPlayer
SoundPlayer.ClassName = "SoundPlayer"
setmetatable(SoundPlayer, BaseClass)

--[[
	Params
	
	[Sound name] = {
		All relevant sound creation data
		
		MaxInstances: how many sounds can be playing at once
		Cooldown: if number, the minimum time before another sound can be played;
		if "TimeLength", cooldown ends when sound ends
	}
]]
function SoundPlayer.new(params)
	local self = BaseClass.new()
	setmetatable(self, SoundPlayer)
	
	self.Sound = nil 
	
	local soundData = params.SoundData
	self.Parent = soundData.Parent
	
	local defaultSoundData
	
	if soundData.Sound then
		self.Sound = soundData.Sound
	else
		self.Sound, defaultSoundData = SoundUtilities.CreateSound(soundData)
	end
	
	self.ActiveClones = {}
	self.CurrentInstances = 0
	self.MaxInstances = params.MaxInstances or 30
	
	self.MaxRate = params.MaxRate or 0.05
	self.LastStartedTime = 0
	
	self.DefaultConfig = {
		Cached = true,
		Sound = self.Sound,
		Parent = self.Parent or workspace.Sounds,
	}
	if defaultSoundData then
		self.DefaultConfig = TableUtilities.Reconcile(self.DefaultConfig, defaultSoundData)
	end
	
	self:AddConnections({
		SoundEnded = self.Sound.Ended:Connect(function()
			self.Sound.Parent = self.Parent or workspace.Sounds
		end),
	})

	return self
end

function SoundPlayer:GetConfig(config)
	if config then
		config = TableUtilities.Reconcile(config, self.DefaultConfig)
	else
		config = self.DefaultConfig
	end
	
	return config
end

function SoundPlayer:IsPlaying()
	return self.Sound.IsPlaying and self.CurrentInstances == 0
end

function SoundPlayer:Play(config)
	config = self:GetConfig(config)
	
	-- Can we make any copies if the main sound is already playing?
	if self:IsPlaying() and self.MaxInstances ~= 0 then
		self:PlayCopy(config)
	else
		SoundUtilities.PlayFromConfig(config)
	end
	
end

function SoundPlayer:StopAllInstances()
	self.Sound:Stop()
	
	for sound in pairs(self.ActiveClones) do
		sound:Stop()
		-- This deletes all clones!!!
		sound.TimePosition = sound.TimeLength
	end
end

function SoundPlayer:PlayCopy(config)
	if self.CurrentInstances >= self.MaxInstances then
		return
	end
	
	if os.clock() - self.LastStartedTime < self.MaxRate then
		return
	end
	
	config = self:GetConfig(config)
	
	local soundClone = InstanceCreator.Clone(self.Sound, config)
	
	config.Sound = soundClone
	config.Sound.Playing = false
	config.Sound.TimePosition = 0
	config.Cached = false

	self.ActiveClones[soundClone] = true
	self.CurrentInstances += 1
	self.LastStartedTime = os.clock()
	
	self:AddConnections({
		[`{self.CurrentInstances}`] = soundClone.Ended:Connect(function()
			self:CleanupConnection(`{self.CurrentInstances}Destroying`, `{self.CurrentInstances}`)
			
			if not soundClone then
				return
			end
			self.ActiveClones[soundClone] = nil
			self.CurrentInstances -= 1
		end),
		
		[`{self.CurrentInstances}Destroying`] = soundClone.Ended:Connect(function()
			self:CleanupConnection(`{self.CurrentInstances}`, `{self.CurrentInstances}Destroying`)

			if not soundClone then
				return
			end
			self.ActiveClones[soundClone] = nil
			self.CurrentInstances -= 1
		end),
	})
	
	SoundUtilities.PlayFromConfig(config)
	
	return soundClone
end

function SoundPlayer:Destroy()
	self.Parent = nil
	
	self.Sound:Destroy()
	self.Sound = nil
	
	for sound in pairs(self.ActiveClones) do
		sound:Destroy()
	end
	
	self:BaseDestroy()
end

return SoundPlayer