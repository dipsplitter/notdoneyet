local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local ModelUtilities = Framework.GetShared("ModelUtilities")

local CharacterUtilities = Framework.GetServer("CharacterUtilities")

local function HandleModel(model, id)
	model:SetAttribute("CharacterID", id)
	model.PrimaryPart.Anchored = true
	ModelUtilities.LockCharacter(model, true)

	-- This cached model should only exist on the server. We do not want it to replicate to clients
	if not model.Parent then
		model.Parent = workspace.Camera.CachedCharacters
	end

	CharacterUtilities.CreateAnimationController(model)
end

local CharacterCachedModel = {}
CharacterCachedModel.__index = CharacterCachedModel
CharacterCachedModel.ClassName = "CharacterCachedModel"
setmetatable(CharacterCachedModel, BaseClass)

function CharacterCachedModel.new(id)
	local self = BaseClass.new()
	setmetatable(self, CharacterCachedModel)
	
	self.Id = id
	self.CachedModel = nil
	self.NextModel = nil
	
	self.AutoCleanup = true
	
	return self
end

function CharacterCachedModel:GetModel()
	return self.CachedModel
end

--[[
	Model must be cloned if it's coming from replicated or server storage
]]
function CharacterCachedModel:Cache(model)
	model = model:Clone()
	
	if self.CachedModel then
		self.NextModel = model
	else
		self.CachedModel = model
	end

	HandleModel(model, self.Id)
end

-- Potentially very buggy
function CharacterCachedModel:Override(model)
	local oldModel = self.CachedModel
	oldModel:Destroy()
	
	self.CachedModel = model:Clone()
	
	HandleModel(self.CachedModel, self.Id)
end

function CharacterCachedModel:UpdateOnRespawn()
	if not self.NextModel then
		return
	end
	
	self.CachedModel:Destroy()
	self.CachedModel = self.NextModel
end

return CharacterCachedModel