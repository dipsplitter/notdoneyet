local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Framework = require(ReplicatedStorage.Framework)
local TableListener = Framework.GetShared("TableListener")
local TableUtilities = Framework.GetShared("TableUtilities")

local ItemAnimationModifiers = {}

function ItemAnimationModifiers.AddActionBasedModifiers(item, trackObject, trackModifierInfo, customCallback)
	local actionName = trackModifierInfo.Action
	local actionManager = item:GetActionManager()
	if not actionName or not actionManager then
		return
	end
	
	local action = actionManager:GetAction(actionName)
	local config = action.Config

	local finalModifiers = ItemAnimationModifiers.CreateTableListenerModifiers(trackModifierInfo.Modifiers, customCallback or function(key)
		return config, key, item.DataTable:GetPropertyChangedSignal( action:GetConfigPath(key) )
	end)
	
	trackObject:AddModifiers(finalModifiers)
end

function ItemAnimationModifiers.CreateTableListenerModifiers(modifierTable, tableListenerArgumentsCallback)
	local createdListeners = {}
	
	for category, modifiers in modifierTable do
		createdListeners[category] = {}

		if TableUtilities.IsDictionary(modifiers) then

			for modifierName, key in modifiers do
				createdListeners[category][modifierName] = TableListener.new(
					tableListenerArgumentsCallback(key)
				)
			end

		elseif type(modifiers) == "string" or TableUtilities.IsArray(modifiers) then

			createdListeners[category].Main = TableListener.new(tableListenerArgumentsCallback(modifiers))
		end

	end
	
	return createdListeners
end

return ItemAnimationModifiers
