local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local DamageTypes = Framework.GetShared("DamageTypes")
local TableUtilities = Framework.GetShared("TableUtilities")

local DamageTypesInfo = {}
DamageTypesInfo.__index = DamageTypesInfo

function DamageTypesInfo.new(damageTypesTable, forceFlags, forceProperties)
	local self = {
		Types = damageTypesTable or {},
		Flags = {},
		FlaggedProperties = {},
		FlaggedMultipliers = {},
		
		ForceFlags = forceFlags or {},
		ForceProperties = forceProperties or {},
	}
	setmetatable(self, DamageTypesInfo)
	
	if type(self.Types) == "string" then
		self.Types = {[self.Types] = 1}
	end

	self:SetDamageTypeFlags()
	self:SetProportions()
	self:SetDamageTypeMultiplierValues()
	self:AddDamageTypeDefaultProperties()
	
	self:NormalizeDamageTypeProportions()
	
	self:SetOverallProperties()
	self:SetOverallMultipliers()

	return self
end

function DamageTypesInfo:GetDamageTypeProportion(name)
	if not self.Types[name] then
		return 0
	end

	local info = self.Types[name]
	return info.Proportion or 1
end

--[[
	INPUT:
	
	Fire = {
		Multipliers = {
			FireResistance = 2 or nil,
		}
	}
	
	OUTPUT:
	
	Fire = {
		Multipliers = {
			FireResistance = {
				Value = 2 or 1 (default),
			},
		}
	}
]]
function DamageTypesInfo:SetDamageTypeMultiplierValues()
	for damageTypeName, info in pairs(self.Types) do
		local multipliers = info.Multipliers
		if not multipliers then
			continue
		end

		for attributeName, multiplierInfo in pairs(multipliers) do
			if type(multiplierInfo) == "number" then
				self.Types[damageTypeName].Multipliers[attributeName] = {
					Value = multiplierInfo
				}
			end

			if type(multiplierInfo) == "table" and not multiplierInfo.Value then
				multiplierInfo.Value = 1
			end

		end

	end
end


--[[
	INPUT:
	
	Blast = {
		Proportion = 2
	}
	
	OUTPUT:
	
	B;ast = {
		Proportion = 2,
		Properties = {
			AffectedByRange = true,
		}
	}
]]
function DamageTypesInfo:AddDamageTypeDefaultProperties()
	for damageTypeName, info in pairs(self.Types) do
		local defaultEntry = DamageTypes[damageTypeName].Properties
		if not defaultEntry then
			continue
		end
		
		if info.Properties then
			info.Properties = TableUtilities.Reconcile(info.Properties, defaultEntry)
		else
			info.Properties = TableUtilities.Copy(defaultEntry)
		end
	end
end

function DamageTypesInfo:SetProportions()
	for damageTypeName, info in pairs(self.Types) do
		if type(info) == "table" and info.Proportion then
			continue
		end

		if type(info) == "table" and not info.Proportion then
			info.Proportion = 1
			continue
		end

		if type(info) == "number" then
			self.Types[damageTypeName] = {
				Proportion = info
			}
		end
	end
end

function DamageTypesInfo:NormalizeDamageTypeProportions()
	local total = 0
	for damageTypeName, info in pairs(self.Types) do
		total += self:GetDamageTypeProportion(damageTypeName)
	end

	for damageTypeName, info in pairs(self.Types) do
		self.Types[damageTypeName].Proportion /= total
	end
end

