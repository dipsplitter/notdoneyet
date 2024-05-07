local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local CharacterUtilities = Framework.GetShared("CharacterUtilities")

local RaycastUtilities = {}

function RaycastUtilities.ToRaycastParams(overlapParams)
	if not overlapParams then
		return
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = overlapParams.FilterType
	raycastParams.CollisionGroup = overlapParams.CollisionGroup
	raycastParams.FilterDescendantsInstances = overlapParams.FilterDescendantsInstances
	raycastParams.RespectCanCollide = overlapParams.RespectCanCollide

	return raycastParams
end

function RaycastUtilities.ToOverlapParams(raycastParams)
	if not raycastParams then
		return
	end

	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = raycastParams.FilterType
	overlapParams.CollisionGroup = raycastParams.CollisionGroup
	overlapParams.FilterDescendantsInstances = raycastParams.FilterDescendantsInstances
	overlapParams.RespectCanCollide = raycastParams.RespectCanCollide

	return overlapParams
end

function RaycastUtilities.ConvertRaycastResultToTable(raycastResult)
	return {
		["Instance"] = raycastResult.Instance,
		Normal = raycastResult.Normal,
		Material = raycastResult.Material,
		Position = raycastResult.Position,
		Distance = raycastResult.Distance
	}
end

-- Assumes the raycast result instance exists
function RaycastUtilities.InstanceIsDescendant(raycastResult, compareTo)
	local instance = raycastResult.Instance
	
	if typeof(compareTo) ~= "Instance" then
		return false
	end
	
	if compareTo:IsA("Model") then
		return instance:FindFirstAncestorWhichIsA("Model") == compareTo 
			or instance:IsDescendantOf(compareTo) 
			or instance == compareTo
	end
	
	return true
end

return RaycastUtilities
