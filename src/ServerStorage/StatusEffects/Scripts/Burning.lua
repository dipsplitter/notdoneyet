local ALIASES = {
	IncrementEvent = "BurningDamageIncrement",
	TimerConnection = "BurningDamageIncrementConnection",
	EndConnection = "BurningEnd",
	VisualName = "Burning",
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)

local VisualsReplicator = Framework.GetServer("VisualsReplicator")
local DamageService = Framework.GetServer("DamageService")

local StatusEffect_Burning = {
	
	Default = {
		StackingParams = {"ResetDuration", "Override", "OverrideSource"},

		Duration = 8,
		Tick = 0.5,
		BaseDamage = 4,
		DamageType = "Fire",

	},
	
}

function StatusEffect_Burning.Extend(statusEffect)
	statusEffect.Name = "Burning"
	
	statusEffect.Timer:AddIncrementEvents({
		[ALIASES.IncrementEvent] = {
			FireAtStart = true,
			Duration = {statusEffect:GetParams(), "Tick"},
		}
	})
	
	statusEffect.DamageEvent = DamageService.CreateEvent({
		Target = statusEffect.Target,
		Inflictor = statusEffect,
	})
	
	statusEffect:AddConnections({
		[ALIASES.TimerConnection] = statusEffect.Timer:ConnectTo("IncrementReached", function(name)
			
			if name ~= ALIASES.IncrementEvent then
				return
			end
			
			DamageService.DealDamage(statusEffect.DamageEvent)
		end),
		
		[ALIASES.EndConnection] = statusEffect.Timer:ConnectTo("Ended", function(completed, duration, wasDestroyed)
			StatusEffect_Burning.Stop(statusEffect)
		end)
	})
end

function StatusEffect_Burning.Apply(statusEffect)
	local id = VisualsReplicator.Replicate(ALIASES.VisualName, {CharacterId = statusEffect:GetTargetId()})
	statusEffect.BurningVisualId = id
	
	statusEffect.Timer:Start()
end

function StatusEffect_Burning.Stop(statusEffect)
	if statusEffect:IsTargetDead() then
		return
	end
	
	VisualsReplicator.Stop(statusEffect.BurningVisualId)
end

function StatusEffect_Burning.HandleStacking(currentEffect, newEffectParams)
	currentEffect:HandleStacking(newEffectParams)
end

function StatusEffect_Burning.IsTargetValid(character)
	return not character:IsDead()
end

return StatusEffect_Burning
