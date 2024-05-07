local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local ModelUtilities = Framework.GetShared("ModelUtilities")

local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local IsServer = RunService:IsServer()
local IsClient = RunService:IsClient()

local ItemModelsFolder = workspace.ItemModels

local ItemModel = {}
ItemModel.__index = ItemModel
ItemModel.ClassName = "ItemModel"
setmetatable(ItemModel, BaseClass)

-- TODO: Low priority - Make this client-side ONLY

--[[
	Item models must have a part named Handle which connects all other parts with Motor6Ds or Weld Constraints
	The model has the attribute WeldTo, which can be set to a body part (LeftHand, RightHand, UpperTorso) for animating; default is RightHand
	The handle should contain a Motor6D named ItemGrip whose part 0 is the handle and part 1 is the body part as specified by WeldTo
]]
function ItemModel.new(params)
	local self = BaseClass.new()
	setmetatable(self, ItemModel)
	
	self.Model = params.Model:Clone()
	self.Model.Name = self:GetBaseName()
	self.Model.Parent = ItemModelsFolder
	
	self:Hide()
	ModelUtilities.SetInteractive(self.Model, false)
	
	self.Cleaner:Add(self.Model)
	
	self.Handle = self.Model.Handle
	
	self.CharacterModel = params.CharacterModel

	if IsServer then
		local player = Players:GetPlayerFromCharacter(self.CharacterModel)
		if player then
			CollectionService:AddTag(self.Model, `ReplicatedFrom{player.Name}`)
		end
	end
	
	self.WeldTo = self.Model:GetAttribute("WeldTo") or "RightHand"
	
	self.HandleMotor = Instance.new("Motor6D")
	self.HandleMotor.Name = "ItemGrip"
	
	self.Cleaner:Add(self.HandleMotor)
	
	self.IKControls = {}

	return self
end

function ItemModel:GetWorldPosition()
	return self.Model:GetPivot().Position
end

function ItemModel:GetBaseName()
	if IsServer then
		return `S_{self.Model.Name}`
	elseif IsClient then
		return `C_{self.Model.Name}`
	end
end

function ItemModel:ConnectMotor6D()
	local motor = self.HandleMotor
	
	-- Dude...
	if not motor.Part0 then
		local bodyPart = self.CharacterModel:FindFirstChild(self.WeldTo)
		motor.Part0 = bodyPart
		
		if not motor.Parent then
			motor.Parent = bodyPart
		end
	end
	
	motor.Part1 = self.Handle

	motor.C0 = self.Model:GetAttribute("C0")
	motor.C1 = self.Model:GetAttribute("C1")
end

function ItemModel:DisconnectMotor6D()
	self.HandleMotor.Part1 = nil
end

function ItemModel:Equip()
	ModelUtilities.Anchor(self.Model, false)
	ModelUtilities.SetTransparency(self.Model, 0)
	--self.Model.Parent = self.CharacterModel
	
	self:ConnectMotor6D()
end

function ItemModel:Unequip()
	self:DisconnectMotor6D()
	
	self:Hide()
end

function ItemModel:Hide()
	ModelUtilities.Lock(self.Model, true)
	ModelUtilities.SetTransparency(self.Model, 1)
	self.Model.Parent = ItemModelsFolder
end

function ItemModel:Destroy()
	self.HandleMotor = nil
	
	self.Model:Destroy()
	self.Model = nil
	
	self:BaseDestroy()
end

return ItemModel

