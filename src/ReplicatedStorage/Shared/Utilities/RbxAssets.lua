local RbxAssetIdPrefix = "rbxassetid://"
local AssetDeliveryPrefix = "https://assetdelivery.roblox.com/v1/asset/?id="

local RbxAssets = {}

function RbxAssets.ToRbxAssetId(id)
	if string.find(id, RbxAssetIdPrefix) then
		return id
	end
	
	if type(id) == "number" then
		id = tostring(id)
	else
		assert(tonumber(id) ~= nil)
	end
	
	return RbxAssetIdPrefix .. id
end

function RbxAssets.HasPrefix(assetId)
	if type(assetId) ~= "string" then
		return false
	end
	
	if string.find(assetId, "^rbxassetid://") then
		return true
	end
	return false
end

function RbxAssets.GetAssetId(assetId)
	local stringToReplace = ""
	if string.find(assetId, RbxAssetIdPrefix) then
		stringToReplace = RbxAssetIdPrefix
	end
	
	if string.find(assetId, AssetDeliveryPrefix) then
		stringToReplace = AssetDeliveryPrefix
	end
	
	local result = string.gsub(assetId, stringToReplace, "")
	return tonumber(result)
end

return RbxAssets
