local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local TableUtilities = Framework.GetShared("TableUtilities")

local StatusEffectProperties = Framework.GetServer("StatusEffectProperties")

local function SetDamageProperties(params)
	if not params.DamageProperties then
		return
	end
	
	for keyName, newValue in params do
		if StatusEffectProperties.DamageProperties[keyName] then
			params.DamageProperties[keyName] = newValue
		end
	end

end

local StatusEffectStacking = {}

function StatusEffectStacking.Override(originalEffect, newProperties)
	local newParams = newProperties.Params
	local currentParams = originalEffect.Params
	
	for keyName, newValue in newParams do
		local currentValue = currentParams[keyName]
		
		if (StatusEffectProperties.ImprovedWhenIncreased[keyName] and newValue > currentValue) 
			or (StatusEffectProperties.ImprovedWhenDecreased[keyName] and newValue < currentValue) then
			
			currentParams[keyName] = newValue
		end
	end
	
	SetDamageProperties(originalEffect.Params)
end

function StatusEffectStacking.OverrideUnconditionally(originalEffect, newProperties)
	local newParams = newProperties.Params
	
	originalEffect.Params = TableUtilities.DeepMerge(originalEffect.Params, newParams)
	
	SetDamageProperties(originalEffect.Params)
end

function StatusEffectStacking.OverrideSource(originalEffect, newProperties)
	originalEffect.Source = newProperties.Source
end

function StatusEffectStacking.ResetDuration(originalEffect)
	originalEffect.Timer.Current = 0
end

return StatusEffectStacking