function DamageTypesInfo:SetDamageTypeFlags()
	local forceFlags = self.ForceFlags

	-- Force flags will never be changed
	for flagName, value in pairs(forceFlags) do
		self.Flags[flagName] = {
			Value = value,
			Priority = math.huge,
		}
	end

	-- Decide the damage flags we'll be turning on
	for damageTypeName, info in pairs(self.Types) do
		local defaultFlagsEntry = DamageTypes[damageTypeName] or {}

		for damageTypeFlag, defaultValue in pairs(defaultFlagsEntry.Flags) do		
			local currentFlagsEntry = self.Flags[damageTypeFlag]

			-- Add to current flags
			if not currentFlagsEntry then
				self.Flags[damageTypeFlag] = {
					Value = defaultValue,
					Priority = defaultFlagsEntry.Id,
				}
				continue
			end

			-- If our current priority is lower than the id, override it
			if currentFlagsEntry.Priority < defaultFlagsEntry.Id then
				currentFlagsEntry.Priority = defaultFlagsEntry.Id
				currentFlagsEntry.Value = defaultValue
			end

		end
	end
end

--[[ 
	These properties will be evaluated after individual typed damage is summed
	Ex: The damage was critical -> Set the AffectedByRange property to false for all damage calculations
]]
function DamageTypesInfo:SetOverallProperties()
	local forceProperties = self.ForceProperties

	-- Force properties will never be changed
	for propertyName, value in pairs(forceProperties) do
		self.FlaggedProperties[propertyName] = {
			Value = value,
			Priority = math.huge,
		}
	end

	for flagName in pairs(self.Flags) do
		local defaultFlagEntry = DamageTypes.Flags[flagName] or {}

		if not defaultFlagEntry.Properties then
			continue
		end

		for propertyName, value in pairs(defaultFlagEntry.Properties) do
			local currentEntry = self.FlaggedProperties[propertyName]

			if not currentEntry then
				self.FlaggedProperties[propertyName] = {
					Value = value,
					Priority = defaultFlagEntry.Id,
				}
				continue
			end

			-- If our current priority is lower than the id, override it
			if currentEntry.Priority < defaultFlagEntry.Id then
				currentEntry.Priority = defaultFlagEntry.Id
				currentEntry.Value = value
			end
		end
	end
end

function DamageTypesInfo:SetOverallMultipliers()

	for flagName, value in pairs(self.Flags) do
		local defaultEntry = DamageTypes.Flags[flagName]
		local flagPriority = value.Priority
		local id = defaultEntry.Id
		
		local multipliers = defaultEntry.Multipliers or {}
		if type(value) == "table" and value.Multipliers then
			multipliers = TableUtilities.Reconcile(value.Multipliers, multipliers)
		end
		
		if not multipliers then
			continue
		end
		
		for multiplierName, multiplierValue in multipliers do
			local currentEntry = self.FlaggedMultipliers[multiplierName]
			
			if not currentEntry then
				self.FlaggedMultipliers[multiplierName] = {
					Value = multiplierValue,
					Priority = math.huge,
					Id = defaultEntry.Id
				}
				continue
			end
			
			-- Our priority is lower, so change
			if currentEntry.Priority < flagPriority then
				currentEntry.Priority = flagPriority
				currentEntry.Value = multiplierValue
				currentEntry.Id = id
			elseif currentEntry.Id < id then
				currentEntry.Priority = id
				currentEntry.Value = value
				currentEntry.Id = id
			end

		end
		
	end

end

function DamageTypesInfo:GetDamageTypeMultipliers(damageType)
	if not self.Types[damageType] then
		return {}
	end
	
	return self.Types[damageType].Multipliers or {}
end

function DamageTypesInfo:GetAttributeMultipliersForDamageType(damageType, attributeName)
	if not damageType then
		return self.FlaggedMultipliers[attributeName]
	end
	
	local multipliers = self:GetDamageTypeMultipliers(damageType)
	return multipliers[attributeName]
end

function DamageTypesInfo:GetFlaggedProperty(propertyName)
	return self.FlaggedProperties[propertyName]
end

function DamageTypesInfo:GetPropertyForDamageType(damageType, propertyName)
	local damageTypeInfo = self.Types[damageType]
	if not damageTypeInfo and not damageTypeInfo.Properties then
		return
	end
	
	return damageTypeInfo.Properties[propertyName]
end

return DamageTypesInfo