local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Timer = Framework.GetShared("Timer")

local RunService = game:GetService("RunService")
local IsClient = RunService:IsClient()

--[[
	An action that starts when a key is pressed and ends when it is released
]]
local ItemHoldAction = {}

function ItemHoldAction.Extend(actionObj, params)
	actionObj:AddEvent({
		Name = "Released",
	})
	
	local inputContext = actionObj:GetInputContext()
	if inputContext then
		inputContext.ValidInputStates[Enum.UserInputState.End] = {
			Event = "Released",
			AutoTrigger = true,
			Replicate = if IsClient then true else nil,
		}
	end
		
		
	if not actionObj:GetTimer("HeldTimer") then

		actionObj:AddTimers({
			HeldTimer = Timer.new({
				Duration = params.GetMaxHeldTime or -1,
				IncrementMultipliers = params.HeldMultipliers,
			}),
		})

	end

	local timer = actionObj:GetTimer("HeldTimer")

	actionObj:AddConnections({
		-- Fire released event when the timer ends
		HeldTimerFinished = timer:ConnectTo("Ended", function(completed, timeHeld)
			actionObj:StartEvent("Ended", {Completed = completed, TimeHeld = timeHeld})
		end),
		
		StopHeldTimerOnInputFinish = actionObj:ConnectTo("Released", function(args)
			timer:Reset()
		end),

		StartHeldTimer = actionObj:ConnectTo("StartedSuccessfully", function()
			timer:Start()
			actionObj.CanStart = false
		end),
	
		OnHoldCancel = actionObj:ConnectTo("Cancel", function()
			actionObj:Unbind()

			timer:SilentReset()
		end)
	})
end

return ItemHoldAction