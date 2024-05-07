local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Framework = require(ReplicatedStorage.Framework)
local Client = Framework.GetClient("Client")

local ItemAnimationModifiers = Framework.GetShared("ItemAnimationModifiers")

local IsServer = Framework.IsServer
local IsClient = Framework.IsClient

local currentMouseDelta = Vector3.zero

local function IsAngleInRange(angle, lower, upper)
	local upperLowerDifference = upper - lower
	upper = if upperLowerDifference < 0 then upperLowerDifference + 360 else upperLowerDifference
	
	local angleLowerDifference = angle - lower
	angle = if angleLowerDifference < 0 then angleLowerDifference + 360 else angleLowerDifference
	
	return (angle < upper)
end

local DirectionalAttacks = {}

function DirectionalAttacks.SetServerDirectionBasedOnAnimations(item)
	if not IsServer then
		return
	end
	
	item:AddConnections({
		SetMeleeDirection = item.Animator:ConnectTo("AnimationStarted", function(animationName, config)
			if config and config.Name then
				item.CurrentDirection = DirectionalAttacks.GetDirectionNameFromAnimationPath(animationName)
			end
		end),
	})
end

function DirectionalAttacks.AddAnimationModifiers(item, actionName, keys)
	local actionManager = item:GetActionManager()
	local action = actionManager:GetAction(actionName)
	
	local directionsTable = action:GetConfig("Directions")
	
	local animator = item.Animator
	for directionName in directionsTable do
		local animationObject = animator:GetAnimation(directionName)
		
		if not animationObject then
			return
		end
		
		local directionConfig = action:GetConfig(directionName)
		
		for trackName, modifiers in keys do
			local modifierTable = {
				Action = actionName,
				Modifiers = modifiers,
			}

			ItemAnimationModifiers.AddActionBasedModifiers(item, animationObject:GetAnimation(trackName), modifierTable, function(keyName)
				return directionConfig, keyName, item.DataTable:GetPropertyChangedSignal( action:GetConfigPath({directionName, keyName}) )
			end)
		end
	end
end

function DirectionalAttacks.GetDirectionNames(item, actionName)
	local actionManager = item:GetActionManager()
	local action = actionManager:GetAction(actionName)
	
	local directionsTable = action:GetConfig("Directions")
	
	local keys = {}
	for directionName in directionsTable do
		table.insert(keys, directionName)
	end
	
	return keys
end

function DirectionalAttacks.GetDirectionNameFromAnimationPath(animationPath)
	local split = string.split(animationPath, ".")
	return split[#split]
end

function DirectionalAttacks.GetDirection(item, actionName)
	local actionManager = item:GetActionManager()
	local action = actionManager:GetAction(actionName)
	
	local directionsTable = action:GetConfig("Directions")
	
	local mouseDelta
	if IsServer then
		mouseDelta = Vector3.zero
	else
		mouseDelta = Client.GetMouseDelta()
	end
	
	local x, y = mouseDelta.X, mouseDelta.Y
	local absX, absY = math.abs(x), math.abs(y)
	
	if absX == 0 and absY == 0 then
		return next(directionsTable)
	end
	
	local angle = math.deg(math.atan2(y, x))
	
	for directionName, angleRanges in directionsTable do
		local isInRange = IsAngleInRange(angle, angleRanges[1], angleRanges[2])
		
		if isInRange then
			return directionName
		end
	end
	
	return next(directionsTable)
end

return DirectionalAttacks