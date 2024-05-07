local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local TableUtilities = Framework.GetShared("TableUtilities")

local InflictorInfo = {}
InflictorInfo.__index = InflictorInfo

function InflictorInfo.new(inflictor, otherInfo)
	if not inflictor then
		return
	end
	
	local self = {
		Inflictor = inflictor,
		Info = otherInfo,
	}
	setmetatable(self, InflictorInfo)
	
	if inflictor:IsA("Projectile") then
		self.Type = "Projectile"
	elseif inflictor:IsA("BaseItem") then
		self.Type = "Item"
	elseif inflictor:IsA("StatusEffect") then
		self.Type = "StatusEffect"
	end
	
	return self
end

function InflictorInfo:GetObject()
	return self.Inflictor
end

function InflictorInfo:GetName()
	return self.Inflictor.Id
end

function InflictorInfo:GetPosition()
	if self.Type == "Projectile" then
		return self.Inflictor.DataTable:Get("CFrame").Position
	elseif self.Type == "Item" then
		
		local owner = self.Inflictor.Character
		if owner then
			return owner:GetPivot().Position
		end
		
		return self.Inflictor.ItemModel:GetWorldPosition()
	end
end

function InflictorInfo:GetCharacterOwner()
	if self.Type == "Projectile" or self.Type == "Item" then
		return self.Inflictor:GetCurrentOwner()
	elseif self.Type == "StatusEffect" then
		return self.Inflictor:GetCharacterSource()
	end
end

function InflictorInfo:GetDamageProperty(name)
	local damageProperties = self:GetProperty("DamageProperties")
	
	if not damageProperties then
		return
	end
	
	if damageProperties[name] then
		return damageProperties[name]
	end
	
	return self:GetProperty(name)
end

function InflictorInfo:GetDamageProperties()
	return self:GetProperty("DamageProperties")
end

function InflictorInfo:GetKnockbackProperties(name)
	local damageProperties = self:GetProperty("DamageProperties")

	if not damageProperties then
		return
	end

	return damageProperties.KnockbackProperties
end

function InflictorInfo:GetProperty(statName)
	if self.Type == "Projectile" then
		
		local directStat = self.Inflictor:GetStat(statName)
		if directStat then
			return directStat
		end
		
		
	elseif self.Type == "Item" then
		
		if self.Info and self.Info[statName] then
			return self.Info[statName]
		end
		
		local actionName = self.Info.Action
		local propertyPath = self.Info[`{statName}Path`]
		
		if actionName then
			
			local action = self.Inflictor:GetActionManager():GetAction(actionName)
			if propertyPath then
				return TableUtilities.GetValueFromPath(action.Config, propertyPath)
			end
			
			return action:GetConfig(statName)
		end
		
		-- Don't. This should never run
		return TableUtilities.RecursiveFind(self.Inflictor.Properties.Data, statName)
		
	elseif self.Type == "StatusEffect" then
		
		if self.Info and self.Info[statName] then
			return self.Info[statName]
		end
		
		if self.Inflictor.GetParam then
			return self.Inflictor:GetParam(statName)
		end
		
	end
end

function InflictorInfo:Destroy()
	table.clear(self)
	setmetatable(self, nil)
	table.freeze(self)
end

return InflictorInfo