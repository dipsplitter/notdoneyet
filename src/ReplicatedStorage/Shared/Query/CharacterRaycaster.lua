local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Raycaster = Framework.GetShared("Raycaster")

local CharacterRaycaster = {}
CharacterRaycaster.__index = CharacterRaycaster
CharacterRaycaster.ClassName = "CharacterRaycaster"
setmetatable(CharacterRaycaster, Raycaster)

function CharacterRaycaster.new(params)
	local self = Raycaster.new(params)
	setmetatable(self, CharacterRaycaster)
	
	self.Character = params.Character
	self:AddToIgnoreList(self.Character)
	
	return self
end

function CharacterRaycaster:CastFromHead(length, dir)
	local head = self.Character:FindFirstChild("Head")
	local eyesAttachment = self.Character.PrimaryPart.EyesAttachment
	
	dir = dir or head.CFrame.LookVector
	
	return self:Cast(eyesAttachment.WorldPosition, dir, length)
end

function CharacterRaycaster:BlockcastFromCenter(length, size, dir)
	if not size then
		local characterSize = self.Character.PrimaryPart.BoundingBox.Size
		size = Vector3.new(characterSize.X, characterSize.Y, 0)
	else
		size.Z = 0
	end

	dir = dir or self.Character.PrimaryPart.EyesAttachment.WorldCFrame.LookVector

	return self:Blockcast(self.Character:GetPivot(), size, dir * length)
end

return CharacterRaycaster
