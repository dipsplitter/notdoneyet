local ReplicatedStorage = game:GetService("ReplicatedStorage") 
local Framework = require(ReplicatedStorage.Framework)
local RbxAssets = Framework.GetShared("RbxAssets")
local AssetService = Framework.GetShared("AssetService")
local AnimationTrack = Framework.GetShared("AnimationTrack")
local AnimationGroup = Framework.GetShared("AnimationGroup")

local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local AnimationUtilities = {}

function AnimationUtilities.GetAnimationId(object)
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

function AnimationUtilities.GetAnimator(character)
	local animationController = character:FindFirstChildOfClass("Humanoid") or character:FindFirstChildOfClass("AnimationController")
	local animator = animationController:FindFirstChildOfClass("Animator")
	
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = animationController
	end
	
	return animator
end

function AnimationUtilities.CreateAnimation(id, name)
	local animation = Instance.new("Animation")
	animation.AnimationId = id
	animation.Name = name

	return animation
end

function AnimationUtilities.CreateAnimationTrackFromPath(pathToAnim, character)
	local animationProperties = AssetService.Animations(pathToAnim)
	local animator = AnimationUtilities.GetAnimator(character)

	-- Single track
	if animationProperties.Id then
		local animationObject = AnimationUtilities.CreateAnimation(RbxAssets.ToRbxAssetId(animationProperties.Id), pathToAnim)

		return AnimationTrack.new({
			AnimationTrack = animator:LoadAnimation(animationObject),
			Properties = animationProperties
		})
	end
	
	local group = AnimationGroup.new({
		Prefix = pathToAnim
	})

	for animName, animProperties in animationProperties do
		local animationObject = AnimationUtilities.CreateAnimation(RbxAssets.ToRbxAssetId(animProperties.Id), `{pathToAnim}.{animName}`)
		animationObject:SetAttribute("GroupPrefix", pathToAnim)
		
		local animationTrack = animator:LoadAnimation(animationObject)
		
		local track = AnimationTrack.new({
			AnimationTrack = animationTrack,
			Properties = animProperties
		})
		
		group:AddAnimation(track)
	end
	
	return group
end

function AnimationUtilities.GetTrackFromAnimator(animator, id, checkInstanceName)
	if not checkInstanceName then
		local assetId = RbxAssets.ToRbxAssetId(id)
	end
	
	for i, track in pairs(animator:GetPlayingAnimationTracks()) do
		local animationObject = track.Animation
		
		if (checkInstanceName and animationObject.Name == id) or animationObject.AnimationId == id then
			return track
		end
	end
end

return AnimationUtilities
