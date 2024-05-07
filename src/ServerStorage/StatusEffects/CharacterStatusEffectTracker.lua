local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local TableUtilities = Framework.GetShared("TableUtilities")

local CharacterStatusEffectTracker = {}
CharacterStatusEffectTracker.__index = CharacterStatusEffectTracker
CharacterStatusEffectTracker.ClassName = "CharacterStatusEffectTracker"
setmetatable(CharacterStatusEffectTracker, BaseClass)

function CharacterStatusEffectTracker.new(character)
	local self = BaseClass.new()
	setmetatable(self, CharacterStatusEffectTracker)
	
	self.AutoCleanup = true
	
	self:AddSignals("EffectAdded", "EffectRemoved")
	
	self:InjectObject("Character", character)
	self.Current = {}
	
	return self
end

function CharacterStatusEffectTracker:GetEffect(name)
	for effect in self.Current do
		if effect.Name == name then
			return effect
		end
	end
end

function CharacterStatusEffectTracker:ShouldAdd(creationParams)
	return TableUtilities.Every(self.Current, function(effect)
		return effect:ShouldAddOtherEffect(creationParams)
	end)
end

function CharacterStatusEffectTracker:Add(statusEffect)
	statusEffect.Cleaner:Add(function()
		self:Remove(statusEffect)
	end)
	
	self.Current[statusEffect] = {
		Time = workspace:GetServerTimeNow(),
	}
	
	self:FireSignal("EffectAdded", statusEffect)
end

function CharacterStatusEffectTracker:Remove(statusEffect, ...)
	if type(statusEffect) == "string" then
		statusEffect = self:GetEffect(statusEffect)
	end
	
	self.Current[statusEffect] = nil
	
	self:FireSignal("EffectRemoved", statusEffect, ...)
end

function CharacterStatusEffectTracker:EndAll()
	for statusEffect in self.Current do
		statusEffect:End()
	end
end

function CharacterStatusEffectTracker:GetSortedByTime(ascending)
	local results = {}
	
	for effect in self.Current do
		table.insert(results, effect)
	end
	
	table.sort(results, function(a, b)
		if not ascending then
			return a.CreatedTimestamp > b.CreatedTimestamp
		else
			return a.CreatedTimestamp < b.CreatedTimestamp
		end
		
	end)
	
	return results
end

function CharacterStatusEffectTracker:GetCount()
	return TableUtilities.GetKeyCount(self.Current)
end

return CharacterStatusEffectTracker
