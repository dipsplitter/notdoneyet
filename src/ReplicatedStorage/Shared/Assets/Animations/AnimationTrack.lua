local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local Value = Framework.GetShared("Value")
local RbxAssets = Framework.GetShared("RbxAssets")
local ValueRetriever = Framework.GetShared("ValueRetriever")
local DynamicNumberValue = Framework.GetShared("DynamicNumberValue")
local TableUtilities = Framework.GetShared("TableUtilities")

local AnimationKeyframeMarkerCache = Framework.GetShared("AnimationKeyframeMarkerCache")

local DefaultProperties = {
	FadeTime = 0.00001,
	Weight = 1,
	Speed = 1,
	GroupWeight = 1,
	ReplayIfPlaying = true,
}

local AnimationTrack = {}
AnimationTrack.__index = AnimationTrack
AnimationTrack.ClassName = "AnimationTrack"
setmetatable(AnimationTrack, BaseClass)

function AnimationTrack.new(params)
	local self = BaseClass.new()
	setmetatable(self, AnimationTrack)
	
	self.Track = params.AnimationTrack
	self.Name = self.Track.Animation.Name
	
	self.Track:SetAttribute("Name", self.Name)
	
	--[[
		CONFIG:
		Weight
		FadeTime (default), 
		Duration 
		Speed
		Looped?
		Priority
		GroupWeight
		ReplayIfPlaying
	]]

	self.Properties = TableUtilities.Reconcile(params.Properties, DefaultProperties) or DefaultProperties
	
	if not self.Properties.Duration then
		self.Properties.Duration = self.Track.Length
	end

	self.Cleaner:Add(self.Track)
	self.Cleaner:Add(function()
		self:Stop(0)
	end)
	
	self.CurrentSpeedModifier = DynamicNumberValue.new(1, params.SpeedModifiers)
	self.CurrentDurationModifier = DynamicNumberValue.new(self.Track.Length)
	if params.DurationModifiers then
		self.CurrentDurationModifier:AddBaseValueSetter(params.DurationModifiers)
	end
	
	self:AddConnections({
		AutoAdjustSpeed = self.CurrentSpeedModifier:ConnectTo("ValueChanged", function(new, old)
			if not self:IsPlaying() then
				return
			end
			
			self.Track:Adjust({Speed = new / old})
		end),
		
		AutoAdjustSpeedBasedOnDuration = self.CurrentDurationModifier:ConnectTo("ValueChanged", function(new, old)
			if not self:IsPlaying() then
				return
			end
			
			self.Track:Adjust({Speed = (self.Properties.Duration / new) * old})
		end),
	})
	self:SetupMarkerConnections()
	
	return self
end

function AnimationTrack:SetupMarkerConnections()
	local markerArray = AnimationKeyframeMarkerCache[self.Name]
	if not markerArray then
		return
	end
	
	local connectionsTable = {}
	for i, eventName in markerArray do
		if connectionsTable[`{eventName}MarkerSignal`] then
			continue
		end
		
		connectionsTable[`{eventName}MarkerSignal`] = self.Track:GetMarkerReachedSignal(eventName):Connect(function(params)
			if not self.EventSignal then
				return
			end

			self.EventSignal:Fire(eventName, self.Name, params)
		end)
	end
	
	self:AddConnections(connectionsTable)
end

function AnimationTrack:SetEventSignal(signal)
	self.EventSignal = signal
end

function AnimationTrack:GetEvent(eventName)
	return self.Track:GetMarkerReachedSignal(eventName)
end

function AnimationTrack:AddModifiers(dict)
	if dict.Speed then
		self:AddSpeedModifiers(dict.Speed)
	end
	
	if dict.Duration then
		self:AddDurationModifiers(dict.Duration)
	end
end

function AnimationTrack:AddSpeedModifiers(modifiersTable)
	self.CurrentSpeedModifier:AddModifiers(modifiersTable)
end

function AnimationTrack:AddDurationModifiers(modifiersTable)
	self.CurrentDurationModifier:AddBaseValueSetter(modifiersTable)
end

function AnimationTrack:IsPlaying()
	return self.Track.IsPlaying
end

function AnimationTrack:GetPlaybackSpeed()
	local duration = self.Properties.Duration
	
end

-- Configs can include functions to be called on keyframe events / end
function AnimationTrack:Play(properties)
	if self:IsPlaying() and not self.Properties.ReplayIfPlaying then
		self:Adjust(properties)
		return
	end
	
	if properties == nil or properties.Name then
		properties = self.Properties
	end
	
	self.Track.Looped = Framework.DefaultFalse(properties.Looped)
	
	self.Track.Priority = properties.Priority or self.Track.Priority
	
	local speed = (properties.Speed or 1) * self.CurrentSpeedModifier.Value
	if self.CurrentDurationModifier.Value ~= 0 then
		speed *= self.Properties.Duration / self.CurrentDurationModifier.Value
	end
	
	self.Track:Play(properties.FadeTime, properties.Weight, speed)
end

function AnimationTrack:Adjust(newProperties)
	if not newProperties then
		return
	end
	
	local calculatedPlaybackSpeed = self.Track.Speed
	
	if newProperties.Speed then
		self.Track:AdjustSpeed(newProperties.Speed)
	end
	
	if newProperties.Duration then
		calculatedPlaybackSpeed /= newProperties.Duration
		
		self.Track:AdjustSpeed(calculatedPlaybackSpeed)
	end
	
	if newProperties.Priority then
		self.Track.Priority = newProperties.Priority
	end
	
	if newProperties.Weight then
		self.Track:AdjustWeight(newProperties.Weight)
	end
end

function AnimationTrack:Stop(fadeTime)
	if fadeTime then
		fadeTime = math.max(fadeTime, DefaultProperties.FadeTime)
	end
	
	self.Track:Stop(fadeTime or self.Properties.StopTime)
end

return AnimationTrack
