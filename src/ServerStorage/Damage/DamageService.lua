local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local EnumService = Framework.GetShared("EnumService")
local IndicatorTypes = EnumService.GetEnum("Enum_IndicatorTypes")

local DamageEvent = Framework.GetServer("DamageEvent")
local Knockback = Framework.GetServer("Knockback")

local NETWORK = Framework.Network()
local IndicatorEvent = NETWORK.Event("Indicator")

local DamageService = {}

function DamageService.FireAttacker(damageEvent, damageResults)
	local attacker = damageEvent.Attacker
	local target = damageEvent.Target
	
	-- Did we hurt ourselves? Is the person we hurt dead?
	if attacker == target then
		return
	end
	
	if attacker and attacker.Player then
		
		IndicatorEvent:Fire({
			IndicatorType = IndicatorTypes.Damage,
			DamageEvent = damageEvent,
			DamageResults = damageResults
		}, attacker.Player)
		
	end
end

function DamageService.DealDamage(params)
	local damageEvent = params
	if params.ClassName ~= "DamageEvent" then
		damageEvent = DamageEvent.new(params)
	end

	local damageResults = damageEvent:DealDamage()
	
	if not damageResults then
		return
	end
	
	DamageService.FireAttacker(damageEvent, damageResults)
	DamageService.ApplyKnockback(damageEvent)
	
	return damageResults
end

function DamageService.ApplyKnockback(params)
	local knockbackValue = if params.ClassName == "DamageEvent" then params.CurrentDamage else params.Value
	
	local knockback = Knockback.new({
		Target = params.Target,
		Value = knockbackValue,
		Inflictor = params.Inflictor
	})
	
	knockback:Apply()
end

function DamageService.CreateEvent(params)
	return DamageEvent.new(params)
end

return DamageService
