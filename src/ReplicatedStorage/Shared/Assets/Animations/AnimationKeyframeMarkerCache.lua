local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local AssetService = Framework.GetShared("AssetService")
local RbxAssets = Framework.GetShared("RbxAssets")
local RecycledSpawn = Framework.GetShared("RecycledSpawn")

local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local function GetAllKeyframeMarkerNames(animationId)
	local markers = {}

	local keyframeSequence = KeyframeSequenceProvider:GetKeyframeSequenceAsync(animationId)

	local function Recurse(parent)
		for i, child in parent:GetChildren() do

			if child:IsA("KeyframeMarker") then
				table.insert(markers, child.Name)
			end

			if #child:GetChildren() > 0 then
				Recurse(child)
			end

		end
	end
	Recurse(keyframeSequence)
	
	return markers
end

local AnimationKeyframeMarkerCache = {}

local function Cache()
	for path, data in AssetService.GetAllAnimations() do
		if not data.Id then
			continue
		end

		RecycledSpawn(function()
			local markers = GetAllKeyframeMarkerNames(RbxAssets.ToRbxAssetId(data.Id))
			
			if #markers > 0 then
				AnimationKeyframeMarkerCache[path] = markers
			end
		end)
	end
end
Cache()

-- TODO: Likely unnecessary
-- Just in case; we can't guarantee that all animations have been cached when this runs
AssetService.AssetsCached:Once(function(category)
	if category ~= "Animations" then
		return
	end
	
	Cache()
end)

return AnimationKeyframeMarkerCache
