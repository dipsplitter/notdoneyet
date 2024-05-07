local ALIASES = {
	TimerConnection = "InvigorateConnection",
	EndConnection = "InvigorateEnd",
	VisualName = "Invigorate",
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)

local VisualsReplicator = Framework.GetServer("VisualsReplicator")

local StatusEffect_Invigorate = {
	
	Default = {
		StackingParams = {"ResetDuration", "Override", "OverrideSource"},
		
		FireDamageMultiplierIncrease = 0.15,
		
		MaxStacks = 5,
		
		Duration = 20,
	},
	
}

function StatusEffect_Invigorate.Extend(statusEffect)
	statusEffect.Name = "Invigorate"
	
	statusEffect.CurrentDamageIncrease = 0
	
	statusEffect:AddConnections({
		[ALIASES.EndConnection] = statusEffect.Timer:ConnectTo("Ended", function(completed, duration, wasDestroyed)
			StatusEffect_Invigorate.Stop(statusEffect)
		end)
	})
end

function StatusEffect_Invigorate.ReduceResistance(statusEffect)
	local target = statusEffect.Target
	
	local fireDamageMultipliers = target.Attributes:GetModifierObject("FireDamageMultiplier")
	
	statusEffect.CurrentDamageIncrease += statusEffect:GetParam("FireDamageMultiplierIncrease")
	
	fireDamageMultipliers:SetAdd("InvigorateEffect", statusEffect.CurrentDamageIncrease)
end

function StatusEffect_Invigorate.Apply(statusEffect)
	local id = VisualsReplicator.Replicate(ALIASES.VisualName, {CharacterId = statusEffect:GetTargetId()})
	statusEffect.InvigorateVisualId = id
	
	statusEffect.Timer:Start()
	
	StatusEffect_Invigorate.ReduceResistance(statusEffect)
end

function StatusEffect_Invigorate.Stop(statusEffect)
	if statusEffect:IsTargetDead() then
		return
	end
	
	local target = statusEffect.Target
	local fireDamageMultipliers = target.Attributes:GetModifierObject("FireDamageMultiplier")
	fireDamageMultipliers:Remove("InvigorateEffect")
	VisualsReplicator.Stop(statusEffect.InvigorateVisualId)
end

function StatusEffect_Invigorate.HandleStacking(currentEffect, newEffectParams)
	currentEffect:HandleStacking(newEffectParams)
	
	if currentEffect.TimesStacked <= currentEffect:GetParam("MaxStacks") then
		StatusEffect_Invigorate.ReduceResistance(currentEffect)
	end
end

function StatusEffect_Invigorate.IsTargetValid(character)
	return not character:IsDead()
end

return StatusEffect_Invigorate
