local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local RbxAssets = Framework.GetShared("RbxAssets")

--[[

]]
local HumanoidDescriptionPropertyMap = {
	["BodyProportionScale"] = "ProportionScale",
	["BodyDepthScale"] = "DepthScale",
	["BodyWidthScale"] = "WidthScale",
	["BodyHeightScale"] = "HeightScale",
}
local ColoredBodyParts = {
	Head = 0,
	LeftArm = 0,
	LeftLeg = 0,
	RightArm = 0,
	RightLeg = 0,
	Torso = 0,
}

--[[
	Wrapper for HumanoidDescription that allows for custom accessory assets
]]

local CharacterDescription = {}
CharacterDescription.__index = CharacterDescription
CharacterDescription.ClassName = "CharacterDescription"
setmetatable(CharacterDescription, BaseClass)

function CharacterDescription.new(characterDescriptionTemplate, customDescription)
	local self = BaseClass.new()
	setmetatable(self, CharacterDescription)
	
	self.HumanoidDescription = customDescription or Instance.new("HumanoidDescription")
	if customDescription then
		self.IsEmpty = false
	else
		self.IsEmpty = true
	end
	
	self.Cleaner:Add(self.HumanoidDescription)
	
	self.BodyParts = {
		Face = 0,
		Head = 0,
		LeftArm = 0,
		LeftLeg = 0,
		RightArm = 0,
		RightLeg = 0,
		Torso = 0,
	}
	
	self.Face = {
		Decal = 0,
	}
	self.Accessories = {}
	self.Clothing = {}
	
	return self
end

function CharacterDescription:SetDescriptionFromCharacter(character)
	local humanoidDescription = self.HumanoidDescription
	local humanoid = character.Humanoid
	
	-- BODY COLORS
	local bodyColors = character:FindFirstChildWhichIsA("BodyColors")
	for bodyPart in pairs(ColoredBodyParts) do
		humanoidDescription[`{bodyPart}Color`] = bodyColors[`{bodyPart}Color3`]
	end
	
	-- HUMANOID RIG PROPORTIONS
	for i, object in pairs(humanoid:GetChildren()) do
		if not object:IsA("NumberValue") then
			continue
		end
		
		local property = HumanoidDescriptionPropertyMap[object.Name]
		if not property then
			property = object.Name
		end
		
		humanoidDescription[property] = object.Value
	end
	
	--[[ BODY PART MESHES
	
	ALL BODY PART MESHES FOR R15 RIGS ARE GOING TO BE 0 I HOPE
	
		for i, bodyPart in pairs(character:GetChildren()) do
			
		end
	]]
	
	table.clear(self.Accessories)
	table.clear(self.Clothing)
	self.Face.Decal = nil
	
	-- ACCESSORIES
	for i, accessory in pairs(humanoid:GetAccessories()) do
		
		local clone = accessory:Clone()
		self.Accessories[clone] = 1
		
	end
	
	-- SHIRTS, PANTS, ETC.
	for i, clothing in pairs(character:GetChildren()) do
		if not clothing:IsA("Clothing") then
			continue
		end
		
		local clone = clothing:Clone()
		self.Clothing[clone] = 1
	end
	
	-- FACES
	local head = character:FindFirstChild("Head")
	local faceDecal = head:FindFirstChild("face")
		
	if faceDecal then
		self.Face.Decal = faceDecal.Texture
	end
	
	self.IsEmpty = false
end

function CharacterDescription:Apply(target)
	local humanoid = target.Humanoid
	
	for accessory in pairs(self.Accessories) do
		local clone = accessory:Clone()
		humanoid:AddAccessory(clone)
	end
	
	for clothing in pairs(self.Clothing) do
		local clone = clothing:Clone()
		clone.Parent = target
	end
	
	local faceDecal = self.Face.Decal
	if faceDecal ~= 0 then
		target.Head.face.Texture = faceDecal
	end
	
	humanoid:ApplyDescription(self.HumanoidDescription)
end

function CharacterDescription:AddAnimations(animationDict)
	for animationName, id in pairs(animationDict) do
		self.HumanoidDescription[`{animationName}Animation`] = id
	end
end

function CharacterDescription:Destroy()
	for clone in pairs(self.Accessories) do
		self.Accessories[clone] = nil
		clone:Destroy()
	end
	
	self:BaseDestroy()
end

return CharacterDescription
