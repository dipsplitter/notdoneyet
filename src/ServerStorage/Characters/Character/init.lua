local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local InstanceCreator = Framework.GetShared("InstanceCreator")
local ModelUtilities = Framework.GetShared("ModelUtilities")
local RandomUtilities = Framework.GetShared("RandomUtilities")
local ItemInventory = Framework.GetShared("ItemInventory")
local CharacterModelStorage = Framework.GetShared("CharacterModelStorage")

local ClassModels = Framework.GetShared("ClassModels")
local ClassCharacterAttributes = Framework.GetShared("ClassCharacterAttributes")

local CharacterUtilities = Framework.GetServer("CharacterUtilities")
local CharacterRegistry = Framework.GetServer("CharacterRegistry")
local CharacterDescription = Framework.GetServer("CharacterDescription")
local CharacterAttributes = Framework.GetServer("CharacterAttributes")
local CharacterCachedModel = Framework.GetServer("CharacterCachedModel")
local CharacterActiveModel = Framework.GetServer("CharacterActiveModel")

local CharacterSpawner = Framework.GetServer("CharacterSpawner")

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local DeathCFrame = CFrame.new(0, 1e4, 0)

local Character = {}
Character.__index = Character 
Character.ClassName = "Character"
setmetatable(Character, BaseClass)

function Character.new(params)
	local self = BaseClass.new()
	setmetatable(self, Character)
	
	self.Id = CharacterRegistry.CurrentId
	CharacterRegistry.CurrentId += 1
	CharacterRegistry.Insert(self)
	
	self.Tags = params.Tags or {}
	self.Class = "None"
	self.Team = "Neutral"

	self.IKControls = {}
	
	self.Description = CharacterDescription.new(params.HumanoidDescription)
	self.Cleaner:Add(self.Description)
	
	self.CachedModel = CharacterCachedModel.new(self.Id)
	self.CachedModel:Cache(params.Model or CharacterUtilities.GetDefaultCharacter())
	
	self.ActiveModel = CharacterActiveModel.new(self)
	
	if self.Description.IsEmpty then
		self.Description:SetDescriptionFromCharacter(self.CachedModel:GetModel())
	end
	
	self.Player = params.Player or Players:GetPlayerFromCharacter(self.CachedModel:GetModel())
	self.Respawning = Framework.DefaultFalse(params.Respawning)
	if self.Player then
		self.Respawning = true
	end
	
	self.DeletionDelay = params.DeletionDelay or 10
	self:AddSignals("Died", "Spawned", "Loaded", "Respawning")
	
	self.Attributes = CharacterAttributes.new(self)
	
	self.ItemInventory = ItemInventory.new()
	
	self:FireSignal("Loaded")
	
	return self
end

function Character:SetupConnectionsForNewModel()
	local model = self.ActiveModel:GetModel()
	self:AddConnections({
		-- TODO: Don't involve the humanoid
		HumanoidDeath = model.Humanoid.HealthChanged:Connect(function(health)
			if health > 0 then
				return
			end
			
			self:CleanupConnection("HumanoidDeath")
			self:FireSignal("Died")
		end),
		
		HealthAttribute = self.Attributes.ValuesList.Health:ConnectTo("Changed", function(index, prev, current)
			if not model then
				return
			end
			
			if current <= 0 then
				model.Humanoid.Health = 0
			end
		end),
		
		
		ClearItemInventory = self:ConnectTo("Died", function()
			local inventory = self:GetInventory()
			
			for item in inventory.ItemsList do
				item:OnCharacterDeath()
			end
			
			inventory:ForgetAllItems()
		end)
	})
	
	if not self.Respawning then
		self:AddConnections({
			RemoveOnDeath = self.Signals.Died:Connect(function()
				task.delay(self.DeletionDelay, function()
					if self.Destroy then
						self:Destroy()
					end
				end)
			end),
		})
	end
end

function Character:GetAttributes()
	return self.Attributes
end

function Character:GetInventory()
	return self.ItemInventory
end

function Character:GetModel()
	return self.ActiveModel:GetModel()
end

function Character:GetModelPart(name)
	return self.ActiveModel:GetModelPart(name)
end

-- TODO
function Character:SetClass(className)
	self.Class = className
	
	local classModel = CharacterModelStorage.GetModel(ClassModels[self.Class][self.Team])
	if not self:GetModel() then
		self.CachedModel:Override(classModel)
	else
		self.CachedModel:Cache(classModel)
	end
	
	self.CachedModel:UpdateOnRespawn()
	self.Description:SetDescriptionFromCharacter(self.CachedModel:GetModel())
	
	self.Attributes:SetNewBaseAttributes(ClassCharacterAttributes[self.Class])
end

function Character:GetBoundingBoxSize()
	-- Bounding box is rotated 90 degrees along Z, so X and Y are swapped
	local size = self.ActiveModel:GetBoundingBox().Size
	return Vector3.new(size.Y, size.X, size.Z)
end

function Character:GetEyesLookVector()
	return self.ActiveModel:GetModelPart("Head").CFrame.LookVector
end

function Character:GetHeadToLookRay()
	local origin = self.ActiveModel:GetModelPart("Head").Position
	return {
		Origin = origin,
		Direction = (self:GetEyesLookVector() * 500 - origin).Unit
	}
end

function Character:ApplyDescription(applyToActiveModel)
	self.Description:Apply(self.CachedModel:GetModel())
	
	if self.ActiveModel and applyToActiveModel then
		self.Description:Apply(self:GetModel())
	end
end

function Character:GetCharacterAttribute(attributeName)
	return self.Attributes:Get(attributeName)
end

function Character:SetCharacterAttribute(attributeName, value)
	self.Attributes:Set(attributeName, value)
end

function Character:IsAlive()
	local model = self:GetModel()
	if not model then
		return false
	end
	return model.Humanoid.Health > 0
end

function Character:GetPosition()
	local model = self:GetModel()
	if not model then
		return
	end
	return model.PrimaryPart.Position
end

function Character:IsDead()
	local model = self:GetModel()
	if not model then
		return true
	end
	
	local humanoid = model:FindFirstChild("Humanoid") 
	if not humanoid then
		return true
	end
	
	return humanoid.Health == 0
end

-- Note: this does not actually do damage
function Character:Kill()
	local model = self:GetModel()
	if not model then
		return
	end
	
	model.Humanoid.Health = 0
end

--[[
	FIXME: Potential memory leak
	When the character dies and is "destroyed" there's still a reference to it
]]

function Character:BaseSpawn(currentModel, spawnParams)
	self.CachedModel:UpdateOnRespawn()
	self.ActiveModel:Spawn(currentModel)
	self:SetupConnectionsForNewModel()
	
	CharacterSpawner.Spawn(self, spawnParams)
	
	self.Signals.Spawned:Fire(self.ActiveModel.Model)
end
Character.Spawn = Character.BaseSpawn

function Character:Destroy()
	self.Description:Destroy()
	self.Attributes:Destroy()
	self.ActiveModel:Destroy()
	self.CachedModel:Destroy()

	self:BaseDestroy()
end

return Character