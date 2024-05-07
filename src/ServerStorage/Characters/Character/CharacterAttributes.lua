local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local ClampedValue = Framework.GetShared("ClampedValue")
local Value = Framework.GetShared("Value")
local ValueModifiers = Framework.GetShared("ValueModifiers")
local DefaultCharacterAttributes = Framework.GetShared("DefaultCharacterAttributes")
local TableUtilities = Framework.GetShared("TableUtilities")
local CharacterAttributesUtilities = Framework.GetShared("CharacterAttributesUtilities")
local InstanceCreator = Framework.GetShared("InstanceCreator")

local CharacterAttributes = {}
CharacterAttributes.__index = CharacterAttributes
CharacterAttributes.ClassName = "CharacterAttributes"
setmetatable(CharacterAttributes, BaseClass)

function CharacterAttributes.new(character, attributes)
	local self = BaseClass.new()
	setmetatable(self, CharacterAttributes)
	
	self:InjectObject("Character", character)
	
	self.AutoCleanup = true
	self.Base = {}
	self.ValuesList = {}
	self.ModifiersList = {}
	
	self.BaseAttributesFolder = InstanceCreator.Create("Folder", {
		Name = "Attributes",
		Parent = self.Character.CachedModel:GetModel(),
	})
	self.CurrentAttributesFolder = nil
	
	self:SetNewBaseAttributes(attributes)
	
	self:AddConnections({
		CharacterDestroying = self.Character:ConnectTo("Destroying", function()
			self:Destroy()
		end),
		
		CurrentModelDestroying = self.Character:ConnectTo("Respawning", function()
			if self.CurrentAttributesFolder then
				self.CurrentAttributesFolder:Destroy()
			end
			
			self.CurrentAttributesFolder = nil
			
			self:ResetToBase()
		end),
	})
	
	return self
end

function CharacterAttributes:CreateAttributesFolder()
	local currentModel = self.Character:GetModel()
	if not currentModel then
		return
	end
	
	local existingAttributes = currentModel:FindFirstChild("Attributes")
	if existingAttributes then
		self.CurrentAttributesFolder = existingAttributes
		self:LinkAllValueObjects()
		return existingAttributes
	end
	
	self.CurrentAttributesFolder = self.BaseAttributesFolder:Clone()
	self:LinkAllValueObjects()
	self.CurrentAttributesFolder.Parent = currentModel
	
	return self.CurrentAttributesFolder
end

function CharacterAttributes:ClearValueList()
	for name, object in pairs(self.ValuesList) do
		if object.Destroy then
			object:Destroy()
		end
		
		self.ValuesList[name] = nil
		
		self.ModifiersList[name]:Destroy()
		self.ModifiersList[name] = nil
	end
end

function CharacterAttributes:RemoveAttribute(...)
	local args = {...}
	
	for i, name in ipairs(args) do
		self.Base[name] = nil
		self.BaseAttributesFolder:SetAttribute(name, nil)
		
		if self.ValuesList[name] then
			self.ValuesList[name]:Destroy()
			self.ValuesList[name] = nil
			
			self.ModifiersList[name]:Destroy()
			self.ModifiersList[name] = nil
		end
	end
end

function CharacterAttributes:RemoveUnusedAttributes(newAttributes)
	for attributeName in pairs(self.Base) do
		if not newAttributes[attributeName] or (newAttributes[attributeName].Value == false) then
			self:RemoveAttribute(attributeName)
		end
	end
end

function CharacterAttributes:LinkAllValueObjects()
	if not self.CurrentAttributesFolder then
		return
	end
	
	for name, object in pairs(self.ValuesList) do
		object:LinkAttribute(self.CurrentAttributesFolder, name)
	end
end

function CharacterAttributes:SetNewBaseAttributes(attributes)
	local defaultCopy = TableUtilities.DeepCopy(DefaultCharacterAttributes)
	attributes = attributes or defaultCopy
	
	-- Fill in missing entries with default attributes, but don't override existing key-value pairs
	if attributes ~= defaultCopy then
		-- Use Merge because we don't want to deep reconcile
		attributes = TableUtilities.Merge(attributes, defaultCopy, false)
	end
	
	local createdValues = CharacterAttributesUtilities.CreateCharacterAttributeValues(attributes)
	
	local oldBase = TableUtilities.DeepCopy(self.Base)
	self.Base = TableUtilities.Reconcile(self.Base, attributes)
	
	for name, object in pairs(createdValues) do
		-- Delete existing values
		if self.ValuesList[name] then
			self.ValuesList[name]:Destroy()
			self.ValuesList[name] = nil
		end
		
		self.ValuesList[name] = object
		self:SetupNewValue(name, object)
	end
end

function CharacterAttributes:SetupNewValue(name, object)
	if object:IsClass("ClampedValue") then
		self.BaseAttributesFolder:SetAttribute(name, Vector3.new(object.Min, object.Value, object.Max))
	else
		self.BaseAttributesFolder:SetAttribute(name, object.Value)
	end
	
	object:AddExternalReference(self.ValuesList)
	
	-- Update the modifier's base value
	local modifierObject = self.ModifiersList[name]
	if not modifierObject then
		modifierObject = ValueModifiers.new(object.Value)
		self.ModifiersList[name] = modifierObject
	else
		modifierObject.Base = object.Value
	end

	-- The value object updates accordingly when any of its modifiers changes
	object:AddConnections({
		ModifierChanged = modifierObject.Changed:Connect(function()
			object.Value = modifierObject:Calculate()
		end)
	})
	
	if self.CurrentAttributesFolder then
		object:LinkAttribute(self.CurrentAttributesFolder, name)
	end
end

function CharacterAttributes:ResetToBase()
	for statName, valueObject in self.ValuesList do
		local base = self:GetBase(statName)
		valueObject.Value = base
	end
end

function CharacterAttributes:Get(statName)
	if self.ValuesList[statName] then
		return self.ValuesList[statName].Value
	end
	
	return CharacterAttributesUtilities.GetAttributeDefaultValue(statName)
end

function CharacterAttributes:VerifyValueObject(statName)
	if self.ValuesList[statName] then
		return true
	end
	
	self.ValuesList[statName] = CharacterAttributesUtilities.CreateAttributeValue(statName)
	self:SetupNewValue(statName, self.ValuesList[statName])
end

function CharacterAttributes:GetValueObject(statName)
	self:VerifyValueObject(statName)
	return self.ValuesList[statName]
end

function CharacterAttributes:GetModifierObject(statName)
	self:VerifyValueObject(statName)
	return self.ModifiersList[statName]
end

function CharacterAttributes:GetBase(statName)
	if self.Base[statName] then
		return self.Base[statName].Value
	end

	return CharacterAttributesUtilities.GetAttributeDefaultValue(statName)
end

function CharacterAttributes:Set(statName, value)
	if self.ValuesList[statName] then
		self.ValuesList[statName].Value = value
		
		-- Also update the modifier base value
		if self.ModifiersList then
			self.ModifiersList[statName].Base = value
		end
	else
		local attributeType = CharacterAttributesUtilities.GetAttributeType(statName)
		
		self.ValuesList[statName] = CharacterAttributesUtilities.CreateAttributeValue(statName, value)
		self.ModifiersList[statName] = ValueModifiers.new(self.ValuesList[statName].Value)
	end
end

function CharacterAttributes:Destroy()
	self.BaseAttributesFolder = nil
	self.CurrentAttributesFolder = nil
	self:ClearValueList()
	
	self:BaseDestroy()
end

return CharacterAttributes