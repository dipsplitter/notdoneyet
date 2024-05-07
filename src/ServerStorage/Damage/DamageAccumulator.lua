local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local DamageService = Framework.GetServer("DamageService")

local DamageAccumulator = {}
DamageAccumulator.__index = DamageAccumulator

function DamageAccumulator.new(params)
	local self = {
		Attacker = params.Attacker,
		Inflictor = params.Inflictor,
		InflictorInfo = params.InflictorInfo,
		
		Targets = {}
	}
	setmetatable(self, DamageAccumulator)
	
	return self
end

function DamageAccumulator:AddDamage(target, damage)
	if not self.Targets[target] then
		self.Targets[target] = {
			Event = DamageService.CreateEvent({
				Attacker = self.Attacker,
				Inflictor = self.Inflictor,
				InflictorInfo = self.InflictorInfo,
				Target = target
			}),
			
			CurrentBaseDamage = 0
		}
	end
	
	self.Targets[target].CurrentBaseDamage += damage
end

function DamageAccumulator:ApplyDamage(target)
	local eventInfo = self.Targets[target]
	if not eventInfo then
		return
	end
	
	local event = eventInfo.Event
	event.BaseDamage = eventInfo.CurrentBaseDamage
	
	DamageService.DealDamage(event)
end

function DamageAccumulator:ApplyDamageToAll()
	for target, eventInfo in self.Targets do
		local event = eventInfo.Event
		event.BaseDamage = eventInfo.CurrentBaseDamage
		
		DamageService.DealDamage(event)
	end
end

return DamageAccumulator
