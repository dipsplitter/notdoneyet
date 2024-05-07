local CollectionService = game:GetService("CollectionService")

local InstanceFilter = {}
InstanceFilter.__index = InstanceFilter
InstanceFilter.ClassName = "InstanceFilter"

--[[
	Exclude: everything listed should be ignored
	Include: everything not listed should be ignored
]]
function InstanceFilter.new(filterType)
	local self = setmetatable({
		FilterType = filterType or "Exclude",
		Instances = {},
	}, InstanceFilter)
	
	return self
end

function InstanceFilter:Add(instancesToAdd)
	if type(instancesToAdd) == "table" then -- Instance array
		
		for i, instance in pairs(instancesToAdd) do
			self.Instances[instance] = true
		end
		
	elseif type(instancesToAdd) == "string" then -- Tagged instances
		
		for i, instance in pairs(CollectionService:GetTagged(instancesToAdd)) do
			self.Instances[instance] = true
		end
		
	else
		self.Instances[instancesToAdd] = true
	end
end

function InstanceFilter:Remove(instancesToAdd)
	if type(instancesToAdd) == "string" then
		
		for instance in pairs(self.Instances) do
			if CollectionService:HasTag(instance) then
				self.Instances[instance] = nil
			end
		end
		
	else
		
		self.Instances[instancesToAdd] = nil
		
	end
end

function InstanceFilter:Contains(instance)
	if self.Instances[instance] then
		return true
	end
	
	return false
end

function InstanceFilter:ShouldIgnore(instance)
	if self:Contains(instance) and self.FilterType == "Exclude" then
		return true
	end
	
	if not self:Contains(instance) and self.FilterType == "Include" then
		return true
	end
	
	return false
end

function InstanceFilter:Clear()
	table.clear(self.Instances)
end

function InstanceFilter:Destroy()
	self.Instances = nil
end

return InstanceFilter
