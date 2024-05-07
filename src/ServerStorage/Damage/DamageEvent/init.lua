local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local DamageTypes = Framework.GetShared("DamageTypes")
local CharacterAttributesUtilities = Framework.GetShared("CharacterAttributesUtilities")
local DistanceUtilities = Framework.GetShared("DistanceUtilities")
local Math = Framework.GetShared("Math")

local CharacterRegistry = Framework.GetServer("CharacterRegistry")
local DamageTypesInfo = Framework.GetServer("DamageTypesInfo")
local InflictorInfo = Framework.GetServer("InflictorInfo")

-- The universal flags are Min and Max
local function ApplyDefaultMultiplierFlags(currentValue, multipliers)
	local flags = {}
	local multiplier = 1
	
	if multipliers then
		flags = multipliers.Flags
		multiplier = multipliers.Value
	end
	
	return math.clamp(currentValue * multiplier, flags.Min or 0, flags.Max or math.huge)
end

local function ApplyLinearRangedFalloff(falloffInfo, baseDamage, origin, position)
	local maxDamage = baseDamage * (falloffInfo.Max or 1)
	local minDamage = baseDamage * (falloffInfo.Min or 1)
	local distanceForMax = falloffInfo.MaxDistance
	local distanceForMin = falloffInfo.MinDistance
	
	local distance = DistanceUtilities.GetDistance(origin, position)
	local ratio = (distance - distanceForMin) / (distanceForMax - distanceForMin)
	
	return math.clamp(
		Math.Lerp(minDamage, maxDamage, ratio),
		minDamage,
		maxDamage
	)
end

--[[
	*** PARAMETERS ***
	
	Target: the character model that we want to damage
	Attacker: the character model that is dealing the damage
	
	Damage: number of damage to deal
	
	DamageType: {
		damage type: {
			Proportion: n, 
			Multipliers:
				{damage multiplier, resistance name: k
				OR { Value: k, Flags: {relevant flags...} }, ...}
			}
		} OR string id of valid damage type
	Determines how we should treat the damage and what multipliers / resistances to apply as a result
	Proportion determines how much damage is treated as a certain type
	EX: 0.5 fire, 0.5 bullet with a 100% fire resistance would do half damage as the fire component is entirely blocked
	
	Multipliers determine how damage modifiers are affected in the final damage calculation
	EX: 0.5 fire resistance for a fire typed damage event would halve the effectiveness of the target's fire resistance attribute against it
	
]]

local DamageEvent = {}
DamageEvent.__index = DamageEvent
DamageEvent.ClassName = "DamageEvent"

-- Only the target and inflictor are required
function DamageEvent.new(params)
	local self = {
		Inflictor = InflictorInfo.new(params.Inflictor, params.InflictorInfo), -- The weapon the attacker was using or a projectile spawned
	}
	setmetatable(self, DamageEvent)
	
	local target = params.Target
	local attacker = params.Attacker
	
	if Framework.IsObject(target) then
		self.Target = target
	else
		self.Target = CharacterRegistry.GetCharacterFromModel(target)
	end
	
	if Framework.IsObject(attacker) then
		self.Attacker = attacker
	else
		self.Attacker = CharacterRegistry.GetCharacterFromModel(attacker) or CharacterRegistry.GetCharacterFromModel( self.Inflictor:GetCharacterOwner() )
	end
	
	self.Origin = params.Origin or self.Inflictor:GetPosition()
	self.BaseDamage = params.Damage or self.Inflictor:GetDamageProperty("BaseDamage")
	self.IsPosthumous = Framework.DefaultTrue(params.IsPosthumous or self.Inflictor:GetDamageProperty("IsPosthumous"))

	self.CurrentDamage = self.BaseDamage
	self.CurrentArmorDamage = 0
	
	-- For accumulators
	self.TotalDamage = 0
	self.TotalArmorDamage = 0
	
	self.DamageType = DamageTypesInfo.new( 
		params.DamageType or self.Inflictor:GetDamageProperty("DamageType"),
		params.ForceFlags or self.Inflictor:GetDamageProperty("ForceFlags"),
		params.ForceProperties or self.Inflictor:GetDamageProperty("ForceProperties")
	)
	
	return self
end

function DamageEvent:SetInflictor(inflictor, info)
	if self.Inflictor then
		self.Inflictor:Destroy()
	end
	
	self.Inflictor = InflictorInfo.new(inflictor, info)
	
	local inflictor = self.Inflictor
	
	self.Origin = inflictor:GetPosition()
	self.BaseDamage = inflictor:GetDamageProperty("BaseDamage")
	self.IsPosthumous = Framework.DefaultTrue(inflictor:GetDamageProperty("IsPosthumous"))
	
	self.DamageType = DamageTypesInfo.new( 
		inflictor:GetDamageProperty("DamageType"),
		inflictor:GetDamageProperty("ForceFlags"),
		inflictor:GetDamageProperty("ForceProperties")
	)
end

-- TODO: Checks the attacker's status effects and conditions (e.g. are they crit boosted?)
function DamageEvent:AutoMarkFlags()
	
end

function DamageEvent:GetCharacterAttributeWithMultipliers(attributeName, damageType, character)
	character = character or self.Target
	if not character then
		return false
	end
	
	local value = character:GetCharacterAttribute(attributeName)
	if not value then
		return false
	end
	
	local multipliers = self.DamageType:GetAttributeMultipliersForDamageType(damageType, attributeName)
	
	return ApplyDefaultMultiplierFlags(value, multipliers)
end

