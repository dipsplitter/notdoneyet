--[[
	Shared methods for base item
	
	Stupid OOP mutators, accessors, all that garbage are placed here to reduce the clutter in each script
]]

local BaseItemShared = {}

function BaseItemShared:GetValueManager()
	return self.DataTable.ValueManager
end

function BaseItemShared:GetProperty(path)
	return self.DataTable:GetProperty(path)
end

function BaseItemShared:SetProperty(path, value)
	self.DataTable:SetProperty(path, value)
end

function BaseItemShared:GetProperties()
	return self.DataTable.Data.Properties
end

function BaseItemShared:GetState(name)
	return self.DataTable:GetState(name)
end

function BaseItemShared:SetState(path, value)
	self.DataTable:SetState(path, value)
end

function BaseItemShared:GetBaseProperty(path)
	return self.DataTable:GetBaseProperty(path)
end

function BaseItemShared:GetValue(valueName, property)
	return self.DataTable:GetValue(valueName, property)
end

function BaseItemShared:SetValue(valueName, newValue, propertyName)
	self.DataTable:SetValue(valueName, newValue, propertyName)
end

function BaseItemShared:SetValues(dict)
	self.DataTable:BatchSetValues(dict)
end

function BaseItemShared:GetActionManager()
	return self.ActionManager
end

function BaseItemShared:GetAnimator()
	return self.Animator
end

function BaseItemShared:GetSounds()
	return self.Sounds
end

function BaseItemShared:GetAnimationData()
	return self.Schema.Animations
end

function BaseItemShared:GetSoundData()
	return self.Schema.Sounds
end

return function(item)
	for methodName, method in BaseItemShared do
		item[methodName] = method
	end
end
