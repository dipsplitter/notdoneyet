local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local AnimationUtilities = Framework.GetShared("AnimationUtilities")
local TableListener = Framework.GetShared("TableListener")
local TableUtilities = Framework.GetShared("TableUtilities")
local ItemAnimationModifiers = Framework.GetShared("ItemAnimationModifiers")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local IsClient = RunService:IsClient()
local IsServer = RunService:IsServer()

local function AddImplicitModifiers(name, track, trackInfo, item)
	if type(trackInfo) == "string" then
		return
	end
	
	local animationModule = trackInfo.Module
	
	-- For custom scripted animations
	if trackInfo.Custom and animationModule then
		require(animationModule).Wrap(track, item)
		return
	end
	
	-- Connect custom animation script
	if animationModule then
		require(animationModule).Wrap(track, item)
	end
	
	if name == "Equip" then
		-- Add equip speed modifiers
	elseif name == "Unequip" then
		-- Add unequip speed modifiers (having unequip animation implies a nonzero unequip speed)
	else
		ItemAnimationModifiers.AddActionBasedModifiers(item, track, trackInfo)
	end
end

local ItemAnimator = {}
ItemAnimator.__index = ItemAnimator
ItemAnimator.ClassName = "ItemAnimator"
setmetatable(ItemAnimator, BaseClass)

function ItemAnimator.new(item)
	local self = BaseClass.new()
	setmetatable(self, ItemAnimator)
	
	self.Animations = {}
	self.AnimationGroups = {}
	self.CurrentlyPlaying = {}
	
	-- Only necessary on the server
	self:InjectObject("Item", item)
	
	self.Character = self.Item.Character
	
	local itemAnimationData = self.Item.Schema.Animations
	if not itemAnimationData then
		return
	end
	
	self:AddSignals("AnimationStarted", "AnimationEventReached")
	
	for animationName, info in itemAnimationData do
		self:CreateAnimation(animationName, info)
	end
	
	self.Item:GetSignal("ActionManagerInitialized"):Once(function()
		self:AddImplicitModifiers()
	end)
	
	self:ListenForAnimations()

	return self
end

function ItemAnimator:GetAnimationFromAssetId(assetId)
	for name, track in self.Animations do
		if track.Track.Animation.AnimationId == assetId then
			return track
		end
	end
	
	for name, group in self.AnimationGroups do
		local track = group:FromAssetId(assetId)
		
		if track then
			return track, group
		end
	end
end

function ItemAnimator:ListenForAnimations()
	if not IsServer then
		return
	end
	
	self:AddConnections({
		AnimationListenerConnection = self.Character:FindFirstChild("Animator", true).AnimationPlayed:Connect(function(animationTrack)
			local animationId = animationTrack.Animation.AnimationId
			local animationObject, animationGroup = self:GetAnimationFromAssetId(animationId)
			
			if not animationObject then
				return
			end
			
			if animationGroup then
				self:FireSignal("AnimationStarted", animationGroup.Prefix, {
					Name = animationGroup:GetAbbreviatedAnimationTrackName(animationObject.Name)
				})
			else
				self:FireSignal("AnimationStarted", animationObject.Name)
			end
			
		end)
	})
end

function ItemAnimator:StopListeningForAnimations()
	self:CleanupConnection("AnimationListenerConnection")
end

function ItemAnimator:SetCharacter()
	if next(self.Animations) then
		
	end
end

function ItemAnimator:GetAnimation(name, individualTrackName)
	local animation = self.Animations[name]
	if animation then
		return animation
	end
	
	local group = self.AnimationGroups[name]
	if group and individualTrackName then
		return group:GetAnimation(individualTrackName)
	end
	
	return group
end

function ItemAnimator:GetEventForAnimation(animationName, eventName)
	local animation = self:GetAnimation(animationName)
	return animation:GetEvent(eventName)
end

function ItemAnimator:CreateAnimation(name, info)
	local animPath = info
	if type(info) == "table" then
		animPath = info.Path
	end

	local object = AnimationUtilities.CreateAnimationTrackFromPath(animPath, self.Character)

	if object:IsClass("AnimationTrack") then
		self.Animations[name] = object
	else
		self.AnimationGroups[name] = object
	end
	object:SetEventSignal(self:GetSignal("AnimationEventReached"))
end

function ItemAnimator:AddImplicitModifiers()
	local itemAnimationData = self.Item.Schema.Animations

	for animationName, info in itemAnimationData do
		local animationObject = self:GetAnimation(animationName)
		
		AddImplicitModifiers(animationName, animationObject, info, self.Item)
	end
end

function ItemAnimator:AddModifiers(dict)
	for animationName, modifiers in dict do
		self:GetAnimation(animationName):AddModifiers(modifiers)
	end
end

--[[
	Don't let the server play animations if the client's already playing them
	Just check if the item's owner is a player
]]
function ItemAnimator:CancelAnimationReplicationIfClient()
	if not IsServer then
		return false
	end
	
	local player = Players:GetPlayerFromCharacter(self.Character)
	if not player then
		return false
	end

	return true
end

-- Use name of animation group to play a randomly chosen animation from that group
function ItemAnimator:Play(animationName, config, callback)
	if self:CancelAnimationReplicationIfClient() then
		return
	end
	
	local animGroup = self.AnimationGroups[animationName]
	
	if animGroup then
		animGroup:Play(config)
		self.Signals.AnimationStarted:Fire(animationName, config) -- Indicates animation group
		
		if callback then
			callback()
		end
		return
	end
	
	local anim = self.Animations[animationName]
	if anim then
		anim:Play(config)
		self.Signals.AnimationStarted:Fire(animationName, config)
	end
	
	if callback then
		callback()
	end
end

function ItemAnimator:PlayAsIdle(animationName, config)
	if self:CancelAnimationReplicationIfClient() then
		return
	end
	
	config.Priority = Enum.AnimationPriority.Idle
	config.Looped = true
	
	local idle = self.AnimationGroups[animationName]
	if not idle then
		idle = self.Animations[animationName]
	end
	
	idle:Play(config)
end

function ItemAnimator:Stop(...)
	if self:CancelAnimationReplicationIfClient() then
		return
	end
	
	local args = {...}
	for i, name in args do
		if self.Animations[name] then
			self.Animations[name]:Stop()
		end

		if self.AnimationGroups[name] then
			self.AnimationGroups[name]:Stop()
		end
	end
end

function ItemAnimator:StopAll()
	if self:CancelAnimationReplicationIfClient() then
		return
	end
	
	for k, v in self.Animations do
		v:Stop()
	end
	
	for k, v in self.AnimationGroups do
		v:Stop()
	end
end

return ItemAnimator

