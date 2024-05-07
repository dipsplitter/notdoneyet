local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local UiFramework = Framework.GetShared("UiFramework")
local TableUtilities = Framework.GetShared("TableUtilities")

local ResourceUtilities = {}

function ResourceUtilities.FindParentResource(resource)
	local parentResource = resource.Override
	
	if not parentResource then
		return
	end
	
	return UiFramework.GetResource(parentResource)
end

function ResourceUtilities.MergeWithParentResource(resource)
	local parent = ResourceUtilities.FindParentResource(resource)
	if not parent then
		return resource
	end
	
	return TableUtilities.DeepMerge(parent, resource)
end
	
return ResourceUtilities