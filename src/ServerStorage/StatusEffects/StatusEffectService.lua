local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local StatusEffectStorage = Framework.GetShared("StatusEffectStorage")
local Signal = Framework.GetShared("Signal")
local TableUtilities = Framework.GetShared("TableUtilities")

local CharacterRegistry = Framework.GetServer("CharacterRegistry")
local CharacterStatusEffectTracker = Framework.GetServer("CharacterStatusEffectTracker")
local StatusEffect = Framework.GetServer("StatusEffect")

local ScriptsFolder = script.Parent.Scripts

local StatusEffectService = {
	EffectBlacklisted = Signal.new(),
	EffectTargetInvalid = Signal.new(),
}

local effectTrackers = {}

local function GetModule(name)
	return require(ScriptsFolder:FindFirstChild(name))
end

function StatusEffectService.Apply(params)
	local module = GetModule(params.Name)
	
	local target = params.Target
	local targetCharacter = CharacterRegistry.GetCharacterFromModel(target)
	if not targetCharacter then
		return
	end
	
	if module.IsTargetValid then
		if not module.IsTargetValid(targetCharacter) then
			StatusEffectService.EffectTargetInvalid:Fire(params, targetCharacter)
			return
		end
	end
	
	local tracker = StatusEffectService.GetTracker(targetCharacter)
	
	-- Add default effect params
	params.Params = params.Params or {}
	params.Params = TableUtilities.Reconcile(params.Params, module.Default)
	params.Tracker = tracker
	
	local shouldAdd, blacklistedBy = tracker:ShouldAdd(params) 
	
	if not shouldAdd then
		StatusEffectService.EffectBlacklisted:Fire(params, blacklistedBy)
		return
	end
	
	local existingEffect = tracker:GetEffect(params.Name)
	
	-- There's a stacking function or property, so let the effect decide what to do
	if existingEffect and module.HandleStacking then
		
		local stacks = params.Stacks or 1
		for i = 1, stacks do
			module.HandleStacking(existingEffect, params)
		end
		
		return
	end
	
	-- If there isn't, create an entirely new effect
	return StatusEffectService.Create(module, params)
end

function StatusEffectService.Create(module, params)
	local newEffect = StatusEffect.new(params)
	module.Extend(newEffect)
	module.Apply(newEffect)
	
	if params.Stacks then
		for i = 1, params.Stacks do
			module.HandleStacking(newEffect, params)
		end
	end
	
	return newEffect
end

function StatusEffectService.GetTracker(character)
	local id = CharacterRegistry.GetId(character)
	
	return effectTrackers[id]
end

function StatusEffectService.GetEffect(character, name)
	local id = CharacterRegistry.GetId(character)

	return effectTrackers[id]:GetEffect(name)
end

CharacterRegistry.CharacterAdded:Connect(function(id, character)
	effectTrackers[id] = CharacterStatusEffectTracker.new(character)
end)

CharacterRegistry.CharacterRemoved:Connect(function(id)
	effectTrackers[id]:EndAll()
	effectTrackers[id]:Destroy()
	effectTrackers[id] = nil
end)

return StatusEffectService