function DamageEvent:GetDamageForDamageType(damageTypeName)
	local damageTypeInfo = self.DamageType.Types[damageTypeName]
	local proportion = damageTypeInfo.Proportion
	
	-- Factor in target resistance
	local typedResistance = self:GetCharacterAttributeWithMultipliers(`{damageTypeName}DamageResistance`, damageTypeName)
	local generalResistance = self:GetCharacterAttributeWithMultipliers(`DamageResistance`, damageTypeName)
	
	local targetArmor = self.Target:GetCharacterAttribute("Armor")
	local armorDamage = 0
	
	-- Factor in the attacker's damage multipliers
	local typedAttackerBonus, generalAttackerBonus = 1, 1
	if self.Attacker then
		typedAttackerBonus = self:GetCharacterAttributeWithMultipliers(`{damageTypeName}DamageMultiplier`, damageTypeName, self.Attacker)
		generalAttackerBonus = self:GetCharacterAttributeWithMultipliers(`DamageMultiplier`, damageTypeName, self.Attacker)
	end
	
	
	local damage = self.CurrentDamage * proportion * typedResistance * typedAttackerBonus * generalResistance * generalAttackerBonus
	
	local properties = damageTypeInfo.Properties
	if not properties then
		return damage
	end
	
	local targetPos = self.Target:GetPosition()
	if properties.AffectedByRange then
		damage = ApplyLinearRangedFalloff(
			properties.DistanceModifiers or self.Inflictor:GetDamageProperty("DistanceModifiers"), 
			damage, 
			if self.Attacker then self.Attacker:GetPosition() else self.Origin, 
			targetPos
		)
	end
	
	if properties.AffectedBySplash and self.Origin then
		damage = ApplyLinearRangedFalloff(
			properties.SplashModifiers or self.Inflictor:GetDamageProperty("SplashModifiers"),
			damage,
			self.Origin,
			targetPos
		)
	end

	return damage
end

function DamageEvent:GetArmorDamageForDamageType(damageTypeName, totalDamage)
	local targetArmor = self.Target:GetCharacterAttribute("Armor")
	if not targetArmor then
		return 0
	end
	
	if targetArmor <= 0 then
		return 0
	end

	local typedArmorAbsorption = self:GetCharacterAttributeWithMultipliers(`{damageTypeName}ArmorAbsorption`, damageTypeName)
	local generalArmorAbsorption = self:GetCharacterAttributeWithMultipliers(`ArmorAbsorption`, damageTypeName)
	local armorDamage = totalDamage * typedArmorAbsorption * generalArmorAbsorption
	
	self.CurrentArmorDamage += math.min(targetArmor - self.CurrentArmorDamage, armorDamage)
end

function DamageEvent:ApplyDamageFlagMultipliers()
	for flagName, value in pairs(self.DamageType.Flags) do
		local resistance = self:GetCharacterAttributeWithMultipliers(`{flagName}DamageResistance`)
		local attackerBonus = 1
		
		if self.Attacker then
			attackerBonus = self:GetCharacterAttributeWithMultipliers(`{flagName}DamageMultiplier`, self.Attacker)
		end
		
		self.CurrentDamage *= attackerBonus * resistance 
	end
end

-- TODO. I am going to kill myself if I have to modify these damage scripts again
function DamageEvent:ApplyOverallMultipliers()
	for multiplierName, info in pairs(self.DamageType.FlaggedMultipliers) do
		self.CurrentDamage *= info.Value
	end
end

function DamageEvent:ApplySelfDamageMultipliers()
	if self.Target ~= self.Attacker then
		return
	end
	
	local inflictorSelfDamageScale = self.Inflictor:GetDamageProperty("SelfDamageScale")
	if not inflictorSelfDamageScale then
		return
	end
	
	self.CurrentDamage *= inflictorSelfDamageScale
end

function DamageEvent:CalculateDamage()
	self:ApplyDamageFlagMultipliers()
	self:ApplyOverallMultipliers()
	self:ApplySelfDamageMultipliers()
	
	local totalDamage = 0 
	for damageTypeName in self.DamageType.Types do
		local typedDamage = self:GetDamageForDamageType(damageTypeName)
		local armorDamage = self:GetArmorDamageForDamageType(damageTypeName, typedDamage)
		
		totalDamage += typedDamage
	end

	self.CurrentDamage = totalDamage
end

function DamageEvent:DealDamage()
	if not self.Target then
		return
	end
	
	if not self.Target.Attributes or not getmetatable(self.Target) then
		return
	end
	
	if self.Target:IsDead() then
		return
	end
	
	self.CurrentDamage = self.BaseDamage
	self.CurrentArmorDamage = 0
	
	self:CalculateDamage()
	
	-- We will arbitrarily round up health damage and round down armor damage
	
	local health = self.Target:GetCharacterAttribute("Health")
	local healthDamage = math.ceil(self.CurrentDamage - self.CurrentArmorDamage)
	
	local armor = self.Target:GetCharacterAttribute("Armor")
	local armorDamage = math.floor(self.CurrentArmorDamage)
	
	-- Return the actual damage taken; if we did 300 to a 100 hp target, we would have done 100 damage
	local healthDamageDone = math.min(health, healthDamage)
	local armorDamageDone = math.min(armor, armorDamage)
	
	if false then
		print(`{self.Target:GetModel().Name} took {healthDamage + armorDamage} damage ({healthDamage} health, {armorDamage} armor)`)
	end

	self.Target:SetCharacterAttribute("Health", 
		health - healthDamage
	)
	
	if armor then

		self.Target:SetCharacterAttribute("Armor", 
			armor - armorDamage
		)

	end
	
	return {
		Health = {
			Dealt = healthDamageDone,
			Total = healthDamage,
		}, 
		Armor = {
			Dealt = armorDamageDone,
			Total = armorDamage,
		}
	}
end

return DamageEvent