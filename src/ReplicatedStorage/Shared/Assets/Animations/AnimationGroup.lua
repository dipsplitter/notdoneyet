local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local RandomUtilities = Framework.GetShared("RandomUtilities")
local AnimationEventsUtilities = Framework.GetShared("AnimationEventsUtilities")
local Signal = Framework.GetShared("Signal")

local AnimationGroup = {}
AnimationGroup.__index = AnimationGroup
AnimationGroup.ClassName = "AnimationGroup"
setmetatable(AnimationGroup, BaseClass)

function AnimationGroup.new(params)
	local self = BaseClass.new()
	setmetatable(self, AnimationGroup)
	
	self.Prefix = params.Prefix
	
	self.Tracks = {}
	self.TrackIdToName = {}
	
	self.WeightedAnimations = {}
	
	if params.Tracks then
		for i, animationTrack in params.Tracks do
			self:AddAnimation(animationTrack)
		end
	end
	
	self.CurrentTrack = nil
	
	return self
end

function AnimationGroup:FromAssetId(assetId)
	for name, track in self.WeightedAnimations do
		if track.Track.Animation.AnimationId == assetId then
			return track
		end
	end
end

function AnimationGroup:SetEventSignal(signal)
	for name, track in self.WeightedAnimations do
		track:SetEventSignal(signal)
	end
end

function AnimationGroup:AddModifiers(dict)
	for name, modifiers in dict do
		local animation = self.WeightedAnimations[name] or self:FindAnimationFromAbbreviation(name)
		if not animation then
			continue
		end
		
		animation:AddModifiers(modifiers)
	end
end

function AnimationGroup:AddAnimation(track)
	self.WeightedAnimations[track.Name] = track
	
	self.Tracks[self:GetAbbreviatedAnimationTrackName(track.Name)] = track
end

function AnimationGroup:AddAnimations(animations)
	for k, v in pairs(animations) do
		self:AddAnimation(v)
	end
end

function AnimationGroup:Play(properties)
	local name = if properties then properties.Name else nil
	
	if not name then
		self:PlayRandom(properties)
	else
		self:PlayFromName(name, properties)
	end
end

function AnimationGroup:PlayRandom(properties)
	local selectedAnimationName = self:Select()
	local animation = self.WeightedAnimations[selectedAnimationName]

	animation:Play(properties)
	self.CurrentTrack = animation
end

function AnimationGroup:PlaySequentially(transitionTime)
	
end

function AnimationGroup:FindAnimationFromAbbreviation(abbreviated)
	for animationName, animationObject in self.WeightedAnimations do
		if string.find(animationName, abbreviated, #self.Prefix) then
			return animationObject
		end
	end
end

function AnimationGroup:GetAbbreviatedAnimationTrackName(fullTrackName)
	return string.sub(fullTrackName, #self.Prefix + 2)
end

function AnimationGroup:PlayFromName(name, properties)
	local animation = self.WeightedAnimations[name] or self:FindAnimationFromAbbreviation(name)
	
	if not animation then
		return
	end
	
	animation:Play(properties)
	self.CurrentTrack = animation
end

function AnimationGroup:GetAnimation(name)
	return self.WeightedAnimations[name] or self:FindAnimationFromAbbreviation(name)
end

function AnimationGroup:Stop(fadeTime)
	if not self.CurrentTrack then
		return
	end
	
	self.CurrentTrack:Stop(fadeTime)
	self.CurrentTrack = nil
end

function AnimationGroup:Select()
	return RandomUtilities.SelectRandomKeyFromWeightedTable(self.WeightedAnimations, "GroupWeight")
end

function AnimationGroup:Destroy()
	self.CurrentTrack = nil
	self.WeightedAnimations = nil
	
	self.TrackIdToName = nil
	self.Tracks = nil
	
	self:BaseDestroy()
end

return AnimationGroup

