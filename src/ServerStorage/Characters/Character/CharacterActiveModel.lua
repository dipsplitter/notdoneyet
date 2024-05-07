local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local ModelUtilities = Framework.GetShared("ModelUtilities")
local InstanceCreator = Framework.GetShared("InstanceCreator")

local CharacterUtilities = Framework.GetServer("CharacterUtilities")

local CollectionService = game:GetService("CollectionService")

local HitboxIgnoreList = {
	HumanoidRootPart = true, 
	BoundingBox = true,
}

local function CreateHitbox(basePart)
	local hitbox = basePart:Clone() 
	hitbox:ClearAllChildren() 
	hitbox.Transparency = 1
	hitbox.Name = `{basePart.Name}Hitbox`

	hitbox.CanTouch = true 
	hitbox.BrickColor = BrickColor.new("Bright blue") 
	hitbox.Massless = true 
	hitbox.CollisionGroup = "Hitbox"
	hitbox.Parent = basePart

	local motor6D = Instance.new("Motor6D") 
	motor6D.Name = "HitboxConnector" 
	motor6D.MaxVelocity = 1 
	motor6D.Parent = basePart 
	motor6D.Part0 = basePart 
	motor6D.Part1 = hitbox
end

local function CreateEyesAttachment(model)
	local head = model:FindFirstChild("Head")
	local primaryPart = model.PrimaryPart
	
	local attachment = Instance.new("Attachment")
	attachment.Name = "EyesAttachment"
	attachment.Position = Vector3.new(0, primaryPart.Size.Y / 2 + head.Size.Y / 2, 0)
	attachment.Parent = primaryPart
end

local CharacterActiveModel = {}
CharacterActiveModel.__index = CharacterActiveModel
CharacterActiveModel.ClassName = "CharacterActiveModel"
setmetatable(CharacterActiveModel, BaseClass)

function CharacterActiveModel.new(character)
	local self = BaseClass.new()
	setmetatable(self, CharacterActiveModel)
	
	self:InjectObject("Character", character)
	self.Model = nil
	self.BoundingBox = nil
	
	self.AutoCleanup = true
	
	return self
end

function CharacterActiveModel:IsCharacterValid()
	return (self.Model ~= nil) and (self.Model.Humanoid.Health ~= 0)
end

function CharacterActiveModel:ApplyTags(tags)
	tags = tags or self.Character.Tags
	for i, tag in pairs(tags) do
		CollectionService:AddTag(self.Model, tag)
	end
end

function CharacterActiveModel:GetModel()
	return self.Model
end

function CharacterActiveModel:GetModelPart(name)
	return self.Model:FindFirstChild(name)
end

function CharacterActiveModel:Set(currentModel)
	local character = self.Character
	
	if currentModel then
		self.Model = currentModel
	else
		self.Model = character.CachedModel:GetModel():Clone()
	end
	
	self.Model:SetAttribute("CharacterID", character.Id)
	character.Attributes:CreateAttributesFolder()
	CreateEyesAttachment(self.Model)

	self:ApplyTags()

	-- Need to be able to clone its parts
	self.Model.Archivable = true
	
	self.Model.PrimaryPart.Anchored = false
	
	-- We must parent before creating the animator and humanoid description to silence Roblox errors
	self.Model.Parent = workspace.Characters
	
	-- Setup animations
	CharacterUtilities.CreateAnimationController(self.Model)
	character.Description:Apply(self.Model)
end

function CharacterActiveModel:Spawn(model)
	self.Character:FireSignal("Respawning")
	
	-- Get rid of previous model
	if self.Model then
		self.Model:Destroy()
	end
	
	self:Set(model)
	
	ModelUtilities.LockCharacter(self.Model, false)
	self:CreateBoundingBox()
	self:CreateHitboxes()
	
end

function CharacterActiveModel:CreateBoundingBox()
	if self.BoundingBox then
		self.BoundingBox:Destroy()
		self.BoundingBox = nil
	end

	local boxSize = CharacterUtilities.GetCylindricalBoundingBoxSize(self.Model)

	self.BoundingBox = InstanceCreator.Create("Part", {
		Shape = Enum.PartType.Cylinder,
		Name = `BoundingBox`,
		CollisionGroup = "BoundingBox",
		Orientation = Vector3.new(0, 0, -90),
		Size = boxSize,
		Position = self.Model.PrimaryPart.Position,
		Transparency = 1,
		Parent = self.Model.PrimaryPart,
	})

	local boundingBoxWeld = InstanceCreator.Create("WeldConstraint", {
		Name = "BoundingBoxWeld",
		Part0 = self.Model.PrimaryPart,
		Part1 = self.BoundingBox,
		Parent = self.Model.PrimaryPart
	})
end

function CharacterActiveModel:GetBoundingBox()
	return self.BoundingBox
end

function CharacterActiveModel:CreateHitboxes()
	for i, basePart in self.Model:GetChildren() do
		
		if not basePart:IsA("BasePart") or HitboxIgnoreList[basePart.Name] then
			continue
		end
		
		basePart.CollisionGroup = "Nonsolid" 
		basePart.CanTouch = false 

		if basePart:FindFirstChild(`{basePart.Name}Hitbox`) then
			continue
		end

		CreateHitbox(basePart)
			
	end
end

function CharacterActiveModel:Destroy()
	if self.Model then
		self.Model:Destroy()
	end
	
	self:BaseDestroy()
end

return CharacterActiveModel