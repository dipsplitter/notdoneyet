local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local ItemAction = Framework.GetShared("ItemAction")
local ItemCooldownAction = Framework.GetShared("ItemCooldownAction")
local ItemHoldAction = Framework.GetShared("ItemHoldAction")

local RunService = game:GetService("RunService")
local IsClient = RunService:IsClient()

local ActionTypes = {
	["Base"] = ItemCooldownAction,
	["Hold"] = ItemHoldAction,
	-- ["Charge"]
	-- ["Hold"]
	-- ["Combo"]
}

local ActivationKeybinds = {
	Primary = Enum.UserInputType.MouseButton1,
	Secondary = Enum.UserInputType.MouseButton2,
	Teritary = Enum.UserInputType.MouseButton3,
}

local function ExtendItemAction(action, data)
	local actionType = data.ActionType

	if type(actionType) == "table" then
		for i, name in ipairs(actionType) do

			if not ActionTypes[name] then
				continue
			end

			ActionTypes[name].Extend(action, data)
		end
	elseif type(actionType) == "string" then

		if not ActionTypes[actionType] then
			return
		end

		ActionTypes[actionType].Extend(action, data)
	end
end

local ActionCreator = {}

--[[
	Data should contain all constructor params for the requested action class
	
	ActionType: Specifies which action class to create; nil = Base
]]
function ActionCreator.Create(name, data)
	data.ActionType = data.ActionType or "Base"

	-- Can't forget to add the action name
	if not data.ActionName then
		data.ActionName = name
	end

	-- If we didn't specify any keybinds, try setting it to one implied from the action's name
	if not data.Keybinds and ActivationKeybinds[name] then
		data.Keybinds = name
	end

	if not data.StartManually and not data.ValidInputStates then
		-- Add default input state
		data.ValidInputStates = {
			[Enum.UserInputState.Begin] = {
				Event = "Started",
				AutoTrigger = true,
				Replicate = if IsClient then true else nil,
			}
		}
	end

	local newAction = ItemAction.new(data)
	ExtendItemAction(newAction, data)

	return newAction
end

return ActionCreator
