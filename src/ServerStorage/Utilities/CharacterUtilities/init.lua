local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local CharacterRegistry = Framework.GetServer("CharacterRegistry")

local DefaultCharacter = script.DefaultCharacter
local CacheCFrame = CFrame.new(0, 1e4, 0)

local BodyColorsParts = {"Head", "LeftArm", "LeftLeg", "RightArm", "RightLeg", "Torso"}

local CharacterUtilities = {}

function CharacterUtilities.GetCharacterFromModel(model)
	return CharacterRegistry.GetCharacterFromModel(model)
end

function CharacterUtilities.CacheCharacter(character)
	character.PrimaryPart.Anchored = true
	character:PivotTo(CacheCFrame)
	character.Parent = workspace.CachedCharacters
end

function CharacterUtilities.GetDefaultCharacter()
	return DefaultCharacter:Clone()
end

function CharacterUtilities.CreateCharacterWithDescription(humanoidDescription)
	local character = CharacterUtilities.GetDefaultCharacter()
	CharacterUtilities.CacheCharacter(character)
	
	if humanoidDescription then
		character.Humanoid:ApplyDescription(humanoidDescription)
	end
	
	return character
end

function CharacterUtilities.GetCharacterSize(character)
	local clone = character:Clone()
	clone.Humanoid:RemoveAccessories()
	
	local size = clone:GetExtentsSize()
	clone:Destroy()
	
	return size
end

function CharacterUtilities.CreateAnimationController(character)
	if character:FindFirstChild("Humanoid") then
		return
	end
	
	local animationController = character:FindFirstChildOfClass("AnimationController")
	if animationController then
		return animationController
	end
	
	animationController = Instance.new("AnimationController")
	animationController.Parent = character

	local animator = Instance.new("Animator")
	animator.Parent = animationController
	
	return animationController
end

function CharacterUtilities.GetCylindricalBoundingBoxSize(character)
	local size = CharacterUtilities.GetCharacterSize(character)
	
	local maxSize = math.max(size.X, size.Z)
	
	return Vector3.new(size.Y + 1, maxSize, maxSize)
end

function CharacterUtilities.GetCenter(character)
	local center, size = character:GetBoundingBox()
	return center
end

function CharacterUtilities.ApplyBodyColorsToHumanoidDescription(character)
	local humanoid = character.Humanoid
	local description = humanoid:GetAppliedDescription()
	local bodyColors = character:FindFirstChildWhichIsA("BodyColors")
	
	for i, bodyPart in pairs(BodyColorsParts) do
		description[`{bodyPart}Color`] = bodyColors[`{bodyPart}Color3`]
	end
end

return CharacterUtilities