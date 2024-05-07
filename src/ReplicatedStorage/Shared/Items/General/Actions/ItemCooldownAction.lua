local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Timer = Framework.GetShared("Timer")

local ItemCooldownAction = {}

function ItemCooldownAction.Extend(actionObj, params)
	if not actionObj:GetTimer("CooldownTimer") then

		actionObj:AddTimers({
			CooldownTimer = Timer.new({
				Duration = params.GetCooldownTime,
				IncrementMultipliers = params.CooldownMultipliers,
			}),
		})

	end
	
	local timer = actionObj:GetTimer("CooldownTimer")
	
	actionObj:AddConnections({
		CooldownFinished = timer:ConnectTo("Ended", function(completed, t)
			if not completed then
				return
			end
			
			actionObj:StartEvent("Ended")
			actionObj.CanStart = true
		end),

		StartCooldown = actionObj:ConnectTo("StartedSuccessfully", function()
			timer:Start()
			actionObj.CanStart = false
		end),
		
		OnCooldownCancel = actionObj:ConnectTo("Cancel", function()
			actionObj:Unbind()

			if timer.Active then
				timer:Reset()
			end
			actionObj.CanStart = true
		end)
	})
	
	-- This is quite annoying
	if actionObj:GetTimer("HeldTimer") then
		actionObj:AddConnections({
			StartCooldown = actionObj:ConnectTo("EndedSuccessfully", function()
				timer:Start()
				actionObj.CanStart = false
			end),
			
			CooldownFinished = timer:ConnectTo("Ended", function(completed, t)
				if not completed then
					return
				end

				actionObj.CanStart = true
			end),
		})
	end
end

return ItemCooldownAction