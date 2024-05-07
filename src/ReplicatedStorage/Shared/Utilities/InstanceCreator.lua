local InstanceCreator = {}

function InstanceCreator.Create(className, properties, parentToWorkspace)
	parentToWorkspace = (parentToWorkspace == nil) or true
	local instance = Instance.new(className)
	
	InstanceCreator.Assign(instance, properties, parentToWorkspace)
	
	return instance
end

function InstanceCreator.Assign(instance, properties, parentToWorkspace)
	parentToWorkspace = (parentToWorkspace == nil) or true
	
	for propertyName, value in pairs(properties) do
		if propertyName == "Parent" then
			continue
		end
		
		pcall(function()
			instance[propertyName] = value
		end)
	end
	
	if properties.Parent then
		instance.Parent = properties.Parent
	elseif parentToWorkspace then
		instance.Parent = workspace
	end
end

function InstanceCreator.Clone(original, properties, parentToWorkspace)
	parentToWorkspace = (parentToWorkspace == nil) or true
	local clone = original:Clone()
	
	InstanceCreator.Assign(clone, properties, parentToWorkspace)
	
	return clone
end

return InstanceCreator
