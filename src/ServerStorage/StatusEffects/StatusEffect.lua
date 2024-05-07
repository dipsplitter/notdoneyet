local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local BaseClass = Framework.GetShared("BaseClass")
local Timer = Framework.GetShared("Timer")

local CharacterRegistry = Framework.GetServer("CharacterRegistry")
local StatusEffectProperties = Framework.GetServer("StatusEffectProperties")
local StatusEffectStacking = Framework.GetServer("StatusEffectStacking")

local StatusEffect = {}
StatusEffect.__index = StatusEffect
StatusEffect.ClassName = "StatusEffect"
setmetatable(StatusEffect, BaseClass)

function StatusEffect.new(params)
	local self = BaseClass.new()
	setmetatable(self, StatusEffect)
	
	self.Name = params.Name
	self.ExtendedBy = {}
	self.Source = params.Source -- The character / item / entity from item that applied this
	
	self:InjectObject("Target", CharacterRegistry.GetCharacterFromModel(params.Target))
	self:InjectObject("Tracker", params.Tracker)
	
	self.Tracker:Add(self)
	
	self.CreatedTimestamp = workspace:GetServerTimeNow()
	
	self.TimesStacked = 1 -- This is the first stack
	self.Params = params.Params or {}
	
	-- Create the damage properties table
	for keyName, value in self.Params do
		if not StatusEffectProperties.DamageProperties[keyName] then
			continue
		end
		
		if not self.Params.DamageProperties then
			self.Params.DamageProperties = {}
		end
		self.Params.DamageProperties[keyName] = value
	end
	
	self.Timer = Timer.new(self.Params)
	self.Timer.Duration = {self.Params, "Duration"}
	
	self:AddConnections({
		AutoDestroy = self.Timer:ConnectTo("Ended", function(completed, duration, wasDestroyed)
			if wasDestroyed then
				return
			end
			
			if not self:ShouldDestroy(completed, duration, wasDestroyed) then
				return
			end
			
			self:CleanupConnection("AutoDestroy")	
			self:Destroy()
		end),
		
		TargetDeath = self.Target:ConnectTo("Died", function()
			self.Timer:Stop()
		end)
	})
	
	return self
end

function StatusEffect:GetTargetId()
	return self.Target:GetModel():GetAttribute("CharacterID")
end

function StatusEffect:IsTargetDead()
	if getmetatable(self.Target) then
		return self.Target:IsDead()
	else
		return true
	end
end

function StatusEffect:GetParams()
	return self.Params
end

function StatusEffect:GetCharacterSource()
	local source = self.Source
	if not source then
		return
	end
	
	if typeof(source) == "Model" then
		return source
	end
	
	if source:IsA("Projectile") or source:IsA("BaseItem") then
		return source:GetCurrentOwner()
	end
end

function StatusEffect:ShouldAddOtherEffect(creationParams)
	local blacklist = self:GetParam("Blacklist")
	if not blacklist then
		return true
	end
	
	local name = creationParams.Name
	
	if blacklist[name] then
		return false
	end
	
	return true
end

function StatusEffect:ShouldDestroy(completed, duration, wasDestroyed)
	return true
end

function StatusEffect:HandleStacking(newParams)
	self.TimesStacked += 1
	
	local stackingFunctions = self.Params.StackingParams
	for i, functionName in stackingFunctions do
		StatusEffectStacking[functionName](self, newParams)
	end
end

function StatusEffect:GetParam(paramName)
	return self.Params[paramName]
end

function StatusEffect:End()
	self.Timer:Stop()
end

function StatusEffect:Destroy()
	self.Tracker:Remove(self)
	BaseClass.Destroy(self)
end

return StatusEffect
