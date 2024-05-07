local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local Math = Framework.GetShared("Math")

local specialLerpKeys = {
	["CFrame"] = Math.LerpCFrame,	
	["Pitch"] = Math.LerpAngle,
	["Yaw"] = Math.LerpAngle,
}

return function(pastState, nextState, alpha)
	local resultingState = {}
	
	for key, value in pastState do
		local lerpToValue = nextState[key]
		
		if specialLerpKeys[key] then
			resultingState[key] = specialLerpKeys[key](value, lerpToValue, alpha)
		else
			resultingState[key] = Math.Lerp(value, lerpToValue, alpha)
		end
		
	end
	
	return resultingState
end
