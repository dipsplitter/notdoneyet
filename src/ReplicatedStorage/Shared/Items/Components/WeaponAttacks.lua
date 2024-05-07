local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local ActionArgumentFormatter = Framework.GetShared("ActionArgumentFormatter")

local function AddTimerBasedTimestamps(item, action)
	local timer = action.Timers.CooldownTimer
	local timestamps = action:GetConfig("Timestamps")
	
	if not timestamps then
		return
	end
	
	for timestampName, timestampTime in timestamps do
		if type(timestampTime) ~= "number" then
			continue
		end
		
		action:AddEvent({
			Name = `{timestampName}TimestampReached`,
			AutoFireSuccess = true,
		})
		
		timer:AddTimestamps({
			[timestampName] = timestampTime
		})
		
		item:AddConnections({
			[`{action.ActionName}{timestampName}TimestampReached`] = timer.Signals.TimestampReached:Connect(function(timestampName)
				if timestampName ~= timestampName or (Framework.IsServer and item:IsCurrentOwnerPlayer()) then
					return
				end

				item:GetActionManager():StartActionEvent({
					ActionName = action.ActionName,
					EventName = `{timestampName}TimestampReached`,
				})
			end)
		})
	end
end

local function AddAnimationEventBasedTimestamps(item, action)
	local animator = item.Animator
	local timestamps = action:GetConfig("Timestamps")
	
	if not timestamps then
		return
	end
	
	for timestampName, animationEventName in timestamps do
		if type(animationEventName) == "number" then
			continue
		end
		
		local eventName, animationName
		
		-- Only the event name
		if type(animationEventName) == "string" then
			eventName = animationEventName
		else -- Table with animation and event name
			eventName = animationEventName.Event
			animationName = animationEventName.Animation
		end

		action:AddEvent({
			Name = `{timestampName}TimestampReached`,
			AutoFireSuccess = true,
		})

		item:AddConnections({
			[`{action.ActionName}{timestampName}TimestampReached`] = animator:ConnectTo("AnimationEventReached", function(receivedEventName, receivedAnimationName)
				if Framework.IsServer and item:IsCurrentOwnerPlayer() then
					return
				end
				
				-- Is this the correct animation?
				if animationName and (receivedAnimationName ~= animationName) then
					return
				end
				
				-- Is this the correct event?
				if eventName ~= receivedEventName then
					return
				end

				item:GetActionManager():StartActionEvent({
					ActionName = action.ActionName,
					EventName = `{timestampName}TimestampReached`,
				})
			end)
		})
	end
end

local WeaponAttacks = {}

function WeaponAttacks.ReplicateAttack(item, actionName, args)
	local actionManager = item:GetActionManager()
	
	local argsTable = {
		ActionName = actionName,
		EventName = "Attack",
		Args = args,
	}
	
	if actionManager.IsNetworked then
		actionManager:StartActionEventWithReplication(argsTable)
	else
		-- We need to manually format the arguments using a copy of the network middleware... yikes
		argsTable = ActionArgumentFormatter(argsTable)
		
		actionManager:StartActionEvent(argsTable)
	end
end

function WeaponAttacks.StartAttack(item, actionName, args)
	local actionManager = item:GetActionManager()
	
	actionManager:StartActionEvent({
		ActionName = actionName,
		EventName = "Attack",
		Args = args,
	})
end

function WeaponAttacks.SetActionAsAttack(item, actionName)
	local action = item:GetActionManager():GetAction(actionName)
	
	action:AddEvent({
		Name = "Attack",
	})
	
	WeaponAttacks.AddAttackTimestampsToAction(item, action)
end

function WeaponAttacks.AddAttackTimestampsToAction(item, action)
	AddTimerBasedTimestamps(item, action)
	AddAnimationEventBasedTimestamps(item, action)
end

return WeaponAttacks
