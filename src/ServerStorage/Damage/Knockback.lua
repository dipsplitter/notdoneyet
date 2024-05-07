local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)

local CharacterRegistry = Framework.GetServer("CharacterRegistry")

local NETWORK = Framework.Network()
local VelocityEvent = NETWORK.Event("Velocity")

local BASE_BOUDNING_BOX_VOLUME = 5 * 5 * 5
local NEGLIGIBLE_MAGNITUDE = 150
local DOWN_VECTOR = Vector3.new(0, 2, 0)

local Knockback = {}
Knockback.__index = Knockback

function Knockback.new(params)
	local self = {
		Target = params.Target,
		Value = params.Value,
		
		Inflictor = params.Inflictor,
	}
	setmetatable(self, Knockback)
	
	if not Framework.IsObject(self.Target) then
		self.Target = CharacterRegistry.GetCharacterFromModel(self.Target)
	end
	
	return self
end

function Knockback:GetDirection()
	local inflictorPosition = self.Inflictor:GetPosition()
	local targetPosition = self.Target:GetPosition()
	
	if inflictorPosition  then
		if math.abs(inflictorPosition.Y - targetPosition.Y) > DOWN_VECTOR.Y then
			return (targetPosition - inflictorPosition).Unit
		end
		-- Temporary: Consider the target to be higher than the inflictor
		-- Applying a force to someone who's grounded kills most of it because of friction (I think)
		return (targetPosition + DOWN_VECTOR - inflictorPosition).Unit
	end
	
	return (self.Target:GetPosition() - DOWN_VECTOR).Unit
end

function Knockback:ApplyInflictorModifiers()
	local knockbackParams = self.Inflictor:GetKnockbackProperties()
	if not knockbackParams then
		return
	end

	if knockbackParams.OverrideValue then
		self.Value = knockbackParams.OverrideValue
	end
	
	-- Scale the force if we hurt ourselves
	if knockbackParams.SelfDamageScale and self.Target:GetModel() == self.Inflictor:GetCharacterOwner() then
		self.Value *= knockbackParams.SelfDamageScale
	end
	
	if knockbackParams.Scale then
		self.Value *= knockbackParams.Scale
	end
	
	if knockbackParams.MinValue then
		self.Value = math.max(knockbackParams.MinValue, self.Value)
	end
	
	if knockbackParams.MaxValue then
		self.Value = math.min(knockbackParams.MaxValue, self.Value)
	end
end

function Knockback:Apply(customDirection)
	local directionVector = customDirection or self:GetDirection()
	
	self:ApplyInflictorModifiers()
	
	-- Factor in damage
	directionVector *= (self.Value * BASE_BOUDNING_BOX_VOLUME)
	
	-- Target's knockback resistance
	directionVector *= self.Target:GetCharacterAttribute("KnockbackResistance")
	
	-- Too small to be even worth doing anything
	if directionVector.Magnitude < NEGLIGIBLE_MAGNITUDE then
		return
	end
	
	-- This is a player, so we need to fire the Velocity event
	if self.Target.Player then
		VelocityEvent:Fire(
			{Vector = directionVector}, 
			self.Target.Player)
		
		return
	end
	 
	self.Target:GetModel().PrimaryPart:ApplyImpulse(directionVector)
end

return Knockback
