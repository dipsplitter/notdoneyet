local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local QueryRegion = Framework.GetShared("QueryRegion")
local InstanceUtilities = Framework.GetShared("InstanceUtilities")
local WeaponAttacks = Framework.GetShared("WeaponAttacks")

local function DefaultFilterFunction(hitInstance, hitCharacters)
	local character = InstanceUtilities.GetCharacterAncestor(hitInstance)

	if not character then
		return false
	end
	
	if table.find(hitCharacters, character) then
		return false
	end
	
	return true
end

local function FormatResultsForReplication(results, shouldReplicateCallback)
	local formatted = {}

	for i = 1, #results do
		local hitInstance = results[i]
		
		if shouldReplicateCallback and not shouldReplicateCallback(hitInstance) then
			continue
		end

		table.insert(formatted, {
			["Instance"] = hitInstance,
		}) 
	end
	
	return formatted
end

local MeleeHitbox = {}

function MeleeHitbox.IgnoreDuplicateCharacter(hitInstance, hitCharacters)
	local character = InstanceUtilities.GetCharacterAncestor(hitInstance)

	if hitCharacters[character] then
		return false
	else
		hitCharacters[character] = true
	end
	
	return true
end

function MeleeHitbox.CreateHitbox(item)
	local handle = item.ItemModel.Handle
	
	local overlapParams = OverlapParams.new()
	overlapParams.CollisionGroup = "Projectile"
	overlapParams.FilterDescendantsInstances = {item.Character}
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	
	item.MeleeHitbox = QueryRegion.new({
		Origin = handle:FindFirstChild("HitboxOrigin") or handle,
		QueryParams = {
			["OverlapParams"] = overlapParams,
		},

		QueryType = "Box",
	})
end

function MeleeHitbox.BeginHitbox(item, actionName, properties)
	if not item.MeleeHitbox then
		MeleeHitbox.CreateHitbox(item)
	end

	local actionManager = item:GetActionManager()
	local action = actionManager:GetAction(actionName)

	item.MeleeHitbox:SetProperties(properties)
	
	properties.Filter = properties.Filter or DefaultFilterFunction
	item.MeleeHitbox:ContinuousQuery(properties)
end

function MeleeHitbox.ReplicateResults(item, actionName, shouldReplicateCallback)
	local results = FormatResultsForReplication(item.MeleeHitbox.ContinuousQueryResults, shouldReplicateCallback)
	
	if not next(results) then
		WeaponAttacks.StartAttack(item, actionName, results)
	else
		results.SIGNATURE = "MultiCharacterRaycastResult"

		WeaponAttacks.ReplicateAttack(item, actionName, results)
	end
end

function MeleeHitbox.EndHitbox(item, actionName)
	--[[
	local actionManager = item:GetActionManager()
	local action = actionManager:GetAction(actionName)
	local maximumHitCharacters = action:GetConfig("MaxHits")
	]]

	item.MeleeHitbox:StopContinuousQuery()
end

return MeleeHitbox
