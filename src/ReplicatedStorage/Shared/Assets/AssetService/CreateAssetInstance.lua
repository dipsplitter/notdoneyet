--[[
	ContentProvider assumes Content strings are for images, so we have to create a hundred instances on load. Not cool.
]]

local CreateAssetInstance = {}

function CreateAssetInstance.Sounds(id)
	local sound = Instance.new("Sound")
	sound.SoundId = id
	
	return sound
end

function CreateAssetInstance.Animations(id)
	local animation = Instance.new("Animation")
	animation.AnimationId = id
	
	return animation
end

function CreateAssetInstance.Images(id)
	local decal = Instance.new("Decal")
	decal.Texture = id
	
	return decal
end

return CreateAssetInstance
