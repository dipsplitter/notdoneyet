local ALIASES = {
	TimerConnection = "ImmolateConnection",
	EndConnection = "ImmolateEnd",
	VisualName = "Immolate",
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)

local VisualsReplicator = Framework.GetServer("VisualsReplicator")

local StatusEffect_Immolate = {
	
	Default = {
		StackingParams = {"ResetDuration", "Override", "OverrideSource"},
		
		FireResistanceDecrease = 0.25,
		MaxStacks = 10,
		
		Duration = 10,
	},
	
}

function StatusEffect_Immolate.Extend(statusEffect)
	statusEffect.Name = "Immolate"
	
	statusEffect.CurrentResistanceDecrease = 0
	
	statusEffect:AddConnections({
		[ALIASES.EndConnection] = statusEffect.Timer:ConnectTo("Ended", function(completed, duration, wasDestroyed)
			StatusEffect_Immolate.Stop(statusEffect)
		end)
	})
end

function StatusEffect_Immolate.ReduceResistance(statusEffect)
	local target = statusEffect.Target
	
	local fireResistanceModifiers = target.Attributes:GetModifierObject("FireDamageResistance")
	
	-- Counter-intuitive
	statusEffect.CurrentResistanceDecrease += statusEffect:GetParam("FireResistanceDecrease")
	
	fireResistanceModifiers:SetAdd("ImmolateEffect", statusEffect.CurrentResistanceDecrease)
end

function StatusEffect_Immolate.Apply(statusEffect)
	local id = VisualsReplicator.Replicate(ALIASES.VisualName, {CharacterId = statusEffect:GetTargetId()})
	statusEffect.ImmolateVisualId = id
	
	statusEffect.Timer:Start()
	
	StatusEffect_Immolate.ReduceResistance(statusEffect)
end

function StatusEffect_Immolate.Stop(statusEffect)
	if statusEffect:IsTargetDead() then
		return
	end
	
	local target = statusEffect.Target
	local fireResistanceModifiers = target.Attributes:GetModifierObject("FireDamageResistance")
	fireResistanceModifiers:Remove("ImmolateEffect")
	VisualsReplicator.Stop(statusEffect.ImmolateVisualId)
end

function StatusEffect_Immolate.HandleStacking(currentEffect, newEffectParams)
	currentEffect:HandleStacking(newEffectParams)
	
	if currentEffect.TimesStacked <= currentEffect:GetParam("MaxStacks") then
		StatusEffect_Immolate.ReduceResistance(currentEffect)
	end
end

function StatusEffect_Immolate.IsTargetValid(character)
	return not character:IsDead()
end

return StatusEffect_Immolate
