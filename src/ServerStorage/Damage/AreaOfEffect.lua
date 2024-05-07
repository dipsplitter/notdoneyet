local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local QueryRegion = Framework.GetShared("QueryRegion")
local InstanceUtilities = Framework.GetShared("InstanceUtilities")
local TableUtilities = Framework.GetShared("TableUtilities")
local RaycastUtilities = Framework.GetShared("RaycastUtilities")

local AreaOfEffect = {}
AreaOfEffect.__index = AreaOfEffect
AreaOfEffect.ClassName = "AreaOfEffect"

function AreaOfEffect.new(queryRegionParams)
	local self = {
		["QueryRegion"] = QueryRegion.new(queryRegionParams),
		Characters = {},
	}
	setmetatable(self, AreaOfEffect)
	
	return self
end

function AreaOfEffect:GetCharacters(characterFilter, ...)
	local filtered, unfiltered = self.QueryRegion:PerformQuery(...)
	
	local characters = {}
	
	for i, part in filtered do
		local character = InstanceUtilities.GetCharacterAncestor(part)
		if not character then
			continue
		end
		
		if not characters[character] then
			characters[character] = 1
		else
			characters[character] += 1
		end
	end
	
	self.Characters = TableUtilities.FilterDictionary(characters, characterFilter)
	
	return self.Characters
end

function AreaOfEffect:ForEachCharacter(func)
	for character, count in self.Characters do
		func(character, count)
	end
end

function AreaOfEffect:IsInLineOfSight(target)
	local origin = self.QueryRegion:GetOriginPosition()
	
	local result = workspace:Raycast(origin,
		(target:GetPivot().Position - origin).Unit * self.QueryRegion:GetQueryParam("Size"),
		RaycastUtilities.ToRaycastParams(self.QueryRegion:GetQueryParam("OverlapParams"))
	)
	
	if not result then
		return true
	end
	
	if RaycastUtilities.InstanceIsDescendant(result, target) then
		return true
	end
	
	return false
end

return AreaOfEffect
