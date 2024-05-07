local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local RbxAssets = Framework.GetShared("RbxAssets")

local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

-- TODO: This is in AnimationUtil
local function GetAnimationId(object)
	if typeof(object) == "Instance" then
		if object:IsA("AnimationTrack") then
			return object.Animation.AnimationId
		elseif object:IsA("Animation") then
			return object.AnimationId
		end
	elseif typeof(object) == "table" then
		return object.Track.Animation.AnimationId
	else
		return RbxAssets.ToRbxAssetId(object)
	end
end

local AnimationEventsUtilities = {}

function AnimationEventsUtilities.GetEventArray(animationTrack)
	local animationId = GetAnimationId(animationTrack)

	local events = {}
	local keyframeSequence = KeyframeSequenceProvider:GetKeyframeSequenceAsync(animationId)

	local function Recurse(parent)
		for i, child in parent:GetChildren() do

			if child:IsA("KeyframeMarker") then
				table.insert(events, child)
			end

			if #child:GetChildren() > 0 then
				Recurse(child)
			end

		end
	end

	Recurse(keyframeSequence)

	return events
end

return AnimationEventsUtilities
